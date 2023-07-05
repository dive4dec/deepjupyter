SHELL:= /bin/bash
activate_conda = source /opt/conda/bin/activate && conda activate jlite
# registry for docker images
# registry=localhost:32000
registry=chungc/
# version for tagging image for deployment
version=latest

jupyterhub_chart_version = 3.0.0-beta.1
namespace := jhub
release := default
registry := localhost:32000/
project := $(release)-$(namespace)
python_version := 3.10
base := minimal-notebook-nv

nv:
	docker build \
		-t "nv" -f "nv/Dockerfile" .

docker-stacks-foundation-nv: nv
	docker build \
		--build-arg ROOT_CONTAINER="nv" \
		--build-arg PYTHON_VERSION="$(python_version)" \
		-t "docker-stacks-foundation-nv" docker-stacks/docker-stacks-foundation

base-notebook-nv: docker-stacks-foundation-nv
	docker build \
		--build-arg BASE_CONTAINER="docker-stacks-foundation-nv" \
		-t "base-notebook-nv" docker-stacks/base-notebook

minimal-notebook-nv: base-notebook-nv
	docker build \
		--build-arg BASE_CONTAINER="base-notebook-nv" \
		-t "minimal-notebook-nv" docker-stacks/minimal-notebook

scipy-notebook-nv: minimal-notebook-nv
	docker build \
		--build-arg BASE_CONTAINER="minimal-notebook-nv" \
		-t "scipy-notebook-nv" docker-stacks/scipy-notebook

deephub:
	cd hub && \
	docker build --pull \
		-t "deephub" -f Dockerfile .


namespace:
	@if ! kubectl get namespace $(namespace) >/dev/null 2>&1; then \
        echo "Creating namespace $(namespace)"; \
        kubectl create namespace $(namespace); \
    else \
        echo "Namespace $(namespace) already exists"; \
    fi

repo:
	helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/ --force-update
	helm repo update

upgrade: namespace
	@echo "Upgrading chart in the Kubernetes cluster..."
	microk8s helm upgrade -i -n $(namespace) $(release) jupyterhub/jupyterhub \
	  --version=$(jupyterhub_chart_version) -f values.yaml --wait
	helm list -n $(namespace) && kubectl get all -n $(namespace)

test.upgrade:
	microk8s helm upgrade -i -n $(namespace) $(release) jupyterhub/jupyterhub \
	  --version=$(jupyterhub_chart_version) --version=2.0.0 -f values.yaml --wait --dry-run --debug


delete:
	@echo "Deleting chart from the Kubernetes cluster..."
	microk8s helm delete -n $(namespace) $(release) --wait

push: push.deepnb push.deepnbg push.deephub

push.%: %
	docker tag "$*" "${registry}$*:${version}"
	docker push "${registry}$*:${version}"

# Support different interfaces such as
# VSCode, remote desktop, retrolab, ...
jupyter-interface:
	docker build --pull \
		-t "jupyter-interface" -f jupyter-interface/Dockerfile .
	docker run --rm -it  -p 8888:8888/tcp -v "$$(pwd)/jupyter-interface/examples":/home/jovyan/work jupyter-interface

#  deeplearning dev; 
deepnb: $(base)
	base=$(base); i=0; \
	for module in deep jupyter-interface dev; \
	do \
	stage="deepnb$$((++i))_$$module"; \
	docker build --build-arg BASE_CONTAINER="$$base" \
		-t "$$stage" -f "$$module/Dockerfile" .; \
	base="$$stage"; \
	done; \
	docker tag "$$stage" deepnb

deepnbg: deepnb
	cd gpu && \
	docker build --build-arg BASE_CONTAINER="deepnb" \
		-t deepnbg -f "Dockerfile" .
	# docker run --rm -it  -p 8888:8888/tcp deepnbg

jl-source: jl-clean-source jl-build-source

jl-release: jl-clean-release jl-build-release jl-page

jl-clean-release:
	rm -rf _release .jupyterlite.doit.db
    
jl-clean-source:
	rm -rf _source .jupyterlite.doit.db

jl-build-release:
	# run jlite twice to get wtc setup
	cd jupyterlite && \
	$(activate_conda) && \
	jupyter lite build --contents=../release && \
	jupyter lite build --contents=../release && \
	python kernel2xeus_python.py && \
	python kernel2pyodide.py && \
	cp -rf _output ../_release

jl-build-source:
	cd jupyterlite && \
	$(activate_conda) && \
	jupyter lite build --contents=../source && \
	python kernel2xeus_python.py && \
	python kernel2pyodide.py && \
	cp -rf _output ../_source
    
jl-page:
	cd release && \
	$(activate_conda) && \
	ghp-import -np ../_release

modules := push deepnb deepnbg deephub main scipy-nv nv programming jupyter-interface jl jl-clean jl-build jl-page release push.%

.PHONY: $(modules)