# shellcheck shell=bash
# ============================================================================
# zinit + plugin definitions. Called by loader.zsh once compinit has run.
# ============================================================================

# zinit installation directory (XDG-compliant).
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Auto-install zinit on first run. Requires network — fail gracefully on
# offline / firewalled machines.
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
	if command -v git >/dev/null 2>&1; then
		echo "Installing zinit (one-time)..." >&2
		mkdir -p "${ZINIT_HOME%/*}"
		if ! git clone --depth=1 \
			https://github.com/zdharma-continuum/zinit.git \
			"$ZINIT_HOME" 2>/dev/null; then
			echo "zinit install failed (no network?). Skipping plugins." >&2
			return
		fi
	else
		return
	fi
fi

# shellcheck disable=SC1091
source "$ZINIT_HOME/zinit.zsh"

# ============================================================================
# Plugins, in load order.
# ============================================================================

# Extra completions — load before plugins that consume completion data.
zinit light zsh-users/zsh-completions

# fzf-tab needs fzf installed.
if command -v fzf >/dev/null 2>&1; then
	zinit light Aloxaf/fzf-tab

	# fzf-tab styling
	zstyle ':fzf-tab:*' switch-group '<' '>'
	zstyle ':fzf-tab:*' popup-pad 30 0
	# Use tmux popup if inside tmux, else regular fzf
	if [[ -n "$TMUX" ]]; then
		zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
	fi
fi

# Auto-pair brackets / quotes.
zinit light hlissner/zsh-autopair

# Inline suggestions from history (the grey ghost text).
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#777777'

# ============================================================================
# Syntax highlighting — MUST be the last plugin loaded.
# ============================================================================
zinit light zsh-users/zsh-syntax-highlighting

# ╔══════════════════════════════════════════════════════════════════════╗
# ║  DO NOT ADD PLUGINS BELOW THIS LINE.                                 ║
# ║  zsh-syntax-highlighting must run last; anything below it breaks     ║
# ║  highlighting silently.                                              ║
# ╚══════════════════════════════════════════════════════════════════════╝