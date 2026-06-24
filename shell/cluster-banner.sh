# shellcheck shell=bash
# ============================================================================
# cluster-banner.sh — friendly HPC login banner.
#
# Detects the cluster from the hostname and prints a coloured summary box
# with user, host, shell, date, and active SLURM job count.
# Site-specific environment activation lives in the site profile files
# (profiles/cca.zsh, profiles/glui.zsh), NOT here.
# ============================================================================

HOST_SHORT="$(hostname -s 2>/dev/null || hostname)"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"
SHELL_NAME="$(basename "$SHELL")"

# ------------------ Colours ------------------
RESET="\033[0m"
BOLD="\033[1m"
BORDER="\033[38;5;67m"
ACCENT="\033[38;5;39m"
JOB_COLOR="\033[38;5;220m"
CLUSTER_COLOR="\033[38;5;45m"   # default; overridden below

# ------------------ Cluster detection ------------------
case "$HOST_SHORT" in
	*cca*)
		CLUSTER_NAME="CC-IN2P3 Lyon"
		CLUSTER_COLOR="\033[38;5;208m"   # orange
		;;
	*glui*)
		CLUSTER_NAME="GLUON IFIC Valencia"
		CLUSTER_COLOR="\033[38;5;45m"    # cyan
		;;
	*)
		CLUSTER_NAME="Unknown Cluster"
		CLUSTER_COLOR="\033[38;5;196m"   # red
		;;
esac

# ------------------ SLURM job count ------------------
_get_job_count() {
	if command -v squeue >/dev/null 2>&1; then
		JOB_COUNT=$(squeue -h -u "$USER" 2>/dev/null | wc -l)
	else
		JOB_COUNT=0
	fi
}

# ------------------ Print ------------------
_print_cluster_banner() {
	_get_job_count
	printf "\n"
	printf "${BORDER}${BOLD}┌──────────────────────────────────────────────┐${RESET}\n"
	printf "${BORDER}${BOLD}│   ${CLUSTER_COLOR}HPC ${RESET} / ${CLUSTER_COLOR}%-35s${BORDER} │${RESET}\n" "$CLUSTER_NAME"
	printf "${BORDER}${BOLD}├──────────────────────────────────────────────┤${RESET}\n"
	printf "${BORDER}${BOLD}│   ${ACCENT}User:${RESET}  %-35s${BORDER} │${RESET}\n" "$USER"
	printf "${BORDER}${BOLD}│   ${ACCENT}Host:${RESET}  %-35s${BORDER} │${RESET}\n" "$HOST_SHORT"
	printf "${BORDER}${BOLD}│   ${ACCENT}Shell:${RESET} %-35s${BORDER} │${RESET}\n" "$SHELL_NAME"
	printf "${BORDER}${BOLD}│   ${ACCENT}Date:${RESET}  %-35s${BORDER} │${RESET}\n" "$DATE_NOW"
	if [ "${JOB_COUNT:-0}" -gt 0 ]; then
		printf "${BORDER}${BOLD}│   ${JOB_COLOR}Active jobs:${RESET} %-30s${BORDER} │${RESET}\n" "$JOB_COUNT"
	fi
	printf "${BORDER}${BOLD}└──────────────────────────────────────────────┘${RESET}\n"
}

# Show the banner only when:
#   - shell is interactive
#   - stdout is a real tty (not piped, not 'ssh host cmd')
#   - we're not nested inside an existing shell session (tmux/screen)
#     — first pane gets it, additional panes don't
#
# The TMUX/STY/cluster-banner-shown checks: TMUX is set inside tmux,
# STY inside screen, and we set our own marker so a manual re-source
# (e.g. `source ~/.zshrc`) doesn't redraw the banner mid-session.
case $- in
	*i*) ;;
	*)   return 0 2>/dev/null || exit 0 ;;
esac

[[ -t 1 ]]                          || return 0 2>/dev/null || exit 0
[[ -z "${TMUX:-}${STY:-}" ]]        || return 0 2>/dev/null || exit 0
[[ -z "${_CLUSTER_BANNER_SHOWN:-}" ]] || return 0 2>/dev/null || exit 0
export _CLUSTER_BANNER_SHOWN=1

printf "\nWelcome to ${CLUSTER_COLOR}${CLUSTER_NAME}${RESET}, ${ACCENT}${USER}${RESET}!\n"
_print_cluster_banner
