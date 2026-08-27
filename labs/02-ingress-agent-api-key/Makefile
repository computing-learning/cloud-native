.PHONY: cluster ingress deploy verify status destroy

cluster:
	./scripts/create-cluster.sh

ingress:
	./scripts/install-ingress.sh

deploy:
	./scripts/deploy.sh

verify:
	./scripts/verify.sh

status:
	kubectl get pods,services,ingress -n cloud-native-lab

destroy:
	./scripts/destroy.sh
