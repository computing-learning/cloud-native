# Kubernetes NGINX Ingress Integration Lab

This lab isolates Kubernetes routing. MCP and A2A are fixed JSON HTTP mocks—there is no AI, SDK, database, or business logic.

## Problem

The frontend is public, the Hub owns internal REST endpoints, and an external API key must be usable only on MCP/A2A communication paths. If the key appears on a general `/api/*` request, ingress returns `403` before the request reaches the Hub. The Hub still validates the key value on MCP and A2A.

```text
Client → ingress-nginx → Ingress path → URL rewrite → Service → Pod → API-key validation
```

## Boundary matrix

| Public path | Backend path | Key policy | Owner |
| --- | --- | --- | --- |
| `/` | `/` | none | Frontend |
| `/api/users` | `/users` | header forbidden by this lab boundary | General REST Ingress |
| `/api/mcp` | `/mcp` | required and validated | Hub |
| `/api/mcp/tools` | `/mcp/tools` | required and validated | Hub |
| `/api/a2a` | `/` | required and validated | Hub |
| `/.well-known/agent-card.json` | unchanged | public discovery | Hub |

The internal REST endpoints are intentionally unauthenticated to keep routing observable. That is not a production security design.

## Prerequisites

- Docker
- kind
- kubectl
- curl
- `rg` (used by the test runner)
- Linux host with port 80 available

Add `127.0.0.1 gateway.local` to `/etc/hosts`, or test individual requests with `curl --resolve gateway.local:80:127.0.0.1 ...`.

## Run

```bash
chmod +x scripts/*.sh
./scripts/create-cluster.sh
./scripts/deploy.sh
./scripts/test.sh
```

Destroy the lab:

```bash
./scripts/destroy.sh
```

## Predict before testing

1. Which rule wins when `/api/mcp` also matches the general `/api` regex?
2. Why must `/api/a2a` become `/`?
3. Should the Agent Card advertise the Service DNS name or gateway URL?
4. Does ingress prove a key is valid, or only observe its header?
5. Why must the Hub validate the key?
6. What happens when two Ingress objects declare the same host and exact path?

## Inspect each layer

```bash
kubectl -n ingress-lab get ingress,service,endpoints,pod -o wide
kubectl -n ingress-lab describe ingress hub-mcp
kubectl -n ingress-lab logs deployment/hub
kubectl -n ingress-nginx logs deployment/ingress-nginx-controller
kubectl -n ingress-nginx exec deployment/ingress-nginx-controller -- nginx -T \
  | less
```

Search the generated configuration:

```bash
kubectl -n ingress-nginx exec deployment/ingress-nginx-controller -- nginx -T \
  | rg -n 'gateway.local|api/mcp|api/a2a|http_x_hub_api_key'
```

## Path types used

- `Exact`: `/api/a2a` and the Agent Card match only those complete paths.
- `Prefix`: `/` provides the frontend catch-all.
- `ImplementationSpecific`: regex rules depend on ingress-nginx behavior.

When regex locations share a host, ingress-nginx orders paths by descending length before writing NGINX locations. The MCP regex is therefore evaluated before the broader API regex. Do not create duplicate identical host/path declarations; controller behavior and admission results should not become an architecture dependency.

## Break → diagnose → fix

### Break A: remove the MCP-specific rule

Temporarily delete the `hub-mcp` Ingress document and apply the file again. Then call `/api/mcp` with a key.

Expected: the general REST rule receives the request and returns `403`. Diagnosis: the integration exception disappeared, so the request fell into the header-deny boundary. Restore the MCP document and verify `200`.

### Break B: remove the A2A rewrite

Temporarily remove `nginx.ingress.kubernetes.io/rewrite-target: /` from `hub-a2a`, apply, and retry.

Expected: Hub receives `POST /api/a2a` and returns `404`, because it implements only `POST /`. Restore the rewrite and verify `200`.

### Break C: trust ingress as authentication

Temporarily remove `Depends(require_api_key)` from the Hub's MCP route, rebuild, load, and restart the Hub. A wrong key now succeeds. Diagnosis: path authorization and credential authentication were incorrectly treated as the same responsibility. Restore backend validation.

## Important limitations

- Standard Kubernetes Ingress does not route by arbitrary HTTP headers.
- `configuration-snippet` is an ingress-nginx extension and may be disabled by cluster policy.
- This lab explicitly enables Critical-risk snippets; that is a deliberate local-only choice.
- The snippet checks header presence only. It does not authenticate the key.
- Production systems often use an API gateway, scoped credentials, or application authorization instead.
- Ingress API is frozen; Gateway API is worth evaluating for new production platforms.

## Capability matrix

| Capability | Status |
| --- | --- |
| Deployment and Service | ✅ |
| Host/path routing | ✅ |
| Exact, Prefix, ImplementationSpecific | ✅ |
| URL rewrite | ✅ |
| Multiple Ingress objects on one host | ✅ |
| Header boundary | ✅ lab-only |
| Backend key validation | ✅ mock |
| Real MCP/A2A protocol | ❌ |
| Internal API authentication | ❌ |
| Production key scopes | ❌ |

## Complete when

You can explain which rule matched, what path the Pod received, whether a rejected request reached the Pod, why `401` belongs to backend authentication while this lab's `403` belongs to the ingress boundary, and why production should use stronger scoped authorization.

## Backlog

- TLS and DNS
- NetworkPolicy
- JWT or API gateway scopes
- Secret management
- Rate limiting and observability
- Gateway API comparison
