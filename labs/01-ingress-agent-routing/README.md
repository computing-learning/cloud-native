# Lab 01 — Same-host Agent API Isolation

## Goal

Prove that one hostname can expose only selected agent APIs to an external source IP while denying that same IP access to the frontend and internal REST APIs.

This lab isolates Kubernetes Ingress routing and source-IP policy. It contains no database, LLM, business logic, production secret, or complete MCP/A2A implementation.

## Problem questions

Before running the lab, predict:

1. If `/api` is denied, can a more specific `Exact` path such as `/api/mcp` still be allowed?
2. Does an Ingress annotation apply to one path or the whole Ingress resource?
3. Which rule wins for `/api/mcp`: `Prefix /api` or `Exact /api/mcp`?
4. What response should `/api/mcp/tools` receive?
5. Which IP does ingress-nginx evaluate: the workstation IP, Docker bridge IP, or a forwarded IP?

## Architecture

```text
Current workstation
source IP seen by ingress-nginx: 172.20.0.1
        |
        v
gateway.local:80
        |
        v
ingress-nginx
        |
        +-- /api/mcp                     Exact + allow source IP --> Hub
        +-- /api/a2a                     Exact + allow source IP --> Hub
        +-- /api/a2a/agent-card.json     Exact + allow source IP --> Hub
        +-- /api/*                       Prefix + deny source IP  --> 403
        +-- /*                            Prefix + deny source IP  --> 403
```

There is no path rewrite. The public path received by Ingress is the same path received by the Hub.

## Expected policy

| Source | Path | Expected |
|---|---|---:|
| `172.20.0.1` | `/api/mcp` | 200 |
| `172.20.0.1` | `/api/a2a` | 200 |
| `172.20.0.1` | `/api/a2a/agent-card.json` | 200 |
| `172.20.0.1` | `/api/status` | 403 |
| `172.20.0.1` | `/` | 403 |
| `172.20.0.1` | `/api/mcp/tools` | 403 |

## Prerequisites

```bash
docker --version
kind version
kubectl version --client
curl --version
```

## Build and run

```bash
make cluster
make ingress
make deploy
make verify
```

Or run each script directly:

```bash
./scripts/create-cluster.sh
./scripts/install-ingress.sh
./scripts/deploy.sh
./external-agent/test-integration.sh
```

## Observe

```bash
kubectl config current-context
kubectl get all -n cloud-native-lab
kubectl get ingress -n cloud-native-lab
kubectl describe ingress -n cloud-native-lab
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail 50
kubectl logs -n cloud-native-lab deployment/hub --tail 50
```

The ingress access log must show the source address used by the policy. If it is not `172.20.0.1`, update all allowlist and denylist annotations in `k8s/ingress.yaml`.

## Break intentionally

Remove the three `Exact` paths from `gateway-agent`, apply the manifest, and predict the result:

```text
POST /api/mcp -> matches Prefix /api -> denied -> 403
```

Restore the paths, apply again, then run `make verify`.

## Diagnose

```bash
kubectl apply --dry-run=server -f k8s/ingress.yaml
kubectl get ingress -A
kubectl describe ingress -n cloud-native-lab
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- nginx -T
curl -i --resolve gateway.local:80:127.0.0.1 http://gateway.local/api/status
```

If a denied endpoint returns 200, look for another Ingress defining the same host and path. For ingress-nginx, overlapping rules from multiple resources are merged into one NGINX server.

## Cleanup

```bash
make destroy
```

This deletes only the kind cluster named `agent-routing-lab`.

## Architecture takeaway

Path selection and access control are separate responsibilities. A broad internal `Prefix` rule can deny an external source, while more specific `Exact` rules explicitly expose a small integration surface to that source.

For production, prefer an internal allowlist for frontend/API rather than only denying one partner IP. Also verify real client-IP preservation through every load balancer and trusted proxy.

