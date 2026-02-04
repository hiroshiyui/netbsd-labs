PWD := $(shell pwd)

.PHONY: default run-container clean-dryrun clean

default:
	@echo "** NetBSD Labs **"
	@echo ""
	@echo "  - run-container: run development container"
	@echo "  - clean-dryrun: list files to be cleaned from Git repository"
	@echo "  - clean: clean files from Git repository and rootfs in container"

run-container:
	podman run -it --rm -v "$(PWD)/usr":/work --name my-netbsd-labs netbsd-labs

clean-dryrun:
	git clean -ndfx -e usr/src -e usr/CVS -e usr/rootfs_qemu

clean:
	git clean -dfx -e usr/src -e usr/CVS -e usr/rootfs_qemu; \
	podman run -it --rm -v "$(PWD)/usr":/work netbsd-labs rm -rf rootfs_qemu
