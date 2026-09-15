# ============================================================================
# Personal profile — zsh entry point.
# Shared, shell-neutral setup lives in personal.common.sh; this file adds only
# the zsh-specific pieces.
# ============================================================================

[[ -r "$DOTFILES/shell/profiles/personal.common.sh" ]] \
	&& source "$DOTFILES/shell/profiles/personal.common.sh"

# ----------------------------------------------------------------------------
# uv completions (must run AFTER compinit, hence in the profile and not in
# .zprofile — compdef does not exist until .zshrc has run compinit).
# ----------------------------------------------------------------------------
if command -v uv >/dev/null 2>&1; then
	eval "$(uv generate-shell-completion zsh 2>/dev/null || true)"
fi

# ----------------------------------------------------------------------------
# Plugins (zinit + curated set)
# Skips if zinit can't be installed (offline machine, firewall), and defers
# until after compinit if it hasn't run yet.
# ----------------------------------------------------------------------------
if [[ -r "$DOTFILES/shell/plugins/loader.zsh" ]]; then
	source "$DOTFILES/shell/plugins/loader.zsh"
fi
