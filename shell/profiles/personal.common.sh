# shellcheck shell=bash
# ============================================================================
# Personal profile — shell-neutral parts, sourced by personal.zsh and
# personal.bash. Anything that wouldn't make sense on a shared cluster.
#
# Keep this file portable: no zsh arrays, no bash-only syntax. Shell-specific
# setup (completions, plugin manager) belongs in the per-shell wrappers.
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Personal aliases
# ----------------------------------------------------------------------------
[ -r "$DOTFILES/shell/aliases/personal.sh" ] && . "$DOTFILES/shell/aliases/personal.sh"

# ----------------------------------------------------------------------------
# 2. Conda / Mamba
# Override the install path with $CONDA_HOME in ~/.zshrc.local / ~/.bashrc.local
# ----------------------------------------------------------------------------
: "${CONDA_HOME:=$HOME/tools/miniforge3}"

# Pick the hook dialect from the running shell instead of hardcoding zsh.
_personal_hookshell=bash
[ -n "${ZSH_VERSION:-}" ] && _personal_hookshell=zsh

if [ -x "$CONDA_HOME/bin/conda" ]; then
	if __conda_setup="$("$CONDA_HOME/bin/conda" "shell.$_personal_hookshell" hook 2>/dev/null)"; then
		eval "$__conda_setup"
	elif [ -r "$CONDA_HOME/etc/profile.d/conda.sh" ]; then
		. "$CONDA_HOME/etc/profile.d/conda.sh"
	else
		PATH="$CONDA_HOME/bin:$PATH"
		export PATH
	fi
	unset __conda_setup
fi

# Mamba (if installed alongside)
if [ -x "$CONDA_HOME/bin/mamba" ]; then
	export MAMBA_EXE="$CONDA_HOME/bin/mamba"
	export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}"
	if __mamba_setup="$("$MAMBA_EXE" shell hook --shell "$_personal_hookshell" \
		--root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"; then
		eval "$__mamba_setup"
	else
		# shellcheck disable=SC2139  # eager expansion is intentional
		alias mamba="$MAMBA_EXE"
	fi
	unset __mamba_setup
fi

unset _personal_hookshell

# ----------------------------------------------------------------------------
# 3. Julia (juliaup-managed install)
# Portable PATH prepend. The previous `path=(...)` zsh array silently did
# nothing when bash sourced this profile.
# ----------------------------------------------------------------------------
if [ -d "$HOME/tools/julia/bin" ]; then
	case ":$PATH:" in
		*":$HOME/tools/julia/bin:"*) ;;
		*) PATH="$HOME/tools/julia/bin:$PATH"; export PATH ;;
	esac
fi

# ----------------------------------------------------------------------------
# 4. Tmux auto-attach inside kitty (opt out with NO_TMUX=1)
# ----------------------------------------------------------------------------
if [ -z "${TMUX:-}" ] && [ "${TERM:-}" = "xterm-kitty" ] && [ -z "${NO_TMUX:-}" ] \
	&& command -v tmux >/dev/null 2>&1; then
	case "$PWD" in
		"$HOME/projects"/*)
			# Sanitise the project name for tmux (no dots/colons/spaces)
			_session_name=$(basename "$PWD" | tr ' .:' '___')
			;;
		*) _session_name="main" ;;
	esac
	tmux attach -t "$_session_name" 2>/dev/null || tmux new -s "$_session_name"
	unset _session_name
fi

# ----------------------------------------------------------------------------
# 5. Greeter
# Guarded the same way as cluster-banner.sh: interactive shells writing to a
# real tty, once per session. Unguarded, fastfetch corrupted the output of
# `zsh -ic '...'` and of any script that sourced this profile.
# ----------------------------------------------------------------------------
case $- in
	*i*)
		if [ -t 1 ] && [ -z "${_PERSONAL_GREETER_SHOWN:-}" ] \
			&& command -v fastfetch >/dev/null 2>&1; then
			export _PERSONAL_GREETER_SHOWN=1
			fastfetch
		fi
		;;
esac
