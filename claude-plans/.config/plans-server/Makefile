# Always-on local plan site — install/config helper.
# Serves http://plans.claude (127.0.0.2:80) via a Caddy systemd service reverse-proxying
# a per-user MkDocs dev server (live-reload) that renders ~/plans/src/*.md.

SHELL := /bin/bash
.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: help install caddy hosts service venv render-unit build \
        restart reload status logs render-status render-logs uninstall

CONFIG_DIR    := $(HOME)/.config/plans-server
PLANS_DIR     := $(HOME)/plans
PLANS_SRC     := $(PLANS_DIR)/src
UNIT_SRC      := $(CONFIG_DIR)/plans.service
UNIT_DST      := /etc/systemd/system/plans.service
USER_UNIT_DIR := $(HOME)/.config/systemd/user
RENDER_UNIT   := plans-render.service

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

install: caddy hosts service venv render-unit ## Full setup (site + render watcher)
	@echo "Done. Open http://plans.claude; write plans to $(PLANS_SRC)/<slug>.md"

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

service: ## Install + enable the Caddy site service (system)
	@mkdir -p $(PLANS_DIR)
	sudo cp $(UNIT_SRC) $(UNIT_DST)
	sudo systemctl daemon-reload
	sudo systemctl enable --now plans
	@echo "service enabled; status: systemctl status plans"

venv: ## Create the MkDocs venv + install pinned deps
	@python3 -m venv $(CONFIG_DIR)/venv
	$(CONFIG_DIR)/venv/bin/pip install --upgrade -r $(CONFIG_DIR)/requirements.txt

render-unit: ## Install + enable the per-user MkDocs serve unit
	@mkdir -p $(PLANS_SRC) $(USER_UNIT_DIR)
	cp $(CONFIG_DIR)/$(RENDER_UNIT) $(USER_UNIT_DIR)/$(RENDER_UNIT)
	systemctl --user daemon-reload
	systemctl --user enable --now plans-render
	@echo "mkdocs serve unit enabled; logs: journalctl --user -u plans-render -f"

build: ## One-off static build of the site to ~/plans/site
	@$(CONFIG_DIR)/venv/bin/mkdocs build -f $(CONFIG_DIR)/mkdocs.yml

restart: ## Restart the plan site service
	sudo systemctl restart plans

reload: ## Reload Caddy config (falls back to restart if needed)
	sudo systemctl reload plans || sudo systemctl restart plans

status: ## Show site service status
	systemctl status plans --no-pager

logs: ## Follow site service logs
	journalctl -u plans -f

render-status: ## Show render watcher status
	systemctl --user status plans-render --no-pager

render-logs: ## Follow render watcher logs
	journalctl --user -u plans-render -f

uninstall: ## Stop + remove services and /etc/hosts entry
	-systemctl --user disable --now plans-render
	-rm -f $(USER_UNIT_DIR)/$(RENDER_UNIT)
	systemctl --user daemon-reload
	-sudo systemctl disable --now plans
	-sudo rm -f $(UNIT_DST)
	sudo systemctl daemon-reload
	-sudo sed -i -E '/^127\.0\.0\.2[[:space:]]+plans(\.claude)?$$/d' /etc/hosts
	@echo "uninstalled (note: ~/plans, $(CONFIG_DIR), and packages are left intact)"
