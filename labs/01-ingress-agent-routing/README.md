# Lab 01 — Kubernetes Ingress Agent Routing

## Problem

Một hệ thống chạy trong Kubernetes gồm:

* Frontend phục vụ web application
* Hub cung cấp web APIs
* Hub cung cấp một MCP endpoint
* Hub cung cấp A2A Agent Card và A2A endpoint

Một external agent cần truy cập MCP và A2A thông qua một public hostname.

External agent không nên biết:

* Pod IP
* Kubernetes Service name
* ClusterIP
* Hub internal paths
* Hub implementation
* Business logic
* AI implementation

Lab cần chứng minh NGINX Ingress có thể expose public paths khác với internal Hub paths.

---

## Goal

Kiểm chứng happy-path routing:

```text
Public request
→ NGINX Ingress Controller
→ Kubernetes Service
→ Pod
→ Internal application path
```

Lab chỉ kiểm tra:

* Hostname routing
* Path routing
* Path rewrite
* Service-to-Pod routing
* Public MCP endpoint
* Public A2A endpoint
* Frontend routing
* Hub web API routing

MCP và A2A chỉ là HTTP mock contracts.

---

## Components

### Frontend

Static HTML application.

Internal endpoint:

```http
GET /
```

### Hub

Minimal HTTP server.

Internal endpoints:

```http
GET  /healthz
GET  /api/status
POST /mcp
GET  /agent-card.json
POST /a2a
```

### External Agent

Shell script sử dụng `curl` để mô phỏng external integration client.

External Agent không gọi trực tiếp Hub Service hoặc Pod. Nó chỉ gọi:

```text
http://gateway.local
```

### Kubernetes

Kubernetes cung cấp:

* Hub Deployment
* Hub Service
* Frontend Deployment
* Frontend Service
* Ingress rules

### NGINX Ingress Controller

Ingress Controller nhận external HTTP request, chọn rule và forward request đến Kubernetes Service tương ứng.

---

## Architecture

```text
Browser
  │ GET /
  ▼
NGINX Ingress Controller
  ▼
Frontend Service
  ▼
Frontend Pod
```

```text
Web Client
  │ GET /api/status
  ▼
NGINX Ingress Controller
  ▼
Hub Service
  ▼
Hub Pod
  ▼
GET /api/status
```

```text
External Agent
  │ POST /agent/mcp
  ▼
NGINX Ingress Controller
  │ rewrite
  ▼
Hub Service
  ▼
Hub Pod
  ▼
POST /mcp
```

```text
External Agent
  │ GET /agent/a2a/agent-card.json
  ▼
NGINX Ingress Controller
  │ rewrite
  ▼
Hub Service
  ▼
Hub Pod
  ▼
GET /agent-card.json
```

```text
External Agent
  │ POST /agent/a2a
  ▼
NGINX Ingress Controller
  │ rewrite
  ▼
Hub Service
  ▼
Hub Pod
  ▼
POST /a2a
```

---

## Routing Contract

| Public request                   | Target Service | Internal path      |
| -------------------------------- | -------------- | ------------------ |
| `GET /`                          | frontend       | `/`                |
| `GET /api/status`                | hub            | `/api/status`      |
| `POST /agent/mcp`                | hub            | `/mcp`             |
| `GET /agent/a2a/agent-card.json` | hub            | `/agent-card.json` |
| `POST /agent/a2a`                | hub            | `/a2a`             |

---

## Boundary Map

| From                | To                 | Boundary             | Responsibility                     |
| ------------------- | ------------------ | -------------------- | ---------------------------------- |
| Client              | Ingress Controller | External network     | Receive public HTTP request        |
| Ingress Controller  | Service            | Kubernetes network   | Select backend using host and path |
| Service             | Pod                | Kubernetes endpoint  | Select matching Pod                |
| Ingress public path | Hub internal path  | Routing contract     | Rewrite public path                |
| Hub router          | Handler            | Application boundary | Return deterministic mock response |

Kubernetes Service does not understand HTTP paths.

HTTP host matching, path matching, and rewrite are responsibilities of the Ingress Controller.

---

## Happy Scenarios

### Scenario 01 — Frontend

Request:

```http
GET http://gateway.local/
```

Expected:

```text
Ingress
→ Frontend Service
→ Frontend Pod
→ Static HTML
```

### Scenario 02 — Hub Web API

Request:

```http
GET http://gateway.local/api/status
```

Expected:

```text
Ingress
→ Hub Service
→ Hub Pod
→ /api/status
```

### Scenario 03 — MCP

Request:

```http
POST http://gateway.local/agent/mcp
Content-Type: application/json
```

Expected internal request:

```http
POST /mcp
```

Expected response evidence:

```json
{
  "service": "hub",
  "protocol": "mcp-mock",
  "method": "POST",
  "received_path": "/mcp"
}
```

### Scenario 04 — A2A Agent Card

Request:

```http
GET http://gateway.local/agent/a2a/agent-card.json
```

Expected internal request:

```http
GET /agent-card.json
```

Agent Card must advertise the public A2A URL:

```text
http://gateway.local/agent/a2a
```

### Scenario 05 — A2A Request

Request:

```http
POST http://gateway.local/agent/a2a
Content-Type: application/json
```

Expected internal request:

```http
POST /a2a
```

---

## Evidence Contract

Each Hub response must expose:

```json
{
  "service": "hub",
  "protocol": "mcp-mock",
  "method": "POST",
  "received_path": "/mcp",
  "request_id": "..."
}
```

This lets the learner compare:

```text
Public request path
versus
Internal received path
```

HTTP `200` alone is not sufficient evidence.

---

## Scope

Included:

* Hub mock
* Frontend static page
* External agent mock
* Container images
* kind cluster
* Kubernetes Deployment
* Kubernetes Service
* ingress-nginx
* Ingress path routing
* Path rewrite
* `curl` verification

Not included:

* Real MCP implementation
* Real A2A implementation
* LLM
* Database
* Business logic
* Production authentication
* IP allowlist
* TLS
* Rate limiting
* Monitoring
* Routing conflicts

---

## Build Order

```text
01. Problem and architecture
02. Minimal Hub
03. Static frontend
04. Local HTTP verification
05. Container images
06. kind cluster
07. Kubernetes Deployments
08. Kubernetes Services
09. Basic Ingress routing
10. Path rewrite
11. External Agent verification
12. Observations and architecture takeaways
```

Each step must be reviewed and run manually before continuing.

---

## Complete Condition

The lab is complete when the learner can explain:

1. Which process accepts the external connection.
2. Which component matches the HTTP path.
3. Which component selects the destination Pod.
4. Where public paths are rewritten.
5. Why Kubernetes Service does not perform path routing.
6. Why external clients do not need internal Kubernetes addresses.
7. Which evidence proves the intended internal handler received the request.
