# Request Flow

## Allowed MCP request

```text
curl on workstation
  -> host TCP port 80
  -> kind control-plane port mapping
  -> ingress-nginx process
  -> host gateway.local
  -> Exact path /api/mcp
  -> source IP allowed by gateway-agent
  -> hub Service port 80
  -> Hub Pod port 8000
  -> POST /api/mcp
```

Boundaries crossed:

1. Workstation process to Docker network.
2. Docker port mapping to the kind node.
3. Ingress controller to Kubernetes Service.
4. Service routing to a selected Hub Pod.
5. HTTP server process inside the Hub container.

## Denied internal request

```text
curl on workstation
  -> ingress-nginx
  -> Prefix path /api
  -> source IP matches denylist
  -> HTTP 403
```

The denied request does not reach the Hub Service or Pod.

## Rule priority

`/api/mcp` matches both `Exact /api/mcp` and `Prefix /api`. The Exact rule is more specific and selects the agent Ingress location. `/api/mcp/tools` does not match the Exact rule, so it falls back to the denied `/api` Prefix.

