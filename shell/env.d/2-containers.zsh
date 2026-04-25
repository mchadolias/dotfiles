# shellcheck shell=bash
# ============================================================================
# env.d/2-containers.zsh — container-runtime XDG redirects.
# ============================================================================

# ---------- Docker ----------
# Only DOCKER_CONFIG is read by the docker CLI. The data root and cache live
# under /var/lib/docker by default and are configured in /etc/docker/daemon.json
# (key: "data-root"), not via env vars.
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# ---------- Apptainer (commented out — uncomment if you use it) ----------
# These ARE real env vars that Apptainer respects.
# export APPTAINER_CONFIGDIR="$XDG_CONFIG_HOME/apptainer"
# export APPTAINER_CACHEDIR="$XDG_CACHE_HOME/apptainer"
# export APPTAINER_TMPDIR="$XDG_CACHE_HOME/apptainer/tmp"

# ---------- Singularity (legacy name, same project as Apptainer) ----------
# export SINGULARITY_CACHEDIR="$XDG_CACHE_HOME/singularity"
# export SINGULARITY_TMPDIR="$XDG_CACHE_HOME/singularity/tmp"