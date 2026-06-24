# ============================================================================
# CC-IN2P3 Lyon site profile.
# Merged from the original cluster_lyon.sh + the user-section of
# cc_lyon_profile.sh (the system parts of the latter live on /afs and load
# automatically — we don't reproduce them here).
# ============================================================================

# Typical environment variables set by the site profile (for reference):
export THRONG_DIR="/pbs/throng/km3net"
export KM3NET_THRONG_DIR="${THRONG_DIR}"
export KM3NET_HPSS="cchpsskm3net.in2p3.fr:/hpss/in2p3.fr/group/km3net"

# ---------- Group / experiment metadata ----------
# These are needed BEFORE $WORK is set, since $WORK references them.
export ORGANIZATION="km3net"
export EXPERIMENT="km3net"

# ---------- Working directory on /sps ----------
# Use double quotes so $ORGANIZATION and $USER actually expand.
# (The original cluster_lyon.sh used single quotes — this is the fix.)
export WORK="/sps/${ORGANIZATION}/users/${USER}"

# ---------- Conda installation path ----------
# Site-installed Anaconda. CONDA_HOME is consumed by load_conda when called.
export CONDA_HOME="/pbs/software/redhat-9-x86_64/anaconda/3.11"

# Add it to PATH so `conda` is callable for tab-completion / scripts,
# but DON'T auto-init — that's slow and shouldn't fire on every login.
case ":$PATH:" in
	*":$CONDA_HOME/bin:"*) ;;
	*) export PATH="$CONDA_HOME/bin:$PATH" ;;
esac

# ---------- Site profile loading ----------
# The system profile is maintained by the site admins and lives on /afs.
 if [ -r /afs/in2p3.fr/common/uss/system_profile ];then
     . /afs/in2p3.fr/common/uss/system_profile
  fi
 
  if [ -n "$THRONG_DIR" ];then
     if [ -r $THRONG_DIR/group_profile ];then
        . $THRONG_DIR/group_profile
     fi
  fi

# ---------- Module system ----------
export MODULEPATH="$KM3NET_THRONG_DIR/modulefiles/RHEL9"