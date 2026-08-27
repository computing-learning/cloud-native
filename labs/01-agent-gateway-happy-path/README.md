# Lab 01 — Agent Gateway Happy Path

```http
POST /agent/a2a
Host: gateway.local
Content-Type: application/json
X-Agent-Api-Key: lab-agent-key
```

The endpoint receives a mock message and returns a deterministic result.

---

## Internal Contract

The Hub exposes:

```http
POST /mcp
GET  /a2a/.well-known/agent.json
POST /a2a
GET  /healthz
```

Expected public-to-internal mapping:

| Public path                         | Internal Hub path             |
| ----------------------------------- | ----------------------------- |
| `/agent/mcp`                        | `/mcp`                        |
| `/agent/a2a/.well-known/agent.json` | `/a2a/.well-known/agent.json` |
| `/agent/a2a`                        | `/a2a`                        |

`/healthz` is used by Kubernetes probes and is not part of the external integration contract.

---

## Happy Scenarios

### Scenario 01 — MCP Initialize

```text
POST /agent/mcp
method: initialize
```

Expected:

* HTTP `200`
* Valid JSON-RPC response
* Mock server information
* Request ID available for tracing

### Scenario 02 — MCP List Tools

```text
POST /agent/mcp
method: tools/list
```

Expected:

* HTTP `200`
* Valid JSON-RPC response
* At least one deterministic mock tool

### Scenario 03 — MCP Call Tool

```text
POST /agent/mcp
method: tools/call
```

Expected:

* HTTP `200`
* Mock tool receives the expected arguments
* Deterministic tool result

### Scenario 04 — A2A Discovery

```http
GET /agent/a2a/.well-known/agent.json
```

Expected:

* HTTP `200`
* Valid mock Agent Card
* Public A2A URL
* No internal Kubernetes address

### Scenario 05 — A2A Message

```http
POST /agent/a2a
```

Expected:

* HTTP `200`
* Message reaches the A2A handler
* Deterministic mock result

---

## Evidence Contract

Hub responses and logs must provide enough information to identify:

```json
{
  "service": "hub",
  "protocol": "mcp",
  "method": "tools/list",
  "received_path": "/mcp",
  "request_id": "..."
}
```

A scenario is not successful based only on HTTP `200`.

Evidence must also prove:

* The intended protocol handler received the request.
* The public path mapped to the intended internal path.
* The request can be correlated through `request_id`.
* No internal infrastructure address leaked into the public contract.

---

## Capability Matrix

| Capability                      | Status |
| ------------------------------- | ------ |
| Hub health endpoint             | ❌      |
| MCP initialize                  | ❌      |
| MCP tool discovery              | ❌      |
| MCP tool invocation             | ❌      |
| A2A Agent Card                  | ❌      |
| A2A message execution           | ❌      |
| Container image                 | ❌      |
| Kubernetes Deployment           | ❌      |
| Kubernetes Service routing      | ❌      |
| Ingress external routing        | ❌      |
| Public-to-internal path mapping | ❌      |
| Request ID correlation          | ❌      |

---

## Non-goals

This phase does not implement:

* Frontend
* Internal REST API exposure
* Database
* LLM
* Real AI agent
* Production authentication or authorization
* IP allowlist
* Rate limiting
* TLS
* Routing-conflict tests
* Monitoring
* Production secrets

---

## Backlog

After the happy integration flow works:

* Missing or invalid API key
* IP allowlist
* Real source IP behind proxy or NAT
* Exact, Prefix, and regex path behavior
* Duplicate Ingress rules
* Timeout and retry
* Rate limiting
* TLS
* Metrics and tracing
* Production Secret management

---

## Build Order

```text
01. Lab contract and structure
02. Minimal Hub health endpoint
03. MCP initialize
04. MCP tools/list
05. MCP tools/call
06. A2A Agent Card
07. A2A message
08. Local happy-path scenarios
09. Container image
10. Kubernetes Deployment and Service
11. NGINX Ingress
12. External verification
13. Observations and architecture takeaways
```

Each step is reviewed and run manually before moving to the next step.

---

## Complete Condition

The lab is complete when the learner can explain:

* Which public MCP and A2A contracts are exposed.
* Which internal paths receive the requests.
* Which process and network boundaries are crossed.
* Why external clients do not need Kubernetes implementation details.
* What evidence proves the correct handler processed each request.
* Which production capabilities remain in the backlog.
