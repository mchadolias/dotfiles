# shellcheck shell=bash
# ============================================================================
# env.d/1-apps.zsh — XDG redirects for tools that don't follow the spec.
# Universal: works on any machine. Machine-specific paths (e.g. OLLAMA_MODELS
# pointing at a particular drive) belong in ~/.zshrc.local instead.
# ============================================================================

# ---------- GnuPG ----------
export GNUPGHOME="$XDG_DATA_HOME/gnupg"

# ---------- Password store (pass) ----------
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"

# ---------- Wget / Less ----------
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export LESSHISTFILE="$XDG_CACHE_HOME/lesshst"

# ---------- NSS (Mozilla, libnss) ----------
export SSL_DIR="sql:$XDG_DATA_HOME/pki/nssdb"

# ---------- CUDA ----------
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"

# ---------- .NET ----------
export DOTNET_ROOT="$XDG_DATA_HOME/dotnet"
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
# Prepend if the path exists; avoid pointless PATH entries.
if [[ -d "$DOTNET_ROOT" ]]; then
	typeset -U path PATH
	# shellcheck disable=SC2206  # zsh array, not subject to bash word-splitting
	path=("$DOTNET_ROOT" "$DOTNET_ROOT/tools" $path)
	export PATH
fi

# ---------- IDE / Editor plugins ----------
export CODEIUM_CONFIG_HOME="$XDG_CONFIG_HOME/codeium"
export SONARLINT_USER_HOME="$XDG_DATA_HOME/sonarlint"

# ---------- Notes ----------
# If you want gpg-agent to handle SSH keys instead of ssh-agent:
#   1. enable-ssh-support in ~/.gnupg/gpg-agent.conf
#   2. nothing else — the ssh-agent block in ~/.zprofile (section 5) probes
#      with `ssh-add -l` and defers to any reachable agent, gpg-agent included.
#      To pin a specific socket, set $SSH_AUTH_SOCK in ~/.zprofile.local; it
#      is sourced after that block and so wins.
