# shellcheck shell=bash
# ============================================================================
# aliases/cluster.sh — HPC / km3net-specific aliases.
# Sourced from profiles/cluster.sh. The base navigation/grep aliases
# come from shell/aliases/general.sh.
# ============================================================================

# ---------- CVMFS shortcuts ----------
alias km3net_cvmfs='cd /cvmfs/km3net.egi.eu'
alias km3net_software='cd /cvmfs/km3net.egi.eu/software'

# ---------- SLURM ----------
if command -v squeue >/dev/null 2>&1; then
	alias sq='squeue -u "$USER"'
	alias sqa='squeue -u "$USER" -o "%.18i %.9P %.40j %.8T %.10M %.6D %R"'
	alias scancel-mine='squeue -h -u "$USER" -o "%i" | xargs -r scancel'
fi

# ---------- Path shortcuts ----------
# WORK is set per-site in profiles/cca.sh / profiles/glui.sh.
alias work='cd "$WORK"'
alias home='cd "$HOME"'

# ---------- Tools ----------

# Override the path in ~/.zshrc.local if your submodule checkout differs:
#   export CLUSTER_TOOLS_BIN=/some/other/path

_link_tools() {
	local dir="$1" pattern="$2" suffix="$3" runner="${4:-}"
	local tool name
	[[ -d "$dir" ]] || return 0
	while IFS= read -r -d '' tool; do
		if [[ -n "$runner" ]]; then
			[[ -r "$tool" ]] || continue   # interpreted: just needs to be readable
		else
			[[ -x "$tool" ]] || continue   # self-executing: needs +x
		fi
		name="$(basename "$tool" "$suffix")"
		alias "$name"="${runner:+$runner }$tool"
	done < <(find "$dir" -maxdepth 1 -type f -name "$pattern" -print0 2>/dev/null)
}

: "${CLUSTER_TOOLS_BIN:=$DOTFILES/tools/bash}"
: "${CLUSTER_TOOLS_SCRIPTS:=$DOTFILES/tools/scripts}"

_link_tools "$CLUSTER_TOOLS_BIN"     '*.sh' '.sh'
_link_tools "$CLUSTER_TOOLS_SCRIPTS" '*.py' '.py' python3

unset -f _link_tools