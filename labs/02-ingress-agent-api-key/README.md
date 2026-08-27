# Lab 01 — API Key on Exact Agent Endpoints

## Goal

Prove one narrow concept: MCP and A2A endpoints under `/api` require an API key, while the existing frontend and broad REST API routing remain unchanged.

This lab does not attempt to classify callers as internal or external. Protecting frontend/internal APIs belongs to VPN, private networking, SSO, mTLS, IP policy, or another lab.

## Questions before running

1. Can two Ingress resources share one hostname?
2. Which rule handles `/api/mcp`: `Exact /api/mcp` or `Prefix /api`?
3. Does `auth-url` on `gateway-agent` affect `gateway-internal`?
4. What happens when the key is missing or invalid?
5. Does `/api/mcp/tools` match the exact MCP rule?

## Architecture

```text
gateway.local
  |
  +-- gateway-agent
  |     +-- Exact /api/mcp -----------------+
  |     +-- Exact /api/a2a                  +--> api-key-auth --> Hub
  |     +-- Exact /api/a2a/agent-card.json -+
  |
  +-- gateway-internal
        +-- Prefix /api ------------------------> Hub
        +-- Prefix / --------------------------> Frontend
```

There is no URL rewrite.

## Expected behavior

| Path | Key | Expected |
|---|---|---:|
| `/api/mcp` | valid | 200 |
| `/api/a2a` | valid | 200 |
| `/api/a2a/agent-card.json` | valid | 200 |
| exact agent endpoint | missing/invalid | 401 |
| `/api/status` | none | 200 |
| `/` | none | 200 |
| `/api/mcp/tools` | none | 404 from Hub mock |

Demo key:

```text
lab-agent-key
```

The key is intentionally visible for learning. Never commit a real production key.

## Run

```bash
make cluster
make ingress
make deploy
make verify
```

## Predict

Before each scenario write:

```text
Matched Ingress:
Matched path:
Auth check executed:
Expected upstream:
Expected status:
```

## Observe

```bash
kubectl get ingress -n cloud-native-lab
kubectl describe ingress gateway-agent -n cloud-native-lab
kubectl logs -n cloud-native-lab deployment/api-key-auth --tail 100
kubectl logs -n cloud-native-lab deployment/hub --tail 100
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail 100
```

## Break intentionally

Remove the `auth-url` annotation from `gateway-agent`, apply the manifest, then run:

```bash
make verify
```

The missing-key tests will change from `401` to `200`. This is an authentication-boundary failure. Restore the annotation and verify again.

## Architecture takeaway

Ingress annotations apply to an Ingress resource and its generated locations. A specific `Exact` route can require authentication without changing the broad frontend/API routes on another Ingress.

Limitation: `/` and broad `/api/*` remain reachable. This lab protects only the three declared agent endpoints.

## Cleanup

```bash
make destroy
```
