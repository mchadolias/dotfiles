# ============================================================================
# Cross-shell aliases (bash + zsh).
# Source from both ~/.bashrc and ~/.zshrc.
# ============================================================================

# ---------- Navigation ----------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias c='clear'
alias h='cd ~'

# ---------- Listings ----------
# Prefer eza/exa when available, fall back to ls.
if command -v eza >/dev/null 2>&1; then
	alias ls='eza --group-directories-first'
	alias ll='eza -lah --group-directories-first --git'
	alias la='eza -a'
	alias lt='eza --tree --level=2'
else
	alias ls='ls --color=auto'
	alias ll='ls -alhF'
	alias la='ls -A'
	alias l='ls -CF'
fi

# ---------- Grep family ----------
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

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

# ---------- Misc ----------
alias wget='wget -c'

# ---------- Tools ---------- 
if command -v nvim >/dev/null 2>&1; then
	alias vim='nvim'
fi

if command -v tmux >/dev/null 2>&1; then
	alias tmux='tmux -f "$XDG_CONFIG_HOME/tmux/tmux.conf"'
fi

if command -v kitty >/dev/null 2>&1; then
	alias kssh='kitty +kitten ssh'
fi

if command -v yazi >/dev/null 2>&1; then
	alias yazi='yazi --config "$XDG_CONFIG_HOME/yazi/config.yaml"'
fi

# ---------- Script Aliases ----------
alias dotfiles='cd "$DOTFILES"'
alias check_tickets='./check_ticket.sh'