# Lab observations

For every scenario, write the prediction before running the test.

| Scenario | Prediction | Actual | Boundary responsible | Why? |
| --- | --- | --- | --- | --- |
| Frontend | | | Ingress path | |
| Internal API | | | Rewrite | |
| MCP valid key | | | Backend auth | |
| MCP wrong key | | | Backend auth | |
| Agent Card | | | Exact path | |
| A2A JSON-RPC | | | Rewrite + backend auth | |
| Key on internal API | | | Ingress header boundary | |
| Internal API without key | | | General API rule | |
| Unknown MCP path | | | Backend route | |

## Failure observed

- What failed?
- Which boundary failed?
- Did the request reach the Pod?

## Fix

- What changed?
- Why is that the correct layer?

## Architecture takeaways

1. Kubernetes Ingress routes by host and path, not by arbitrary headers.
2. ingress-nginx snippets can inspect a header but are controller-specific.
3. Header presence at the edge is not authentication; the Hub validates the key.
4. Public paths may differ from backend paths, so rewrite ownership must be explicit.
