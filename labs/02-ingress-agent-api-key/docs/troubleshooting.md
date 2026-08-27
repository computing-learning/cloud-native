# Troubleshooting

## Agent endpoint returns 503

Check the auth service:

```bash
kubectl get pods,service,endpoints -n cloud-native-lab
kubectl logs -n cloud-native-lab deployment/api-key-auth --tail 100
```

## Valid key still returns 401

Confirm the demo Secret and request header:

```bash
kubectl get secret agent-api-key -n cloud-native-lab
curl -i --resolve gateway.local:80:127.0.0.1 \
  -H 'X-API-Key: lab-agent-key' \
  http://gateway.local/api/a2a/agent-card.json
```

## Missing key returns 200

Confirm `gateway-agent` still contains the `auth-url` annotation and look for duplicate Ingress rules:

```bash
kubectl describe ingress gateway-agent -n cloud-native-lab
kubectl get ingress -A
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- nginx -T
```

## `/api/status` returns 401 unexpectedly

The auth annotation was probably added to `gateway-internal`. It belongs only on `gateway-agent` in this lab.
