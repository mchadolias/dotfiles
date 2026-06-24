# ============================================================================
# aliases/personal.sh — desktop / laptop-only aliases.
# Sourced from profiles/personal.sh. Never loaded on cluster machines.
# ============================================================================

# ---------- Sysadmin (guarded — require sudo) ----------
alias reboot='sudo systemctl reboot'
alias poweroff='sudo systemctl poweroff'
alias shutdown='sudo systemctl poweroff'

# ---------- Package managers (guarded — require sudo) ----------
if command -v apt >/dev/null 2>&1; then
	alias update='sudo apt update'
	alias upgrade='sudo apt upgrade -y'
	alias install='sudo apt install'
	alias remove='sudo apt remove'
elif command -v pacman >/dev/null 2>&1; then
	alias update='sudo pacman -Syu'
	alias install='sudo pacman -S'
	alias remove='sudo pacman -R'
elif command -v dnf >/dev/null 2>&1; then
	alias update='sudo dnf check-update'
	alias upgrade='sudo dnf upgrade -y'
	alias install='sudo dnf install'
	alias remove='sudo dnf remove'
fi

# ---------- Kitty ----------
if command -v kitty >/dev/null 2>&1; then
	alias kssh='kitty +kitten ssh'
	alias icat='kitty +kitten icat'
fi

# ---------- Python / uv ----------
if command -v uv >/dev/null 2>&1; then
	alias py='uv run python'
	alias uvs='uv sync'
	alias uva='uv add'
	alias uvr='uv run'
	alias uvt='uv run pytest'
fi

# ---------- Conda / Mamba ----------
if command -v mamba >/dev/null 2>&1 || command -v conda >/dev/null 2>&1; then
	alias ca='conda activate'
	alias cda='conda deactivate'
	alias cel='conda env list'
	alias cec='conda env create -f'
	alias cer='conda env remove -n'
fi

# ---------- Tmux ----------
if command -v tmux >/dev/null 2>&1; then
	alias tl='tmux list-sessions'
	alias ta='tmux attach -t'
	alias tn='tmux new -s'
	alias tk='tmux kill-session -t'
fi

# ---------- Open / Clipboard ----------
if command -v xdg-open >/dev/null 2>&1; then
	alias open='xdg-open'
fi

# Wayland clipboard (wl-clipboard)
if command -v wl-copy >/dev/null 2>&1; then
	alias pbcopy='wl-copy'
	alias pbpaste='wl-paste'
# X11 fallback
elif command -v xclip >/dev/null 2>&1; then
	alias pbcopy='xclip -selection clipboard'
	alias pbpaste='xclip -selection clipboard -o'
fi

# ---------- Docker / Podman ----------
if command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
	alias docker='podman'
fi

if command -v docker >/dev/null 2>&1 || command -v podman >/dev/null 2>&1; then
	alias dps='docker ps'
	alias dpsa='docker ps -a'
	alias di='docker images'
	alias drm='docker rm'
	alias drmi='docker rmi'
	alias dex='docker exec -it'
fi

# ---------- Network ----------
alias myip='curl -s https://ifconfig.me'
alias localip="ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127"