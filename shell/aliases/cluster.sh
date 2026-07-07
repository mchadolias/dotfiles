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
