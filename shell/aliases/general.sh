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
alias dotfiles='cd "$DOTFILES"'

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

# ---------- Misc ----------
alias wget='wget -c'

# ---------- Git ----------
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gba='git branch -a'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gll='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gf='git fetch --prune'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gcp='git cherry-pick'
alias grh='git reset --hard'
alias grs='git reset --soft'
alias gcl='git clone'

# ---------- Tools ----------
if command -v nvim >/dev/null 2>&1; then
	alias vim='nvim'
fi

if command -v tmux >/dev/null 2>&1; then
	alias tmux='tmux -f "$XDG_CONFIG_HOME/tmux/tmux.conf"'
fi

