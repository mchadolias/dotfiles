# ============================================================================
# Personal profile — loaded on a desktop / laptop.
# Anything that wouldn't make sense on a shared cluster goes here.
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Personal aliases
# ----------------------------------------------------------------------------
[ -r "$DOTFILES/shell/aliases/personal.sh" ] && source "$DOTFILES/shell/aliases/personal.sh"

# ----------------------------------------------------------------------------
# 2. Conda / Mamba
# Replace with your install path or override via $CONDA_HOME in ~/.zshrc.local
# ----------------------------------------------------------------------------
: "${CONDA_HOME:=$HOME/tools/miniforge3}"

if [[ -x "$CONDA_HOME/bin/conda" ]]; then
	__conda_setup="$("$CONDA_HOME/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
	if [ $? -eq 0 ]; then
		eval "$__conda_setup"
	elif [ -f "$CONDA_HOME/etc/profile.d/conda.sh" ]; then
		. "$CONDA_HOME/etc/profile.d/conda.sh"
	else
		export PATH="$CONDA_HOME/bin:$PATH"
	fi
	unset __conda_setup
fi

# Mamba (if installed alongside)
if [[ -x "$CONDA_HOME/bin/mamba" ]]; then
	export MAMBA_EXE="$CONDA_HOME/bin/mamba"
	export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}"
	__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
	if [ $? -eq 0 ]; then
		eval "$__mamba_setup"
	else
		# shellcheck disable=SC2139  # eager expansion is intentional
		alias mamba="$MAMBA_EXE"
	fi
	unset __mamba_setup
fi

# ----------------------------------------------------------------------------
# 3. Julia (juliaup-managed install)
# ----------------------------------------------------------------------------
if [[ -d "$HOME/tools/julia/bin" ]]; then
	# shellcheck disable=SC2206  # zsh array, not subject to bash word-splitting
	path=("$HOME/tools/julia/bin" $path)
	export PATH
fi

# ----------------------------------------------------------------------------
# 4. uv completions (must run AFTER compinit, hence in profile not .zprofile)
# ----------------------------------------------------------------------------
if command -v uv >/dev/null 2>&1; then
	eval "$(uv generate-shell-completion zsh 2>/dev/null || true)"
fi

# ----------------------------------------------------------------------------
# 5. Plugins (zinit + curated set)
# Lives in $DOTFILES/shell/plugins/. Skips if zinit can't be installed
# (offline machine, firewall) or if compinit hasn't run yet (defers).
# ----------------------------------------------------------------------------
if [[ -r "$DOTFILES/shell/plugins/loader.zsh" ]]; then
	source "$DOTFILES/shell/plugins/loader.zsh"
fi

# ----------------------------------------------------------------------------
# 6. Tmux auto-attach inside kitty (opt out with NO_TMUX=1)
# ----------------------------------------------------------------------------
if [[ -z "${TMUX:-}" && "$TERM" == "xterm-kitty" && -z "${NO_TMUX:-}" ]] \
	&& command -v tmux >/dev/null 2>&1; then
	if [[ "$PWD" == "$HOME/projects"/* ]]; then
		# Sanitise the project name for tmux (no dots/colons/spaces)
		_session_name=$(basename "$PWD" | tr ' .:' '___')
	else
		_session_name="main"
	fi
	tmux attach -t "$_session_name" 2>/dev/null \
		|| tmux new -s "$_session_name"
	unset _session_name
fi

# ----------------------------------------------------------------------------
# 7. Greeter
# ----------------------------------------------------------------------------
if command -v fastfetch >/dev/null 2>&1; then
	fastfetch
fi