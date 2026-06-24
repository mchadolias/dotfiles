# ============================================================================
# conda-loaders.sh — lazy initialisers for conda and micromamba (bash + zsh).
# Defer heavy `conda init` until actually needed (login latency on HPC FS).
#   load_conda        # initialise conda for the current shell
#   load_micromamba   # initialise micromamba from CVMFS
#   load_julia        # add CVMFS Julia to PATH
# Override CONDA_HOME / KM3NeT_CVMFS per-site before sourcing.
# ============================================================================

_conda_guard_work() {
	[ -n "${WORK:-}" ] && return 0
	echo "conda-loaders: \$WORK is unset — ignoring \${WORK}-based dirs from ~/.condarc." >&2
	local root="${CONDA_HOME:-$HOME/tools/miniforge3}"
	export CONDA_ENVS_PATH="$root/envs"
	export CONDA_PKGS_DIRS="$root/pkgs"
}

load_conda() {
	_conda_guard_work
	# Already initialised? nothing to do.
	if [ -n "${CONDA_SHLVL:-}" ] && command -v conda >/dev/null 2>&1; then
		return 0
	fi

	# Where to find conda. Sites set CONDA_HOME; otherwise try common spots.
	local candidates="${CONDA_HOME:-} $HOME/tools/miniforge3 $HOME/miniconda3 $HOME/anaconda3"
	local home="" c
	for c in $candidates; do
		[ -n "$c" ] && [ -x "$c/bin/conda" ] && { home="$c"; break; }
	done
	if [ -z "$home" ]; then
		echo "load_conda: no conda installation found." >&2
		return 1
	fi

	# Shell-aware hook (bash vs zsh), with profile-script fallback.
	local hookshell=bash
	[ -n "${ZSH_VERSION:-}" ] && hookshell=zsh
	local setup
	setup="$("$home/bin/conda" "shell.$hookshell" hook 2>/dev/null)" || setup=""
	if [ -n "$setup" ]; then
		eval "$setup"
	elif [ -r "$home/etc/profile.d/conda.sh" ]; then
		. "$home/etc/profile.d/conda.sh"
	else
		export PATH="$home/bin:$PATH"
	fi
}

load_micromamba() {
	_conda_guard_work
	local cvmfs="${KM3NeT_CVMFS:-/cvmfs/km3net.egi.eu}"
	if [ -f "$cvmfs/micromamba/micromamba_x86.sh" ]; then
		# shellcheck disable=SC1091
		. "$cvmfs/micromamba/micromamba_x86.sh"
		echo "Micromamba environment loaded from CVMFS."
	else
		echo "Micromamba script not found at $cvmfs/micromamba/micromamba_x86.sh." >&2
	fi
}

load_julia() {
	local cvmfs="${KM3NeT_CVMFS:-/cvmfs/km3net.egi.eu}"
	if [ -x "$cvmfs/julia/x86_64/1.11.1/bin/julia" ]; then
		export PATH="$cvmfs/julia/x86_64/1.11.1/bin:$PATH"
		echo "Julia 1.11.1 added to PATH."
	else
		echo "Julia binary not found in CVMFS." >&2
	fi
}