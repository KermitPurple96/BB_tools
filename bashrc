# =========================
# ~/.bashrc custom minimal hacker prompt
# =========================

# ---- TERM ----
export TERM=xterm

# ---- colores ----
RESET="\[\e[0m\]"
PURPLE="\[\e[35m\]"
RED="\[\e[31m\]"
GREEN="\[\e[32m\]"
YELLOW="\[\e[33m\]"
BLUE="\[\e[34m\]"

# ---- obtener IP de eth0 ----
get_ip() {
    ip -4 addr show eth0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1
}

# ---- prompt dinámico ----
set_prompt() {

    IP=$(get_ip)
    [ -z "$IP" ] && IP="noip"

    if [ "$EUID" -eq 0 ]; then
        SYMBOL="${RED}#"
    else
        SYMBOL="${PURPLE}\$"
    fi

    PS1="${PURPLE}\u${RESET}${GREEN}@${RESET}${YELLOW}${IP}${RESET} ${BLUE}\w${RESET}${SYMBOL}${RESET} "
}

PROMPT_COMMAND="history -a; history -c; history -r; set_prompt"


# =========================
# extras típicos útiles
# =========================

# historial pro
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# bash completion
[ -f /etc/bash_completion ] && . /etc/bash_completion

# aliases comfy
alias ll='ls -lah --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias ports='ss -tulpen'
alias myip='ip -4 a'

# calidad de vida
set -o noclobber
shopt -s checkwinsize
export LESS='-R'
