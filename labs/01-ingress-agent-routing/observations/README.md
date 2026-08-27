# Lab 01 — Observations

## Environment

```text
Date:
Operating system:
Docker version:
kind version:
kubectl version:
Kubernetes context:
ingress-nginx version:
Source IP observed by ingress-nginx:
```

## Scenario 01 — Exact MCP exception

Prediction:

Actual:

Difference:

Why?

## Scenario 02 — Exact A2A exceptions

Prediction:

Actual:

Difference:

Why?

## Scenario 03 — Internal API denied

Prediction:

Actual:

Difference:

Why?

## Scenario 04 — Frontend denied

Prediction:

Actual:

Difference:

Why?

## Scenario 05 — Exact path does not expose children

Prediction:

Actual:

Difference:

Why?

## Failure observed

What failed?

Which process or network boundary failed?

## Fix

What changed?

Why is Ingress the correct layer for this fix?

## Architecture takeaways

1.
2.
3.

## Review schedule

| Day | Keywords | Notes |
|---:|---|---|
| 1 | Ingress, host, path | |
| 3 | Exact, Prefix, rule priority | |
| 5 | allowlist, denylist, source IP | |
| 7 | proxy boundary, duplicate rule | |

## Capability matrix

| Capability | Status |
|---|---:|
| Same hostname | ✅ |
| Frontend routing | ✅ |
| Internal REST routing | ✅ |
| MCP mock contract | ✅ |
| A2A mock contract | ✅ |
| Exact external exceptions | ✅ |
| External-IP denial for internal surface | ✅ |
| Authentication | ❌ |
| Trusted production proxy configuration | ❌ |
| TLS | ❌ |
| Monitoring | ❌ |

## Backlog

- Replace denylist with an internal CIDR allowlist.
- Verify client IP through a real load balancer or reverse proxy.
- Add API-key or token authentication.
- Add TLS.
- Add rate limiting and audit logging.

