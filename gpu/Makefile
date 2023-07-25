# ---------------------
all: enable label patch mps test

enable:
	@echo "Enabling host-access and gpu..."
	@microk8s enable host-access && \
	microk8s enable gpu \
		--set driver.enabled=true \
		--set migManager.enabled=false \
		--set mig.strategy=mixed \
		--set toolkit.enabled=true \
		;

clean:
	@echo "Disabling gpu..."
	@microk8s disable gpu
	@if helm list -q | grep gpu-operator > /dev/null; then \
		helm delete gpu-operator; \
	fi
	@if helm list -q | grep nebuly > /dev/null; then \
		helm delete nebuly; \
	fi
	@if helm list -q | grep gpu-operator > /dev/null; then \
		helm delete gpu-operator; \
	fi
	@if kubectl get --no-headers namespace | grep gpu-operator-resources > /dev/null; then \
		kubectl delete namespace gpu-operator-resources; \
	fi
	@for label in $$(kubectl get node $$(hostname) -o json | grep -o '"nvidia.com/[^"]*"' | sed 's/"//g'); do\
		kubectl label node $$(hostname) $$label-; \
	done

patch:
	@timeout 120s sh -c 'while ! kubectl wait pods -n gpu-operator-resources -lapp=nvidia-operator-validator --for=condition=Ready=true >/dev/null 2>&1; do sleep 2; done' && \
	kubectl patch daemonset nvidia-device-plugin-daemonset --patch-file patch.yaml

mps:
	@helm upgrade -i nebuly oci://ghcr.io/nebuly-ai/helm-charts/nvidia-device-plugin \
	--version=0.13.0 \
	-f mps.yaml \
	--namespace gpu-operator-resources \
	--set-file config.map.config=mps-config.yaml \
	--wait

label:
	@kubectl label nodes $$(hostname) nos.nebuly.com/gpu-partitioning=mps --overwrite

validate:
	@kubectl logs -n gpu-operator-resources -lapp=nvidia-operator-validator -c nvidia-operator-validator

test: add.test
	@kubectl wait --for=condition=Ready=true -f test.yaml && \
	kubectl logs cuda-vector-add -n gpu-operator-resources -f && \
	make rm.test

add.%:
	@kubectl apply -f $*.yaml -n gpu-operator-resources

rm.%:
	kubectl delete -f $*.yaml -n gpu-operator-resources --wait


# Declare the phony targets
.PHONY: enable mps validate test label add.% rm.%
