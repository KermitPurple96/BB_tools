# =========================
# Terminal / Colors (Bash)
# =========================
export TERM=xterm  # como tenías antes

# Colores y negrita
RESET="\e[0m"
GREEN="\e[1;32m"
RED="\e[1;31m"
BLUE="\e[1;34m"
YELLOW="\e[1;33m"
PURPLE="\e[1;35m"
CYAN="\e[1;36m"

# -------------------------
# Prompt dinámico
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

    # Prompt completo, TODO en negrita y color, texto normal después
    PS1="${PURPLE}\u${RESET}${GREEN}@${RESET}${YELLOW}${IP}${RESET} ${BLUE}\w${RESET}${VENV_PART}${GIT_PART}${SYMBOL}${RESET} "
}

PROMPT_COMMAND="history -a; history -c; history -r; set_prompt"


tmuxn () {
    if [ -z "$1" ]; then
        echo "Uso: tmuxn <nombre_sesion>"
        return 1
    fi

    local session="$1"

    # Si la sesión ya existe, conectarse
    if tmux has-session -t "$session" 2>/dev/null; then
        tmux attach -t "$session"
        return 0
    fi

    # Crear nueva sesión, cargar config y theme
    tmux new-session -d -s "$session" \; \
        source-file ~/.tmux.conf \; \
        source-file ~/.tmux-themepack/powerline/default/green.tmuxtheme

    tmux attach -t "$session"
}


tmuxk () {
    if [ -z "$1" ]; then
        echo "Sesiones activas:"
        tmux list-sessions
        echo
        echo "Uso: tmuxk <nombre_sesion>"
        return 1
    fi

    tmux kill-session -t "$1" && echo "Sesión '$1' eliminada"
}


tmuxkall () {
    local current
    current=$(tmux display-message -p '#S')

    tmux list-sessions -F '#S' | grep -v "^$current$" | while read -r s; do
        tmux kill-session -t "$s"
        echo "Matada: $s"
    done
}



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


extract () {
    for archive in "$@"; do
        [ -f "$archive" ] || { echo "Archivo inválido: $archive"; continue; }
        case "$archive" in
            *.tar.bz2) tar xvjf "$archive" ;;
            *.tar.gz)  tar xvzf "$archive" ;;
            *.bz2)     bunzip2 "$archive" ;;
            *.rar)     rar x "$archive" ;;
            *.gz)      gunzip "$archive" ;;
            *.tar)     tar xvf "$archive" ;;
            *.tbz2)    tar xvjf "$archive" ;;
            *.tgz)     tar xvzf "$archive" ;;
            *.zip)     unzip "$archive" ;;
            *.Z)       uncompress "$archive" ;;
            *.7z)      7z x "$archive" ;;
            *) echo "No sé cómo extraer '$archive'" ;;
        esac
    done
}


whoxy () {
    [ $# -eq 1 ] || { echo "Uso: whoxy dominio.com"; return 1; }
    curl -s "https://api.whoxy.com/?key=$WHOXY_API_KEY&whois=$1" | jq
}

whoxyreverse () {
    [ $# -ge 2 ] || { echo "Uso: whoxyreverse <name|email|company|keyword> valor"; return 1; }
    local type="$1"; shift
    local value="${*// /+}"
    curl -s "https://api.whoxy.com/?key=$WHOXY_API_KEY&reverse=whois&$type=$value" | jq
}

whoxyhistory () {
    [ $# -eq 1 ] || { echo "Uso: whoxyhistory dominio.com"; return 1; }
    curl -s "https://api.whoxy.com/?key=$WHOXY_API_KEY&history=$1" | jq
}

jqurls()    { jq -r '.[].url' "$1"; }
jqsubs()    { jq -r '.[].subdomain' "$1" | sort -u; }
jqips()     { jq -r '.[].ip' "$1" | tr ',' '\n' | sort -u; }
jqcnames()  { jq -r '.[].cname' "$1" | tr ',' '\n' | sort -u; }
jqasn()     { jq -r '.[].asn' "$1" | tr ',' '\n' | sort -u; }
jqcidr()    { jq -r '.[].cidr' "$1" | tr ',' '\n' | sort -u; }
jqorg()     { jq -r '.[].org' "$1" | tr ',' '\n' | sort -u; }
jqbanner()  { jq -r '.[] | select(.banner!="") | "\(.url) => \(.banner)"' "$1"; }


takeover () {
    [ $# -eq 2 ] || { echo "Uso: takeover subs.txt salida.txt"; return 1; }

    local subs="$1"
    local out="$2"
    > "$out"

    while read -r sub; do
        cname=$(dig +short "$sub" CNAME)
        if [[ -n "$cname" ]]; then
            if ! whois "$cname" 2>/dev/null | grep -qi "Domain Status"; then
                echo "[!] Posible takeover: $sub → $cname" | tee -a "$out"
            fi
        fi
    done < "$subs"
}


keywordhunt () {
    [ $# -eq 1 ] || { echo "Uso: keywordhunt urls.txt"; return 1; }

    grep -Evi '\.(jpg|png|css|js|svg|woff|ttf|mp4)$' "$1" | \
    grep -Ei 'api|auth|login|token|debug|admin|password|secret|key|redirect' | \
    sort -u | tee found_keywords.txt
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




# Go / Cargo
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# WHOXY
export WHOXY_API_KEY="$(cat /home/kermit/whoxy_api 2>/dev/null)"


set -o noclobber
shopt -s checkwinsize
export LESS='-R'

. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"
