# Terminal / Colors (Bash)
# =========================
export TERM=xterm

# Colores y negrita
RESET="\e[0m"
GREEN="\e[1;32m"
RED="\e[1;31m"
BLUE="\e[1;34m"
YELLOW="\e[1;33m"
PURPLE="\e[1;35m"
CYAN="\e[1;36m"

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
# Prompt dinámico
# -------------------------
set_prompt() {
    IP=$(get_ip)
    [ -z "$IP" ] && IP="noip"

    if [ "$EUID" -eq 0 ]; then
        SYMBOL="${RED}#"
    else
        SYMBOL="${PURPLE}\$"
    fi

    if [ -n "$VIRTUAL_ENV" ]; then
        VENV_NAME=$(basename "$VIRTUAL_ENV")
        VENV_PART=" ${CYAN}(${VENV_NAME})${RESET}"
    else
        VENV_PART=""
    fi

    BRANCH=$(git_branch)
    if [ -n "$BRANCH" ]; then
        GIT_PART=" ${GREEN}(${BRANCH})${RESET}"
    else
        GIT_PART=""
    fi

    PS1="${PURPLE}\u${RESET}${GREEN}@${RESET}${YELLOW}${IP}${RESET} ${BLUE}\w${RESET}${VENV_PART}${GIT_PART}${SYMBOL}${RESET} "
}
PROMPT_COMMAND="history -a; history -c; history -r; set_prompt"

#precmd_functions+=(set_prompt)
# -------------------------
# Historial
# -------------------------
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# -------------------------
# Bash completion
# -------------------------
[ -f /etc/bash_completion ] && . /etc/bash_completion

# -------------------------
# Aliases
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
# FUNCIONES PERSONALIZADAS
# =========================

# -------------------------
# TMUX
# -------------------------
tmuxn () {
    if [ -z "$1" ]; then
        echo "Uso: tmuxn <nombre_sesion>"
        return 1
    fi

    local session="$1"

    if tmux has-session -t "$session" 2>/dev/null; then
        tmux attach -t "$session"
        return 0
    fi

    tmux new-session -d -s "$session" \; \
        source-file ~/.tmux.conf \; \
        source-file ~/.tmux-themepack/basic.tmuxtheme

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


# =========================
# subs_lepus
# Input: subdomain|ip,ip,ip → solo subdominios
# =========================
domains_lepus() {
    [ $# -eq 1 ] || { echo "Uso: subs_lepus archivo.txt"; return 1; }
    [ -f "$1" ] || { echo "Archivo no encontrado: $1"; return 1; }

    cut -d'|' -f1 "$1" | sort -u
}

# =========================
# subs_ofa
# Input: JSON array → solo subdominios
# =========================
domains_ofa() {
    [ $# -eq 1 ] || { echo "Uso: subs_ofa archivo.json"; return 1; }
    [ -f "$1" ] || { echo "Archivo no encontrado: $1"; return 1; }

    jq -r '.[].subdomain' "$1" | sort -u
}

# =========================
# alive_lepus
# Input: subdomain|ip,ip,ip
# =========================
alive_lepus() {
    [ $# -ge 1 ] || { echo "Uso: alive_lepus archivo.txt [--threads 20]"; return 1; }

    local FILE="$1"
    local THREADS="${3:-15}"

    [ -f "$FILE" ] || { echo "Archivo no encontrado: $FILE"; return 1; }

    local OUT="alive_lepus_results.txt"

    cut -d'|' -f1 "$FILE" | sort -u | httpx -silent -threads "$THREADS" -status-code -title -tech-detect -o "$OUT"

    echo ""
    echo -e "\e[1;32m[✓] Resultados guardados en $OUT\e[0m"
    echo "Total vivos: $(wc -l < "$OUT")"
}

# =========================
# alive_ofa
# Input: JSON array con campo "subdomain"
# =========================
alive_ofa() {
    [ $# -ge 1 ] || { echo "Uso: alive_ofa archivo.json [--threads 20]"; return 1; }

    local FILE="$1"
    local THREADS="${3:-15}"

    [ -f "$FILE" ] || { echo "Archivo no encontrado: $FILE"; return 1; }

    local OUT="alive_ofa_results.txt"

    jq -r '.[].subdomain' "$FILE" | sort -u | httpx -silent -threads "$THREADS" -status-code -title -tech-detect -o "$OUT"

    echo ""
    echo -e "\e[1;32m[✓] Resultados guardados en $OUT\e[0m"
    echo "Total vivos: $(wc -l < "$OUT")"
}



# =========================
# origins
# Dominio único → resolve IPs → CDN vs ORIGIN
# Uso: origins dominio.com
# =========================
origins() {
    [ $# -eq 1 ] || { echo "Uso: origins dominio.com"; return 1; }

    local DOMAIN="$1"

    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local RESET="\033[0m"

    # resolver IPs del dominio
    local IPS
    IPS=$(dig +short "$DOMAIN" A | grep -E '^[0-9]')

    if [ -z "$IPS" ]; then
        echo -e "${RED}[✗] No se pudo resolver: $DOMAIN${RESET}"
        return 1
    fi

    echo -e "${BLUE}Subdomain\t\t\tIP\t\tProvider\t\t\tType${RESET}"
    echo "---------------------------------------------------------------------------------------"

    while read -r ip; do

        local ASN_INFO PROVIDER LOWER TYPE COLOR

        ASN_INFO=$(whois -h whois.cymru.com " -v $ip" 2>/dev/null | tail -n 1)
        PROVIDER=$(echo "$ASN_INFO" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)
        LOWER=$(echo "$PROVIDER" | tr '[:upper:]' '[:lower:]')

        if echo "$LOWER" | grep -Eiq 'fastly|cloudflare|akamai|edgecast|cloudfront|amazon|aws|google|gcp|shopify|salesforce|azure|cdn'; then
            TYPE="CDN"
            COLOR="$RED"
        else
            TYPE="ORIGIN?"
            COLOR="$GREEN"
        fi

        printf "${YELLOW}%-35s${RESET} %-15s ${COLOR}%-30s %-8s${RESET}\n" \
            "$DOMAIN" "$ip" "$PROVIDER" "$TYPE"

    done <<< "$IPS"
}

# -------------------------
# RECON / OSINT
# -------------------------
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

    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local RESET="\033[0m"

    echo -e "${BLUE}Subdomain\tIP\tASN/Provider\tType${RESET}"
    echo "--------------------------------------------------------------"

    declare -A ASN_CACHE

    jq -r '.[] | "\(.subdomain)\t\(.ip)"' "$FILE" | sort -u | while read -r sub ip; do

        if [[ -z "${ASN_CACHE[$ip]}" ]]; then
            ASN_CACHE[$ip]=$(whois -h whois.cymru.com " -v $ip" 2>/dev/null | tail -n 1)
        fi

        local ASN_INFO="${ASN_CACHE[$ip]}"
        local PROVIDER
        PROVIDER=$(echo "$ASN_INFO" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)

        local LOWER
        LOWER=$(echo "$PROVIDER" | tr '[:upper:]' '[:lower:]')

        local TYPE COLOR

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

duckduckgo () {
    [ $# -eq 1 ] || { echo "Uso: duckduckgo dominio.com"; return 1; }

    token=$(curl -s "https://api.duckduckgo.com/?q=site:$1" | grep -Po '(?<=vqd=).*?(?=&)' | tail -1)
    [ -n "$token" ] || { echo "No token vqd"; return 1; }

    curl -s "https://duckduckgo.com/d.js?q=site:$1&vqd=$token" | grep -Po '(?<=u":")[^"]+'
}

# -------------------------
# WHOXY
# -------------------------
whoxy () {
    [ $# -eq 1 ] || { echo "Uso: whoxy <dominio.com>"; return 1; }
    [ -n "$WHOXY_API_KEY" ] || { echo "No variable WHOXY_API_KEY"; return 1; }

    curl -s "https://api.whoxy.com/?key=$WHOXY_API_KEY&whois=$1" | jq
}

whoxyreverse () {
    [ $# -ge 2 ] || { echo "Uso: whoxyreverse <name|email|company|keyword> <valor>"; return 1; }

    local type="$1"; shift
    case "$type" in
        name|email|company|keyword) ;;
        *) echo "❌ Tipo no válido: $type"; return 1 ;;
    esac

    [ -n "$WHOXY_API_KEY" ] || { echo "❌ WHOXY_API_KEY no configurado"; return 1; }

    local value="${*// /+}"
    local url="https://api.whoxy.com/?key=$WHOXY_API_KEY&reverse=whois&$type=$value"

    echo -e "[+] Consultando: $url\n"
    curl -s "$url" | jq
}

whoxyhistory () {
    [ $# -eq 1 ] || { echo "Uso: whoxyhistory <dominio.com>"; return 1; }
    [ -n "$WHOXY_API_KEY" ] || { echo "❌ WHOXY_API_KEY no configurado"; return 1; }

    curl -s "https://api.whoxy.com/?key=$WHOXY_API_KEY&history=$1" | jq
}

# -------------------------
# JQ HELPERS - General
# -------------------------
jqurls()    { jq -r '.[].url' "$1"; }
jqsubs()    { jq -r '.[].subdomain' "$1" | sort -u; }
jqips()     { jq -r '.[].ip' "$1" | tr ',' '\n' | sort -u; }
jqcnames()  { jq -r '.[].cname' "$1" | tr ',' '\n' | sort -u; }
jqasn()     { jq -r '.[].asn' "$1" | tr ',' '\n' | sort -u; }
jqcidr()    { jq -r '.[].cidr' "$1" | tr ',' '\n' | sort -u; }
jqorg()     { jq -r '.[].org' "$1" | tr ',' '\n' | sort -u; }
jqstatus()  { jq -r '.[] | "\(.url) => [\(.status)] \(.reason)"' "$1"; }
jqbanner()  { jq -r '.[] | select(.banner!="") | "\(.url) => \(.banner)"' "$1"; }

# -------------------------
# JQ HELPERS - HTTPX
# -------------------------
jqhttpxstatus()      { jq -r '. | "\(.url) [\(.status_code)] - \(.title) - \(.webserver)"' "$1"; }
jqhttpxtls()         { jq -r 'select(.tls!=null) | "\(.url)\n TLS: \(.tls.tls_version)\n Subject: \(.tls.subject_cn)\n Issuer: \(.tls.issuer_cn)\n"' "$1"; }
jqhttpxalt()         { jq -r 'select(.tls.subject_an!=null) | .url, (.tls.subject_an[] | "  - " + .)' "$1"; }
jqhttpxfingerprint() { jq -r 'select(.tls!=null) | "\(.url)\n SHA1: \(.tls.fingerprint_hash.sha1)\n SHA256: \(.tls.fingerprint_hash.sha256)"' "$1"; }

# -------------------------
# JQ HELPERS - WHOXY Reverse
# -------------------------
jqdomains()    { jq -r '.search_result[].domain_name' "$1" | sort -u; }
jqemails()     { jq -r '.search_result[].registrant_contact.email_address' "$1" | sort -u; }
jqphones()     { jq -r '.search_result[].registrant_contact.phone_number' "$1" | sort -u; }
jqcompanies()  { jq -r '.search_result[].registrant_contact.company_name' "$1" | sort -u; }
jqcountries()  { jq -r '.search_result[].registrant_contact.country_name' "$1" | sort -u; }
jqwhoisdates() { jq -r '.search_result[] | "\(.domain_name) | Created: \(.create_date) | Updated: \(.update_date) | Expires: \(.expiry_date)"' "$1"; }

# -------------------------
# JQ HELPERS - WHOXY History
# -------------------------
jqhistdomains()    { jq -r '.whois_records[].domain_name' "$1" | sort -u; }
jqhistemails()     { jq -r '.whois_records[].registrant_contact.email_address' "$1" | sort -u; }
jqhistphones()     { jq -r '.whois_records[].registrant_contact.phone_number' "$1" | sort -u; }
jqhistcompanies()  { jq -r '.whois_records[].registrant_contact.company_name' "$1" | sort -u; }
jqhistcountries()  { jq -r '.whois_records[].registrant_contact.country_name' "$1" | sort -u; }
jqhistwhoisdates() { jq -r '.whois_records[] | "\(.domain_name) | Created: \(.create_date) | Updated: \(.update_date) | Expires: \(.expiry_date)"' "$1"; }

# -------------------------
# UTILIDADES
# -------------------------
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

rmk () {
    scrub -p dod "$1"
    shred -zun 10 -v "$1"
}

# =========================
# FUNCIÓN HELP
# =========================
myhelp () {
    echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║                    🛠️  FUNCIONES PERSONALIZADAS                   ║\033[0m"
    echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[1;33m📦 TMUX\033[0m"
    echo "  tmuxn <sesion>          Crear/conectar sesión tmux"
    echo "  tmuxk <sesion>          Matar sesión tmux específica"
    echo "  tmuxkall                Matar todas las sesiones excepto la actual"
    echo ""
    echo -e "\033[1;33m🔍 RECON / OSINT\033[0m"
    echo "  origins_ofa <file.json>     Detectar CDN vs Origin (formato OFA JSON)"
    echo "  origins_lepus <file.csv>    Detectar CDN vs Origin (formato Lepus CSV)"
    echo "  takeover <subs> <out>       Buscar posibles subdomain takeovers"
    echo "  keywordhunt <urls.txt>      Buscar URLs con keywords sensibles"
    echo "  duckduckgo <dominio>        Scraping de resultados DuckDuckGo"
    echo ""
    echo -e "\033[1;33m🌐 WHOXY API\033[0m"
    echo "  whoxy <dominio>                         WHOIS lookup"
    echo "  whoxyreverse <type> <valor>             Reverse WHOIS (name|email|company|keyword)"
    echo "  whoxyhistory <dominio>                  Historial WHOIS"
    echo ""
    echo -e "\033[1;33m📄 JQ HELPERS - General\033[0m"
    echo "  jqurls <file>           Extraer URLs"
    echo "  jqsubs <file>           Extraer subdominios únicos"
    echo "  jqips <file>            Extraer IPs únicas"
    echo "  jqcnames <file>         Extraer CNAMEs únicos"
    echo "  jqasn <file>            Extraer ASNs únicos"
    echo "  jqcidr <file>           Extraer CIDRs únicos"
    echo "  jqorg <file>            Extraer organizaciones únicas"
    echo "  jqstatus <file>         Mostrar URL + status + reason"
    echo "  jqbanner <file>         Mostrar banners no vacíos"
    echo ""
    echo -e "\033[1;33m📄 JQ HELPERS - HTTPX\033[0m"
    echo "  jqhttpxstatus <file>        URL + status + title + webserver"
    echo "  jqhttpxtls <file>           Info TLS (versión, subject, issuer)"
    echo "  jqhttpxalt <file>           Subject Alternative Names"
    echo "  jqhttpxfingerprint <file>   Fingerprints SHA1/SHA256"
    echo ""
    echo -e "\033[1;33m📄 JQ HELPERS - WHOXY Reverse\033[0m"
    echo "  jqdomains <file>        Dominios del resultado"
    echo "  jqemails <file>         Emails del registrante"
    echo "  jqphones <file>         Teléfonos del registrante"
    echo "  jqcompanies <file>      Empresas del registrante"
    echo "  jqcountries <file>      Países del registrante"
    echo "  jqwhoisdates <file>     Fechas WHOIS (create/update/expire)"
    echo ""
    echo -e "\033[1;33m📄 JQ HELPERS - WHOXY History\033[0m"
    echo "  jqhist*                 Mismas funciones pero para historial WHOIS"
    echo ""
    echo -e "\033[1;33m🔧 UTILIDADES\033[0m"
    echo "  extract <archivo>       Extraer cualquier archivo comprimido"
    echo "  rmk <archivo>           Borrado seguro (scrub + shred)"
    echo ""
    echo -e "\033[1;33m⌨️  ALIASES\033[0m"
    echo "  ll, la, l               Variantes de ls"
    echo "  ..  / ...               Subir directorios"
    echo "  c                       clear"
    echo "  ports                   ss -tulpen"
    echo "  myip                    ip -4 a"
    echo ""
}

# -------------------------
# PATH / ENV
# -------------------------
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

export WHOXY_API_KEY="$(cat /home/kermit/whoxy_api 2>/dev/null)"

# -------------------------
# OPCIONES
# -------------------------
set -o noclobber
shopt -s checkwinsize
export LESS='-R'
