# ============================================================================
# Plugin loader entry point. Sourced from profiles/personal.zsh.
# Loads zinit and a curated set of plugins. Defers if compinit hasn't run.
# ============================================================================

# Only run in interactive shells.
[[ -o interactive ]] || return

# Only on personal profile; clusters get unpredictable network and don't
# need the plugins anyway.
[[ "${DOTFILES_PROFILE:-personal}" == "personal" ]] || return

# Sanity: $DOTFILES is set by .zshenv. Bail loudly if not.
if [[ -z "${DOTFILES:-}" ]]; then
	echo "plugin loader: \$DOTFILES is not set; skipping plugins." >&2
	return
fi

_load_plugins() {
	# shellcheck disable=SC1091
	source "$DOTFILES/shell/plugins/zinit.zsh"
}

# shellcheck disable=SC2154  # zsh's $+functions[name] is a function-existence test
if (( $+functions[compdef] )); then
	# compinit has run; load plugins now.
	_load_plugins
else
	# compinit hasn't run yet; defer until first prompt.
	autoload -Uz add-zsh-hook
	_load_plugins_after_compinit() {
		[[ -o interactive ]] || return
		add-zsh-hook -d precmd _load_plugins_after_compinit
		_load_plugins
		unset -f _load_plugins_after_compinit
	}
	add-zsh-hook precmd _load_plugins_after_compinit
fi