#!/usr/bin/env bash
# ============================================================================
# build-stow-tree.sh — (re)generate the stow/ packages from source-of-truth.
#
# The repo's "real" files live in shell/, git/, tmux/, ssh/, kitty/, conda/.
# Stow expects a different layout (package/<target-path>/file). Rather than
# duplicate content, this script builds stow/<pkg>/... as a tree of symlinks
# pointing back into the source-of-truth directories.
#
# Run this whenever you add/move/remove a tracked file. Idempotent.
#
# Usage:
#   ./build-stow-tree.sh             # build / refresh
#   ./build-stow-tree.sh --check     # exit 1 if stow tree is out of date
# ============================================================================
set -euo pipefail

CHECK=false
[[ "${1:-}" == "--check" ]] && CHECK=true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$ROOT/stow"

# ----------------------------------------------------------------------------
# Build a fresh staging tree, then compare/swap into place.
# Symlinks in the staging tree are RELATIVE so they survive being moved
# from staging → final location, and so they're portable across machines.
# ----------------------------------------------------------------------------
STAGING="$(mktemp -d)"
# Cleanup runs only after we're done with $STAGING. We disable it explicitly
# at the swap step or in --check after the comparison.
_cleanup() { rm -rf "$STAGING"; }
trap _cleanup EXIT

# Helper: link a source file into the staging tree at the given relative path.
# Args: <source-relative-to-ROOT> <package> <target-path-relative-to-HOME>
link_into() {
	local src_rel="$1" pkg="$2" tgt_rel="$3"
	local src_abs="$ROOT/$src_rel"
	local stage_path="$STAGING/$pkg/$tgt_rel"

	[[ -e "$src_abs" ]] || { echo "missing: $src_abs" >&2; exit 1; }

	mkdir -p "$(dirname "$stage_path")"

	# Compute the relative path as if the symlink were already in its final
	# location ($STOW_DIR/<pkg>/<tgt_rel>), NOT where it sits in staging.
	# Symlink relative paths are resolved at follow-time relative to the
	# symlink's own location, so the target path must be correct for the
	# final destination.
	local final_path="$STOW_DIR/$pkg/$tgt_rel"
	local final_dir
	final_dir="$(dirname "$final_path")"
	local rel
	rel="$(python3 -c '
import os, sys
print(os.path.relpath(sys.argv[1], sys.argv[2]))
' "$src_abs" "$final_dir")"

	ln -s "$rel" "$stage_path"
}

# ----------------------------------------------------------------------------
# Package definitions — one block per stow package.
# Format:  link_into <source>  <package>  <home-relative target>
# ----------------------------------------------------------------------------

# zsh package — files end up under $HOME/.config/zsh/, except .zshenv which
# goes directly to $HOME (zsh always reads it from there first).
link_into shell/zshenv             zsh  .zshenv
link_into shell/zprofile           zsh  .config/zsh/.zprofile
link_into shell/zshrc              zsh  .config/zsh/.zshrc

# zsh env.d drop-ins (numbered so they load in order)
link_into shell/env.d/1-apps.zsh        zsh .config/zsh/env.d/1-apps.zsh
link_into shell/env.d/2-containers.zsh  zsh .config/zsh/env.d/2-containers.zsh

# bash
link_into shell/bashrc             bash .bashrc
link_into shell/profile            bash .profile

# tmux
link_into tmux/tmux.conf           tmux .config/tmux/tmux.conf

# git
link_into git/gitconfig            git  .gitconfig

# ssh — only the public config; the user creates ~/.ssh/config.local from
# the example template (handled by the installer, not Stow).
link_into ssh/config               ssh  .ssh/config

# kitty
link_into kitty/kitty.conf         kitty .config/kitty/kitty.conf

# Note: condarc is intentionally NOT in a Stow package. YAML can't expand
# $HOME, so the file needs path substitution at install time.
# Use install.sh (the non-Stow installer) if you want condarc managed.

# ----------------------------------------------------------------------------
# Compare or swap.
# ----------------------------------------------------------------------------
if $CHECK; then
	if [[ ! -d "$STOW_DIR" ]]; then
		echo "stow/ tree missing — run $0 to build it." >&2
		exit 1
	fi

	# Compare the two trees by listing every symlink + its target.
	# This sidesteps `diff` following symlinks (which would either fail on
	# broken links or do unhelpful content comparison).
	list_links() {
		local dir="$1"
		(cd "$dir" && find . -type l -printf '%p -> %l\n' | sort)
	}

	staged_list="$(list_links "$STAGING")"
	current_list="$(list_links "$STOW_DIR")"

	if [[ "$staged_list" == "$current_list" ]]; then
		echo "stow/ tree is up to date."
		exit 0
	fi

	echo "stow/ tree is out of date — run $0 to rebuild." >&2
	echo "Differences (- current, + expected):" >&2
	diff <(echo "$current_list") <(echo "$staged_list") >&2 || true
	exit 1
fi

# Swap atomically-ish: remove old, move new into place.
if [[ -d "$STOW_DIR" ]]; then
	rm -rf "$STOW_DIR"
fi
mv "$STAGING" "$STOW_DIR"
trap - EXIT  # staging has been moved; nothing to clean up

echo "Built stow/ tree at: $STOW_DIR"
echo "Packages:"
for pkg in "$STOW_DIR"/*/; do
	echo "  - $(basename "$pkg")"
done