# Troubleshooting

## Confirm context

```bash
kubectl config current-context
kubectl config get-contexts
```

Expected context: `kind-agent-routing-lab`.

## Pod stuck in ImagePullBackOff

The image exists on the Docker host but not inside the kind node:

```bash
docker image inspect ingress-routing-hub:1.0.0
kind load docker-image ingress-routing-hub:1.0.0 --name agent-routing-lab
kubectl rollout restart deployment/hub -n cloud-native-lab
```

## Ingress controller cannot pull its image

```bash
kubectl describe pod -n ingress-nginx -l app.kubernetes.io/component=controller
kubectl get deployment ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Pull the exact image with Docker, load it into kind, then restart the controller.

## Expected 403 returns 200

Check the real source address:

```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail 30
```

Update `172.20.0.1/32` in `k8s/ingress.yaml` if the first field is different. Then check for duplicate rules:

```bash
kubectl get ingress -A
kubectl describe ingress -n cloud-native-lab
```

## Expected 200 returns 403

The observed source IP probably does not match the agent allowlist. Inspect the controller log and annotations:

```bash
kubectl get ingress gateway-agent -n cloud-native-lab -o yaml
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail 30
```

## Expected 200 returns 404

Check that the Hub directly implements the public path; this lab performs no rewrite:

```bash
kubectl exec -n cloud-native-lab deployment/hub -- \
  python -c 'import urllib.request; print(urllib.request.urlopen("http://127.0.0.1:8000/api/status").read().decode())'
```

Inspect Hub logs:

```bash
kubectl logs -n cloud-native-lab deployment/hub --tail 100
```

## Inspect generated NGINX configuration

```bash
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- nginx -T
```

Search for `server_name gateway.local` and compare the generated locations.

## Authorization checks

```bash
kubectl auth can-i get pods -n cloud-native-lab
kubectl auth can-i create ingress -n cloud-native-lab
```

