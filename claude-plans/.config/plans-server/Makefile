# Always-on local plan site — install/config helper
# Serves ~/plans over http://plans.claude (127.0.0.2:80) via a Caddy systemd service.

SHELL := /bin/bash
.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: help install caddy hosts service restart reload status logs uninstall

CONFIG_DIR := $(HOME)/.config/plans-server
PLANS_DIR  := $(HOME)/plans
UNIT_SRC   := $(CONFIG_DIR)/plans.service
UNIT_DST   := /etc/systemd/system/plans.service

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: caddy hosts service ## Full setup (caddy + /etc/hosts + service)
	@echo "Done. Open http://plans.claude"

caddy: ## Install Caddy if missing (pacman)
	@command -v caddy >/dev/null 2>&1 || sudo pacman -S --needed caddy

hosts: ## Ensure '127.0.0.2 plans.claude' in /etc/hosts (idempotent, migrates old 'plans')
	@if grep -qE '^127\.0\.0\.2[[:space:]]+plans\.claude$$' /etc/hosts; then \
		echo "/etc/hosts entry already present"; \
	else \
		sudo sed -i -E '/^127\.0\.0\.2[[:space:]]+plans$$/d' /etc/hosts; \
		echo '127.0.0.2  plans.claude' | sudo tee -a /etc/hosts >/dev/null; \
		echo "added '127.0.0.2 plans.claude' to /etc/hosts"; \
	fi

service: ## Install + enable the systemd service
	@mkdir -p $(PLANS_DIR)
	sudo cp $(UNIT_SRC) $(UNIT_DST)
	sudo systemctl daemon-reload
	sudo systemctl enable --now plans
	@echo "service enabled; status: systemctl status plans"

restart: ## Restart the plan site service
	sudo systemctl restart plans

reload: ## Reload Caddy config (falls back to restart if needed)
	sudo systemctl reload plans || sudo systemctl restart plans

status: ## Show service status
	systemctl status plans --no-pager

logs: ## Follow service logs
	journalctl -u plans -f

uninstall: ## Stop + remove service and /etc/hosts entry
	-sudo systemctl disable --now plans
	-sudo rm -f $(UNIT_DST)
	sudo systemctl daemon-reload
	-sudo sed -i -E '/^127\.0\.0\.2[[:space:]]+plans(\.claude)?$$/d' /etc/hosts
	@echo "uninstalled (note: ~/plans, $(CONFIG_DIR), and caddy package are left intact)"
