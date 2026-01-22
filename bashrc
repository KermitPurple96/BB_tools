# =========================
# ~/.bashrc hacker prompt pro
# =========================

export TERM=xterm

# ---- colores ----
RESET="\[\e[0m\]"
PURPLE="\[\e[35m\]"
RED="\[\e[31m\]"
GREEN="\[\e[32m\]"
YELLOW="\[\e[33m\]"
BLUE="\[\e[34m\]"
CYAN="\[\e[36m\]"

# -------------------------
# IP dinámica
# -------------------------
get_ip() {
    ip -4 addr show eth0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1
}

# -------------------------
# git branch
# -------------------------
git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# -------------------------
# prompt dinámico
# -------------------------
set_prompt() {

    IP=$(get_ip)
    [ -z "$IP" ] && IP="noip"

    # símbolo root
    if [ "$EUID" -eq 0 ]; then
        SYMBOL="${RED}#"
    else
        SYMBOL="${PURPLE}\$"
    fi

    # venv
    if [ -n "$VIRTUAL_ENV" ]; then
        VENV_NAME=$(basename "$VIRTUAL_ENV")
        VENV_PART=" ${CYAN}(${VENV_NAME})${RESET}"
    else
        VENV_PART=""
    fi

    # git
    BRANCH=$(git_branch)
    if [ -n "$BRANCH" ]; then
        GIT_PART=" ${GREEN}(${BRANCH})${RESET}"
    else
        GIT_PART=""
    fi

    PS1="${PURPLE}\u${RESET}${GREEN}@${RESET}${YELLOW}${IP}${RESET} ${BLUE}\w${RESET}${VENV_PART}${GIT_PART}${SYMBOL}${RESET} "
}

PROMPT_COMMAND="history -a; history -c; history -r; set_prompt"

# -------------------------
# historial
# -------------------------
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# -------------------------
# bash completion
# -------------------------
[ -f /etc/bash_completion ] && . /etc/bash_completion

# -------------------------
# aliases
# -------------------------
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias ports='ss -tulpen'
alias myip='ip -4 a'

# PATHs
export PATH=$PATH:$HOME/go/bin:$HOME/.local/bin

set -o noclobber
shopt -s checkwinsize
export LESS='-R'
