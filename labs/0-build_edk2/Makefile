PWD := $(shell pwd)

.PHONY: default build-dev-container

default:
	@echo "Hello?"

build-dev-container:
	@podman build --squash-all -t edk2-build .

run-container:
	@podman run -it --rm -v "$(PWD)":/work --name my-edk2-build edk2-build
