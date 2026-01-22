#!/usr/bin/env bash

# =========================
# classify-origins.sh
# JSON → detect CDN vs origin real
# =========================

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Uso: $0 file.json"
    exit 1
fi

# ---- colores ----
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BLUE}Subdomain\tIP\tASN/Provider\tType${RESET}"
echo "--------------------------------------------------------------"

# cache ASN lookups (más rápido)
declare -A ASN_CACHE

cat "$FILE" | jq -r '.[] | "\(.subdomain)\t\(.ip)"' | sort -u | while read sub ip; do

    # -------------------------
    # obtener ASN (con cache)
    # -------------------------
    if [[ -z "${ASN_CACHE[$ip]}" ]]; then
        ASN_INFO=$(whois -h whois.cymru.com " -v $ip" 2>/dev/null | tail -n 1)
        ASN_CACHE[$ip]="$ASN_INFO"
    fi

    ASN_INFO="${ASN_CACHE[$ip]}"
    PROVIDER=$(echo "$ASN_INFO" | awk '{$1=$2=$3=$4=""; print $0}' | xargs)

    LOWER=$(echo "$PROVIDER" | tr '[:upper:]' '[:lower:]')

    TYPE=""
    COLOR=""

    # -------------------------
    # detección CDN/SaaS
    # -------------------------
    if echo "$LOWER" | grep -Eiq 'fastly|cloudflare|akamai|edgecast|cloudfront|amazon|aws|google|gcp|shopify|salesforce|azure|cdn'; then
        TYPE="CDN"
        COLOR=$RED
    else
        TYPE="ORIGIN?"
        COLOR=$GREEN
    fi

    printf "${YELLOW}%-30s${RESET} %-15s ${COLOR}%-35s %-8s${RESET}\n" \
        "$sub" "$ip" "$PROVIDER" "$TYPE"

done
