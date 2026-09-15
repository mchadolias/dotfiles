# shellcheck shell=bash
# ============================================================================
# Personal profile — bash entry point.
# Shared, shell-neutral setup lives in personal.common.sh; this file adds only
# the bash-specific pieces.
#
# Until this file existed, .bashrc's dispatch fell through to personal.sh —
# which was zsh code. The PATH edits silently no-opped under bash and conda
# was initialised twice, once with the wrong hook dialect.
# ============================================================================

[ -r "$DOTFILES/shell/profiles/personal.common.sh" ] \
	&& . "$DOTFILES/shell/profiles/personal.common.sh"

# ----------------------------------------------------------------------------
# uv completions
# ----------------------------------------------------------------------------
if command -v uv >/dev/null 2>&1; then
	eval "$(uv generate-shell-completion bash 2>/dev/null || true)"
fi
