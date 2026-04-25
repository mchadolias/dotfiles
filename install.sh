#!/usr/bin/env bash
# ============================================================================
# install.sh — symlink dotfiles into the right places.
#
# Idempotent: safe to run multiple times.
# Backs up any pre-existing real files (not symlinks) before overwriting.
# Never overwrites *.local files.
#
# Usage:
#   ./install.sh             # install everything
#   ./install.sh --dry-run   # show what would happen
#   ./install.sh --no-conda  # skip condarc (e.g. on cluster)
# ============================================================================
set -euo pipefail

DRY_RUN=false
DO_CONDA=true

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run)  DRY_RUN=true; shift ;;
		--no-conda) DO_CONDA=false; shift ;;
		-h|--help)
			sed -n '4,15p' "$0"; exit 0 ;;
		*) echo "Unknown arg: $1" >&2; exit 1 ;;
	esac
done

# ----------------------------------------------------------------------------
# Locate repo root (the directory containing this script)
# ----------------------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
log()  { printf '\033[0;36m[info]\033[0m  %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[0;31m[err]\033[0m   %s\n' "$*" >&2; exit 1; }

run() {
	if $DRY_RUN; then
		printf '  [dry-run] %s\n' "$*"
	else
		"$@"
	fi
}

# Symlink src -> dst, backing up dst if it's a real file/dir (not a symlink).
link() {
	local src="$1" dst="$2"

	[[ -e "$src" ]] || { warn "source missing: $src"; return; }

	# Already correctly linked? nothing to do.
	if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
		log "ok      $dst"
		return
	fi

	# Existing real file/dir: back it up.
	if [[ -e "$dst" || -L "$dst" ]]; then
		run mkdir -p "$BACKUP_DIR"
		log "backup  $dst -> $BACKUP_DIR/"
		run mv "$dst" "$BACKUP_DIR/"
	fi

	run mkdir -p "$(dirname "$dst")"
	log "link    $src -> $dst"
	run ln -s "$src" "$dst"
}

# ----------------------------------------------------------------------------
# Plan
# ----------------------------------------------------------------------------
log "Repo:    $DOTFILES_DIR"
log "Backup:  $BACKUP_DIR (only created if needed)"
$DRY_RUN && log "Mode:    DRY RUN"

# Shell
link "$DOTFILES_DIR/shell/zshenv"   "$HOME/.zshenv"
link "$DOTFILES_DIR/shell/zprofile" "$XDG_CONFIG_HOME/zsh/.zprofile"
link "$DOTFILES_DIR/shell/zshrc"    "$XDG_CONFIG_HOME/zsh/.zshrc"
link "$DOTFILES_DIR/shell/bashrc"   "$HOME/.bashrc"
link "$DOTFILES_DIR/shell/profile"  "$HOME/.profile"

# zsh env.d drop-ins — link the whole directory so new files added to the
# repo show up automatically without re-running install.sh.
link "$DOTFILES_DIR/shell/env.d"    "$XDG_CONFIG_HOME/zsh/env.d"

# Tmux
link "$DOTFILES_DIR/tmux/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"

# Git
link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# SSH
link "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
run mkdir -p "$HOME/.ssh/sockets"
run chmod 700 "$HOME/.ssh" "$HOME/.ssh/sockets" 2>/dev/null || true

# Kitty (only if kitty exists — skip on headless machines)
if command -v kitty >/dev/null 2>&1; then
	link "$DOTFILES_DIR/kitty/kitty.conf" "$XDG_CONFIG_HOME/kitty/kitty.conf"
fi

# Conda — substitutes __HOME__ in the placeholder file at install time.
# On shared filesystems where you don't want this rewritten, skip with --no-conda.
if $DO_CONDA && command -v conda >/dev/null 2>&1; then
	if $DRY_RUN; then
		log "would render condarc -> $HOME/.condarc with HOME=$HOME"
	else
		log "render  condarc -> $HOME/.condarc"
		sed "s|__HOME__|$HOME|g" "$DOTFILES_DIR/conda/condarc" > "$HOME/.condarc.new"
		if [[ -e "$HOME/.condarc" && ! -L "$HOME/.condarc" ]]; then
			mkdir -p "$BACKUP_DIR"
			mv "$HOME/.condarc" "$BACKUP_DIR/"
		fi
		mv "$HOME/.condarc.new" "$HOME/.condarc"
	fi
fi

# ----------------------------------------------------------------------------
# Local templates — copy if not present, never overwrite
# ----------------------------------------------------------------------------
copy_if_missing() {
	local src="$1" dst="$2"
	if [[ -e "$dst" ]]; then
		log "keep    $dst (exists)"
		return
	fi
	run mkdir -p "$(dirname "$dst")"
	log "create  $dst (template)"
	run cp "$src" "$dst"
}

copy_if_missing "$DOTFILES_DIR/git/gitconfig.local.example" "$HOME/.gitconfig.local"
copy_if_missing "$DOTFILES_DIR/ssh/config.local.example"    "$HOME/.ssh/config.local"

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------
log ""
log "Done."
log "Edit your identity in ~/.gitconfig.local"
log "Edit personal hosts in ~/.ssh/config.local"
$DRY_RUN || log "Backups (if any): $BACKUP_DIR"