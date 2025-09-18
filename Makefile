SHELL := /usr/bin/env bash
.PHONY: dist
dist:
	bash tools/mkdist.sh
