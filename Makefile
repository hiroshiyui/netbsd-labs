.PHONY: default cleanbuild

default:
	@echo "NetBSD Labs"

cleanbuild:
	rm -rf ./usr/obj/* ./usr/tools/* ./usr/tmp/*
