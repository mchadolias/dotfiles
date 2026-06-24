# ============================================================================
# Cluster profile entry point (shell-neutral: sourced by both zsh and bash).
# Loaded by .zshrc / .bashrc when DOTFILES_PROFILE=cluster.
#   1. conda/micromamba lazy loaders
#   2. shared cluster aliases
#   3. site dispatch by hostname
#   4. login banner
# ============================================================================

: "${DOTFILES:=$HOME/dotfiles}"
: "${KM3NeT_CVMFS:=/cvmfs/km3net.egi.eu}"

# portable "is $1 a defined shell function?" — each shell's own mechanism
if [ -n "${ZSH_VERSION:-}" ]; then
	_have_fn() { [ -n "${functions[$1]:-}" ]; }      # zsh
else
	_have_fn() { typeset -f "$1" >/dev/null 2>&1; }  # bash
fi

# 1. Lazy conda/micromamba loaders (defines load_conda, load_micromamba)
[ -r "$DOTFILES/shell/conda-loaders.sh" ] && . "$DOTFILES/shell/conda-loaders.sh"

# 2. Shared cluster aliases (km3net, SLURM, work/home shortcuts)
[ -r "$DOTFILES/shell/aliases/cluster.sh" ] && . "$DOTFILES/shell/aliases/cluster.sh"

# 3. Site dispatch
case "$(hostname -s 2>/dev/null || hostname)" in
	*cca*)  [ -r "$DOTFILES/shell/profiles/cca.sh" ]  && . "$DOTFILES/shell/profiles/cca.sh" ;;
	*glui*) [ -r "$DOTFILES/shell/profiles/glui.sh" ] && . "$DOTFILES/shell/profiles/glui.sh" ;;
	*) echo "cluster profile: unknown host $(hostname -s 2>/dev/null) — no site config loaded." >&2 ;;
esac

# 4. Banner (after site env so $WORK etc. are available if you extend it)
[ -r "$DOTFILES/shell/cluster-banner.sh" ] && . "$DOTFILES/shell/cluster-banner.sh"

# 5. Auto-load conda/micromamba at login (interactive shells only)
case $- in
	*i*)
		if _have_fn load_micromamba; then
			load_micromamba
		elif _have_fn load_conda; then
			load_conda
		fi
		;;
esac

# 6. Activate default env if requested (set CONDA_DEFAULT_ENV in the *.local file)
if [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
	if _have_fn micromamba; then
		micromamba activate "$CONDA_DEFAULT_ENV"
	elif _have_fn conda; then
		conda activate "$CONDA_DEFAULT_ENV"
	fi
fi