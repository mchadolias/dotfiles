#!/usr/bin/env bash
# ============================================================================
# check_ticket.sh — ensure a valid Kerberos ticket exists.
# Renews if possible, otherwise re-authenticates via keytab.
# Intended to be called from cron / systemd timer.
# ============================================================================
set -euo pipefail

# --------------------------------------------------
# Configuration — override via env vars when needed
# --------------------------------------------------
: "${KRB_USERNAME:=$(whoami)}"
: "${KRB_REALM:=CC.IN2P3.FR}"
: "${KRB_CONFIG_DIR:=$HOME/.config/kerberos}"

PRINCIPAL="${KRB_USERNAME}@${KRB_REALM}"
KEYTAB="${KRB_CONFIG_DIR}/keytabs/${KRB_USERNAME}.keytab"
LOGFILE="${KRB_CONFIG_DIR}/kerberos.log"

mkdir -p "${KRB_CONFIG_DIR}/keytabs"
# Keytabs must never be world-readable.
chmod 700 "${KRB_CONFIG_DIR}" "${KRB_CONFIG_DIR}/keytabs" 2>/dev/null || true

log() {
	printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOGFILE"
}

trap 'log "Script failed at line $LINENO (exit $?)"' ERR

# --------------------------------------------------
# 1. Existing ticket? Try to renew.
# --------------------------------------------------
if klist -s; then
	log "Valid Kerberos ticket found for $PRINCIPAL"
	if kinit -R 2>/dev/null; then
		log "Ticket renewed"
		exit 0
	fi
	log "Renewal failed — will attempt keytab re-auth"
else
	log "No valid Kerberos ticket"
fi

# --------------------------------------------------
# 2. Re-authenticate via keytab.
# --------------------------------------------------
if [[ ! -f "$KEYTAB" ]]; then
	log "Keytab not found at $KEYTAB"
	exit 1
fi

# Guard: reject overly permissive keytab.
perms=$(stat -c '%a' "$KEYTAB" 2>/dev/null || stat -f '%Lp' "$KEYTAB")
if [[ "$perms" != "600" && "$perms" != "400" ]]; then
	log "Refusing to use keytab with perms $perms (must be 600 or 400)"
	exit 1
fi

if kinit -kt "$KEYTAB" "$PRINCIPAL"; then
	log "New ticket obtained via keytab"
	exit 0
fi

log "kinit failed"
exit 1