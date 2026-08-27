# Request Flow

## Agent request

```text
POST /api/mcp + X-API-Key
  -> Exact gateway-agent rule
  -> api-key-auth /authorize
  -> 200 when key is valid
  -> Hub /api/mcp
```

Missing or invalid key causes the auth subrequest to return `401`; the request does not reach Hub.

## Broad REST request

```text
GET /api/status without key
  -> Prefix /api on gateway-internal
  -> Hub /api/status
```

## Frontend request

```text
GET / without key
  -> Prefix / on gateway-internal
  -> Frontend
```

The API-key policy is intentionally scoped only to the exact agent routes.
