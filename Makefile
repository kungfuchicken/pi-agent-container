SHELL := /bin/bash

# Default workspace mounted into /workspace in container.
WORKSPACE_DIR ?= $(abspath ../..)
PI_ARGS ?=

# HOST_HOME passes the macOS $HOME into compose; $HOME inside Lima resolves
# to the Linux home, breaking host bind mounts like auth.json.
HOST_HOME ?= $(HOME)

# WORKING_DIR: host path to ~working/ (plans and reports).
# Default assumes this repo lives at ~working/apps/pi-agent-container/.
WORKING_DIR ?= $(abspath ../..)

export WORKSPACE_DIR
export PI_ARGS
export HOST_HOME
export WORKING_DIR

PLIST_TEMPLATE := com.pi-build.plist.template
PLIST_GENERATED := com.pi-build.plist
PLIST_INSTALL_DIR := $(HOME)/Library/LaunchAgents

.PHONY: help safe dev config bump rollback list status prune install-schedule uninstall-schedule

help:
	@echo "pi-agent container helper"
	@echo ""
	@echo "Run:"
	@echo "  make dev            Run full-dev profile (read/write/edit/bash/etc.)"
	@echo "  make safe           Run read-only profile (read/grep/find/ls only)"
	@echo ""
	@echo "Build:"
	@echo "  make bump           Build latest pi-coding-agent version"
	@echo "  make rollback       Roll back to previous build"
	@echo "  make list           Show available builds"
	@echo "  make status         Compare active vs latest npm version"
	@echo "  make prune          Remove old builds beyond retention"
	@echo ""
	@echo "Schedule:"
	@echo "  make install-schedule    Generate plist and load weekly Friday build"
	@echo "  make uninstall-schedule  Unload and remove the scheduled build"
	@echo ""
	@echo "Config:"
	@echo "  make config         Show resolved settings"
	@echo ""
	@echo "Overrides:"
	@echo "  WORKSPACE_DIR=/path/to/project"
	@echo "  PI_ARGS='--model sonnet:high'"

# Write .env before compose — lima doesn't forward env vars into the VM.
.env: FORCE
	@printf 'HOST_HOME=%s\nWORKSPACE_DIR=%s\nWORKING_DIR=%s\nPI_ARGS=%s\n' "$(HOST_HOME)" "$(WORKSPACE_DIR)" "$(WORKING_DIR)" "$(PI_ARGS)" > .env

dev: .env
	lima nerdctl compose --profile full-dev run --rm pi-full-dev

safe: .env
	lima nerdctl compose --profile safe run --rm pi-safe

FORCE:

bump:
	./pi-build bump

rollback:
	./pi-build rollback

list:
	./pi-build list

status:
	./pi-build status

prune:
	./pi-build prune

install-schedule: $(PLIST_GENERATED)
	ln -sf $(abspath $(PLIST_GENERATED)) $(PLIST_INSTALL_DIR)/$(PLIST_GENERATED)
	launchctl load $(PLIST_INSTALL_DIR)/$(PLIST_GENERATED)
	@echo "Scheduled weekly pi-build bump (Fridays at 21:00)."

uninstall-schedule:
	-launchctl unload $(PLIST_INSTALL_DIR)/$(PLIST_GENERATED) 2>/dev/null
	rm -f $(PLIST_INSTALL_DIR)/$(PLIST_GENERATED)
	rm -f $(PLIST_GENERATED)
	@echo "Uninstalled scheduled pi-build."

$(PLIST_GENERATED): $(PLIST_TEMPLATE)
	sed 's|__HOME__|$(HOME)|g' $< > $@
	@echo "Generated $@ from template."

config:
	@echo "WORKSPACE_DIR=$(WORKSPACE_DIR)"
	@echo "PI_ARGS=$(PI_ARGS)"
	@echo "HOST_HOME=$(HOST_HOME)"
	@echo "WORKING_DIR=$(WORKING_DIR)"
