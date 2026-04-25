#!/usr/bin/env bash
# ============================================================================
# stow.sh — install dotfiles with GNU Stow.
#
# Alternative to install.sh. Use this if you have stow installed and prefer
# its conventional package layout. install.sh is the more featureful option
# (handles condarc rendering, conditional kitty install, etc.) and is the
# right choice if you don't have stow.
#
# Usage:
#   ./stow.sh                  # install all packages
#   ./stow.sh --dry-run        # preview (uses stow's --no flag)
#   ./stow.sh --uninstall      # remove all symlinks (stow -D)
#   ./stow.sh zsh git tmux     # install only the listed packages
# ============================================================================
set -euo pipefail

# ----------------------------------------------------------------------------
# Defaults
# ----------------------------------------------------------------------------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$ROOT/stow"

DEFAULT_PACKAGES=(zsh bash git tmux ssh kitty)

DRY_RUN=false
UNINSTALL=false
PACKAGES=()

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
log()  { printf '\033[0;36m[info]\033[0m  %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[0;31m[err]\033[0m   %s\n' "$*" >&2; exit 1; }

# ----------------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run)   DRY_RUN=true; shift ;;
		--uninstall) UNINSTALL=true; shift ;;
		-h|--help)
			sed -n '4,15p' "$0"
			exit 0
			;;
		--) shift; PACKAGES+=("$@"); break ;;
		-*) die "Unknown option: $1" ;;
		*)  PACKAGES+=("$1"); shift ;;
	esac
done

[[ ${#PACKAGES[@]} -eq 0 ]] && PACKAGES=("${DEFAULT_PACKAGES[@]}")

# ----------------------------------------------------------------------------
# Sanity checks
# ----------------------------------------------------------------------------
command -v stow >/dev/null 2>&1 || die "GNU Stow is not installed. Use ./install.sh instead, or 'apt install stow' / 'brew install stow'."

if [[ ! -d "$STOW_DIR" ]]; then
	warn "stow/ tree missing — building it now."
	"$ROOT/build-stow-tree.sh"
fi

# Verify the stow tree is current. If not, rebuild before going further.
if ! "$ROOT/build-stow-tree.sh" --check >/dev/null 2>&1; then
	log "Stow tree out of date — rebuilding."
	"$ROOT/build-stow-tree.sh"
fi

# ----------------------------------------------------------------------------
# Validate requested packages
# ----------------------------------------------------------------------------
for pkg in "${PACKAGES[@]}"; do
	[[ -d "$STOW_DIR/$pkg" ]] || die "No such package: $pkg (in $STOW_DIR)"
done

# Skip kitty on machines without kitty installed (matches install.sh behaviour).
if printf '%s\n' "${PACKAGES[@]}" | grep -qx kitty; then
	if ! command -v kitty >/dev/null 2>&1; then
		warn "kitty not installed on this machine — skipping kitty package."
		PACKAGES=("${PACKAGES[@]/kitty}")
	fi
fi

# ----------------------------------------------------------------------------
# Build the stow command line
# ----------------------------------------------------------------------------
STOW_FLAGS=(-v --target "$HOME" --dir "$STOW_DIR")
$DRY_RUN && STOW_FLAGS+=(--no)

if $UNINSTALL; then
	STOW_FLAGS+=(-D)
	log "Uninstalling: ${PACKAGES[*]}"
else
	# --restow handles the "already partially installed" case gracefully:
	# it unstows then re-stows in one go, ensuring the final state is correct.
	STOW_FLAGS+=(--restow)
	log "Installing:   ${PACKAGES[*]}"
fi

$DRY_RUN && log "Mode: DRY RUN (no changes will be made)"
log "Target:       $HOME"
log "Source:       $STOW_DIR"

# ----------------------------------------------------------------------------
# Pre-flight: warn about pre-existing real files that will conflict.
# Stow refuses to overwrite real (non-symlink) files, so flag them up front.
# ----------------------------------------------------------------------------
if ! $UNINSTALL && ! $DRY_RUN; then
	conflicts=()
	for pkg in "${PACKAGES[@]}"; do
		[[ -z "$pkg" ]] && continue
		while IFS= read -r src; do
			rel="${src#$STOW_DIR/$pkg/}"
			tgt="$HOME/$rel"
			# Real file (not a symlink) at target = conflict.
			if [[ -e "$tgt" && ! -L "$tgt" ]]; then
				conflicts+=("$tgt")
			fi
		done < <(find "$STOW_DIR/$pkg" -type l)
	done

	if [[ ${#conflicts[@]} -gt 0 ]]; then
		warn "Real files exist at these target paths and will block stow:"
		for c in "${conflicts[@]}"; do
			printf '         %s\n' "$c" >&2
		done
		echo >&2
		warn "Either move them aside, or use ./install.sh which auto-backs them up."
		exit 1
	fi
fi

# ----------------------------------------------------------------------------
# Run stow per package (separate invocations for clearer error messages)
# ----------------------------------------------------------------------------
for pkg in "${PACKAGES[@]}"; do
	[[ -z "$pkg" ]] && continue
	log "stow $pkg"
	stow "${STOW_FLAGS[@]}" "$pkg"
done

# ----------------------------------------------------------------------------
# Post-install: drop the *.local templates if missing.
# Stow can't do this — it's a copy-on-first-install, not a symlink.
# ----------------------------------------------------------------------------
if ! $UNINSTALL && ! $DRY_RUN; then
	copy_if_missing() {
		local src="$1" dst="$2"
		if [[ -e "$dst" ]]; then
			log "keep    $dst (exists)"
			return
		fi
		mkdir -p "$(dirname "$dst")"
		cp "$src" "$dst"
		log "create  $dst (template)"
	}

	copy_if_missing "$ROOT/git/gitconfig.local.example" "$HOME/.gitconfig.local"
	copy_if_missing "$ROOT/ssh/config.local.example"    "$HOME/.ssh/config.local"

	# SSH dirs need restrictive perms.
	mkdir -p "$HOME/.ssh/sockets"
	chmod 700 "$HOME/.ssh" "$HOME/.ssh/sockets" 2>/dev/null || true
fi

log ""
log "Done."
if ! $UNINSTALL; then
	log "Note: condarc is NOT managed by stow (it can't expand \$HOME)."
	log "      If you need it, run ./install.sh instead, which renders it."
	log ""
	log "Edit identity:"
	log "  ~/.gitconfig.local"
	log "  ~/.ssh/config.local"
fi