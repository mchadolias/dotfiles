# ============================================================================
# GLUON IFIC Valencia site profile.
# Merged from cluster_gluon.sh + the user-section of ific_gluon_profile.sh.
# ============================================================================

# ---------- Group / experiment metadata ----------
export ORGANIZATION="vega"
export EXPERIMENT="km3net"

# ---------- Working directory on /lustre ----------
# Double quotes — original cluster_gluon.sh used single quotes which left
# literal '${ORGANIZATION}' / '${USER}' in the path.
export WORK="/lustre/ific.uv.es/prj/gl/${ORGANIZATION}/${USER}"

