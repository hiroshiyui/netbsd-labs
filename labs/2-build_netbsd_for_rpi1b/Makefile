PWD := $(shell pwd)

ifndef LABSROOT
$(error LABSROOT is not set. Please run 'source ./envsetup.sh' at project root directory.)
endif

.PHONY: default build-dev-container run-container

default:
	@echo "** Build NetBSD for Raspberri Pi 1B **"
	@echo ""
	@echo "  - build-dev-container: build development container"
	@echo "  - run-container: run development container"

build-dev-container:
	podman build --squash-all -t netbsd-labs $(LABSROOT)

run-container:
	podman run -it --rm -v "$(LABSROOT)/usr":/work -v "$(LABSROOT)/labs/playground":/playground --name my-netbsd-labs netbsd-labs
