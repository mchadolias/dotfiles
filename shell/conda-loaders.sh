# ============================================================================
# conda-loaders.sh — lazy initialisers for conda and micromamba (bash + zsh).
# Defer heavy `conda init` until actually needed (login latency on HPC FS).
#   load_conda        # initialise conda for the current shell
#   load_micromamba   # initialise micromamba from CVMFS
#   load_julia        # add CVMFS Julia to PATH
# Override CONDA_HOME / KM3NeT_CVMFS per-site before sourcing.
# ============================================================================

# ~/.condarc intentionally lists only the local miniforge dirs, because conda
# leaves an *unset* ${WORK} as literal text and resolves it against $PWD. The
# shared cluster dirs are set here instead, where the shell expands $WORK.
#
# Separators differ per variable (verified against conda 26.1):
#   CONDA_ENVS_PATH  -> ":"  (legacy path-style list)
#   CONDA_PKGS_DIRS  -> ","  (sequence-style list)
_conda_site_dirs() {
	local root="${CONDA_HOME:-$HOME/tools/miniforge3}"
	if [ -n "${WORK:-}" ]; then
		export CONDA_ENVS_PATH="$WORK/software/private/conda/envs:$root/envs"
		export CONDA_PKGS_DIRS="$WORK/software/private/conda/pkgs,$root/pkgs"
	else
		export CONDA_ENVS_PATH="$root/envs"
		export CONDA_PKGS_DIRS="$root/pkgs"
	fi
}

load_conda() {
	_conda_site_dirs
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
	_conda_site_dirs
	local cvmfs="${KM3NeT_CVMFS:-/cvmfs/km3net.egi.eu}"
	if [ -f "$cvmfs/micromamba/micromamba_x86.sh" ]; then
		# shellcheck disable=SC1091
		. "$cvmfs/micromamba/micromamba_x86.sh"
		echo "Micromamba environment loaded from CVMFS."

		# The km3net hook only defines `micromamba` as a shell function, which is
		# invisible to non-interactive subshells (every `make`/script recipe line
		# spawns a fresh one). Recover the real binary from the function body and
		# export it, so non-interactive tools can call micromamba directly.
		if [ -z "${MAMBA_EXE:-}" ]; then
			local body exe
			if [ -n "${ZSH_VERSION:-}" ]; then
				body="$(functions micromamba 2>/dev/null)"
			else
				body="$(declare -f micromamba 2>/dev/null)"
			fi
			exe="$(printf '%s' "$body" | grep -oE "/[^[:space:]'\"]*micromamba[^[:space:]'\"]*" | head -n1)"
			[ -n "$exe" ] && [ -x "$exe" ] && export MAMBA_EXE="$exe"
		fi
		if [ -n "${MAMBA_EXE:-}" ]; then
			local exe_dir
			exe_dir="$(dirname "$MAMBA_EXE")"
			case ":$PATH:" in
				*":$exe_dir:"*) : ;;
				*) export PATH="$exe_dir:$PATH" ;;
			esac
		else
			echo "load_micromamba: could not locate the micromamba binary for PATH/MAMBA_EXE; make and other non-interactive tools may not find it." >&2
		fi
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
