# ============================================================================
# Makefile — editing, formatting & maintenance helpers for the dotfiles repo.
#
#   make            # show this help
#   make fmt        # auto-format shell / python / markdown / yaml
#   make lint       # lint everything (mirrors .github/workflows/integrity.yaml)
#   make check      # structural checks + lint (the CI gate, run locally)
#
# Tools are optional: a target that needs a missing tool prints a hint and is
# skipped, so `make fmt` / `make lint` still run whatever IS installed.
# Install hints: `make check-tools`.
# ============================================================================

SHELL        := bash
.ONESHELL:
.SHELLFLAGS  := -e -o pipefail -c
.DEFAULT_GOAL := help

# --- Tool flags (override on the command line, e.g. `make lint SHFMT_FLAGS=...`)
SHFMT_FLAGS        ?= -i 0 -ci          # -i 0 = tabs (matches the repo style)
SHELLCHECK_FLAGS   ?= --severity=warning --exclude=SC1090,SC1091,SC2148
RUFF               ?= ruff
MARKDOWNLINT_FLAGS ?= --disable MD013 MD033

# --- File discovery (skip .git and the tools/ + kitty/tokyo_theme submodules)
#     Patterns are quoted so the shell does not glob them before find runs.
SH_FILES   := $(shell find . -path ./.git -prune -o -path ./tools -prune -o -path ./kitty/tokyo_theme -prune -o \( -name '*.sh' -o -name '*.bash' \) -print)
PY_FILES   := $(shell find . -path ./.git -prune -o -path ./tools -prune -o -path ./kitty/tokyo_theme -prune -o -name '*.py' -print)
MD_FILES   := $(shell find . -path ./.git -prune -o -path ./tools -prune -o -path ./kitty/tokyo_theme -prune -o -not -path '*/node_modules/*' -name '*.md' -print)
YAML_FILES := $(shell find . -path ./.git -prune -o -path ./tools -prune -o -path ./kitty/tokyo_theme -prune -o \( -name '*.yaml' -o -name '*.yml' \) -print)

# find expression reused by the permission targets
FIND_SH    := find . -path ./.git -prune -o -path ./tools -prune -o -path ./kitty/tokyo_theme -prune -o -name '*.sh' -print0

# ============================================================================
##@ Formatting
# ============================================================================

.PHONY: fmt format
fmt format: fmt-shell fmt-python fmt-md fmt-yaml ## Auto-format everything available

.PHONY: fmt-shell
fmt-shell: ## Format shell scripts with shfmt (tabs, indented cases)
	@command -v shfmt >/dev/null || { echo "⚠  shfmt not installed — skipping (see: make check-tools)"; exit 0; }
	[ -n "$(SH_FILES)" ] || { echo "no shell files"; exit 0; }
	shfmt -w -l $(SHFMT_FLAGS) $(SH_FILES)
	echo "✅ shfmt done"

.PHONY: fmt-python
fmt-python: ## Format Python with ruff
	@command -v $(RUFF) >/dev/null || { echo "⚠  ruff not installed — skipping"; exit 0; }
	[ -n "$(PY_FILES)" ] || { echo "no python files"; exit 0; }
	$(RUFF) format $(PY_FILES)

.PHONY: fmt-md
fmt-md: ## Format Markdown with prettier (optional)
	@command -v prettier >/dev/null || { echo "⚠  prettier not installed — skipping markdown format"; exit 0; }
	[ -n "$(MD_FILES)" ] || { echo "no markdown files"; exit 0; }
	prettier --write $(MD_FILES)

.PHONY: fmt-yaml
fmt-yaml: ## Format YAML with prettier (optional)
	@command -v prettier >/dev/null || { echo "⚠  prettier not installed — skipping yaml format"; exit 0; }
	[ -n "$(YAML_FILES)" ] || { echo "no yaml files"; exit 0; }
	prettier --write $(YAML_FILES)

# ============================================================================
##@ Linting (mirrors .github/workflows/integrity.yaml)
# ============================================================================

.PHONY: lint
lint: lint-shell lint-python lint-md ## Run all linters

.PHONY: lint-shell
lint-shell: ## ShellCheck on *.sh / *.bash
	@command -v shellcheck >/dev/null || { echo "⚠  shellcheck not installed — skipping"; exit 0; }
	[ -n "$(SH_FILES)" ] || { echo "no shell files"; exit 0; }
	shellcheck $(SHELLCHECK_FLAGS) $(SH_FILES)
	echo "✅ shellcheck clean"

.PHONY: lint-python
lint-python: ## ruff check on *.py
	@command -v $(RUFF) >/dev/null || { echo "⚠  ruff not installed — skipping"; exit 0; }
	[ -n "$(PY_FILES)" ] || { echo "no python files"; exit 0; }
	$(RUFF) check $(PY_FILES)

.PHONY: lint-md
lint-md: ## markdownlint on *.md
	@command -v markdownlint >/dev/null || { echo "⚠  markdownlint not installed — skipping"; exit 0; }
	[ -n "$(MD_FILES)" ] || { echo "no markdown files"; exit 0; }
	markdownlint $(MARKDOWNLINT_FLAGS) $(MD_FILES)

.PHONY: lint-yaml
lint-yaml: ## yamllint on *.yaml / *.yml (optional)
	@command -v yamllint >/dev/null || { echo "⚠  yamllint not installed — skipping"; exit 0; }
	[ -n "$(YAML_FILES)" ] || { echo "no yaml files"; exit 0; }
	yamllint $(YAML_FILES)

# ============================================================================
##@ Structural checks
# ============================================================================

.PHONY: check
check: required-files perms-check symlinks lint ## Full local gate (structure + lint)

.PHONY: required-files
required-files: ## Verify required files exist
	@missing=0
	for f in README.md LICENSE shell/zshrc shell/bashrc shell/aliases/general.sh tools/README.md tools/LICENSE; do
	  if [ -e "$$f" ]; then echo "✅ $$f"; else echo "❌ missing: $$f"; missing=1; fi
	done
	[ "$$missing" -eq 0 ] || { echo "Error: required file(s) missing."; exit 1; }

.PHONY: perms-check
perms-check: ## Scripts with a shebang must be executable
	@bad=0
	while IFS= read -r -d '' s; do
	  if head -1 "$$s" | grep -q '^#!'; then
	    [ -x "$$s" ] || { echo "❌ not executable: $$s"; bad=1; }
	  fi
	done < <($(FIND_SH))
	[ "$$bad" -eq 0 ] && echo "✅ executable bits OK" || { echo "Fix with: make fix-perms"; exit 1; }

.PHONY: symlinks
symlinks: ## Report broken symlinks
	@broken=$$(find . -path ./.git -prune -o -type l ! -exec test -e {} \; -print)
	if [ -n "$$broken" ]; then echo "❌ broken symlinks:"; echo "$$broken"; exit 1; fi
	echo "✅ no broken symlinks"

.PHONY: fix-perms
fix-perms: ## +x on shebang scripts, -x on sourced *.sh
	@while IFS= read -r -d '' s; do
	  if head -1 "$$s" | grep -q '^#!'; then
	    [ -x "$$s" ] || { chmod +x "$$s"; echo "+x $$s"; }
	  else
	    [ -x "$$s" ] && { chmod -x "$$s"; echo "-x $$s"; } || true
	  fi
	done < <($(FIND_SH))
	echo "✅ permissions normalised"

# ============================================================================
##@ Dotfiles management (wrappers)
# ============================================================================

.PHONY: install
install: ## Symlink dotfiles into place (./install.sh)
	./install.sh

.PHONY: install-dry
install-dry: ## Preview what install would do (./install.sh --dry-run)
	./install.sh --dry-run

.PHONY: stow
stow: ## Install packages via GNU Stow (./stow.sh)
	./stow.sh

.PHONY: unstow
unstow: ## Remove stow symlinks (./stow.sh --uninstall)
	./stow.sh --uninstall

.PHONY: build-tree
build-tree: ## Rebuild the stow/ symlink tree (./build-stow-tree.sh)
	./build-stow-tree.sh

.PHONY: submodules
submodules: ## Init / update git submodules
	git submodule update --init --recursive

# ============================================================================
##@ Utility
# ============================================================================

.PHONY: check-tools
check-tools: ## Show which optional tools are installed (+ install hints)
	@printf "%-14s %-8s %s\n" TOOL STATUS "INSTALL HINT"
	for t in shfmt:'go install mvdan.cc/sh/v3/cmd/shfmt@latest' \
	         shellcheck:'dnf install ShellCheck' \
	         ruff:'pip install ruff' \
	         markdownlint:'npm i -g markdownlint-cli' \
	         prettier:'npm i -g prettier' \
	         yamllint:'pip install yamllint' \
	         stow:'dnf install stow'; do
	  name=$${t%%:*}; hint=$${t#*:}
	  if command -v "$$name" >/dev/null; then status="✅ yes"; else status="— no"; fi
	  printf "%-14s %-8s %s\n" "$$name" "$$status" "$$hint"
	done

.PHONY: clean
clean: ## Remove editor/format backup files (*.bak *.orig *~)
	@find . -path ./.git -prune -o \( -name '*.bak' -o -name '*.orig' -o -name '*~' \) -print -delete

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} \
	  /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5); next } \
	  /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
