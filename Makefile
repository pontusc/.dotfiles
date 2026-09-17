SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

.PHONY: help install-vivaldi

help:
	@printf '%s\n' 'make install-vivaldi  Install Omarchy theme syncing for Vivaldi'

install-vivaldi:
	@if [[ "$$(id -u)" == 0 ]]; then printf '%s\n' 'Run make install-vivaldi as your desktop user, not with sudo.' >&2; exit 1; fi
	@stow -R vivaldi omarchy
	@sudo ./vivaldi/.local/bin/vivaldi-theme-install "$$(id -un)"
	@THEME="$$(omarchy theme current)"; omarchy theme set "$$THEME"
	@printf '%s\n' 'Installation complete. Fully quit and reopen Vivaldi to activate theme syncing.'
