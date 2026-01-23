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

# =========================
# origins_ofa
# JSON → detect CDN vs origin real
# Uso: origins_ofa file.json
# =========================
origins_ofa() {

    local FILE="$1"

    if [ -z "$FILE" ]; then
        echo "Uso: origins_ofa file.json"
        return 1
    fi

    if [ ! -f "$FILE" ]; then
        echo "Archivo no encontrado: $FILE"
        return 1
    fi

    # ---- colores ----
    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local RESET="\033[0m"

    echo -e "${BLUE}Subdomain\tIP\tASN/Provider\tType${RESET}"
    echo "--------------------------------------------------------------"

    # cache ASN lookups (más rápido)
    declare -A ASN_CACHE

    jq -r '.[] | "\(.subdomain)\t\(.ip)"' "$FILE" | sort -u | while read -r sub ip; do

        # -------------------------
        # obtener ASN (con cache)
        # -------------------------
        if [[ -z "${ASN_CACHE[$ip]}" ]]; then
            ASN_CACHE[$ip]=$(whois -h whois.cymru.com " -v $ip" 2>/dev/null | tail -n 1)
        fi

        local ASN_INFO="${ASN_CACHE[$ip]}"
        local PROVIDER
        PROVIDER=$(echo "$ASN_INFO" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)

        local LOWER
        LOWER=$(echo "$PROVIDER" | tr '[:upper:]' '[:lower:]')

        local TYPE COLOR

        # -------------------------
        # detección CDN/SaaS
        # -------------------------
        if echo "$LOWER" | grep -Eiq 'fastly|cloudflare|akamai|edgecast|cloudfront|amazon|aws|google|gcp|shopify|salesforce|azure|cdn'; then
            TYPE="CDN"
            COLOR="$RED"
        else
            TYPE="ORIGIN?"
            COLOR="$GREEN"
        fi

        printf "${YELLOW}%-30s${RESET} %-15s ${COLOR}%-35s %-8s${RESET}\n" \
            "$sub" "$ip" "$PROVIDER" "$TYPE"

    done
}

# =========================
# origins_lepus
# subdomain|ip,ip,ip → CDN vs ORIGIN detector
# Uso: origins_lepus resolved_public.csv
# =========================
origins_lepus() {

    local FILE="$1"

    if [ -z "$FILE" ]; then
        echo "Uso: origins_lepus resolved_public.csv"
        return 1
    fi

    if [ ! -f "$FILE" ]; then
        echo "Archivo no encontrado: $FILE"
        return 1
    fi

    # ---- colores ----
    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local RESET="\033[0m"

    echo -e "${BLUE}Subdomain\t\t\tIP\t\tProvider\t\t\tType${RESET}"
    echo "---------------------------------------------------------------------------------------"

    declare -A ASN_CACHE

    lookup_asn() {
        local ip="$1"

        if [[ -z "${ASN_CACHE[$ip]}" ]]; then
            ASN_CACHE[$ip]=$(whois -h whois.cymru.com " -v $ip" 2>/dev/null | tail -n 1)
        fi

        echo "${ASN_CACHE[$ip]}"
    }

    classify() {
        local provider="$1"
        local lower
        lower=$(echo "$provider" | tr '[:upper:]' '[:lower:]')

        if echo "$lower" | grep -Eiq 'fastly|cloudflare|akamai|edgecast|cloudfront|amazon|aws|google|gcp|shopify|salesforce|azure|cdn'; then
            echo "CDN"
        else
            echo "ORIGIN?"
        fi
    }

    # -------------------------
    # main
    # -------------------------
    while IFS='|' read -r sub ips; do

        IFS=',' read -ra IP_LIST <<< "$ips"

        for ip in "${IP_LIST[@]}"; do

            local ASN_INFO PROVIDER TYPE COLOR

            ASN_INFO=$(lookup_asn "$ip")

            PROVIDER=$(echo "$ASN_INFO" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)

            TYPE=$(classify "$PROVIDER")

            if [[ "$TYPE" == "CDN" ]]; then
                COLOR="$RED"
            else
                COLOR="$GREEN"
            fi

            printf "${YELLOW}%-35s${RESET} %-15s ${COLOR}%-30s %-8s${RESET}\n" \
                "$sub" "$ip" "$PROVIDER" "$TYPE"

        done

    done < "$FILE"
}


# PATHs
export PATH=$PATH:$HOME/go/bin:$HOME/.local/bin

set -o noclobber
shopt -s checkwinsize
export LESS='-R'
