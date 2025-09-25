# ==============================
# WHOIS JSON PARSER FUNCTIONS
# ==============================

# Extraer todos los emails únicos
whois_emails() {
    local file=${1:-/dev/stdin}
    jq -r '.search_result[] | [.registrant_contact.email_address, .administrative_contact.email_address, .technical_contact.email_address] | .[] | select(. != null)' "$file" | sort -u
}

# Extraer todos los teléfonos únicos
whois_phones() {
    local file=${1:-/dev/stdin}
    jq -r '.search_result[] | [.registrant_contact.phone_number, .administrative_contact.phone_number, .technical_contact.phone_number] | .[] | select(. != null)' "$file" | sort -u
}

# Teléfonos con formato internacional
whois_phones_formatted() {
    local file=${1:-/dev/stdin}
    jq -r '.search_result[] | [.registrant_contact.phone_number, .administrative_contact.phone_number, .technical_contact.phone_number] | .[] | select(. != null) | "+" + .[0:2] + " " + .[2:]' "$file"
}

# Información completa de contacto
whois_contacts() {
    local file=${1:-/dev/stdin}
    jq -r '.search_result[] | "Domain: \(.domain_name)\nRegistrant Email: \(.registrant_contact.email_address // "N/A")\nRegistrant Phone: \(.registrant_contact.phone_number // "N/A")\nAdmin Email: \(.administrative_contact.email_address // "N/A")\nAdmin Phone: \(.administrative_contact.phone_number // "N/A")\nTech Email: \(.technical_contact.email_address // "N/A")\nTech Phone: \(.technical_contact.phone_number // "N/A")\n---"' "$file"
}

# Resumen en formato CSV
whois_csv() {
    local file=${1:-/dev/stdin}
    echo "Domain,Registrant_Email,Registrant_Phone,Admin_Email,Admin_Phone,Tech_Email,Tech_Phone"
    jq -r '.search_result[] | [.domain_name, .registrant_contact.email_address, .administrative_contact.phone_number, .administrative_contact.email_address, .administrative_contact.phone_number, .technical_contact.email_address, .technical_contact.phone_number] | @csv' "$file"
}

# Tabla formateada
whois_table() {
    local file=${1:-/dev/stdin}
    echo -e "DOMAIN\tREG_EMAIL\tREG_PHONE\tCOMPANY"
    jq -r '.search_result[] | "\(.domain_name)\t\(.registrant_contact.email_address // "N/A")\t\(.registrant_contact.phone_number // "N/A")\t\(.registrant_contact.company_name // "N/A")"' "$file" | column -t -s $'\t'
}

# Buscar dominios por email específico
whois_by_email() {
    local email="$1"
    local file=${2:-/dev/stdin}
    if [[ -z "$email" ]]; then
        echo "Usage: whois_by_email <email> [file]"
        return 1
    fi
    jq -r --arg email "$email" '.search_result[] | select(.registrant_contact.email_address == $email or .administrative_contact.email_address == $email or .technical_contact.email_address == $email) | .domain_name' "$file"
}

# Buscar por país
whois_by_country() {
    local country="$1"
    local file=${2:-/dev/stdin}
    if [[ -z "$country" ]]; then
        echo "Usage: whois_by_country <country_code> [file]"
        return 1
    fi
    jq -r --arg country "$country" '.search_result[] | select(.registrant_contact.country_code == $country) | "\(.domain_name) - \(.registrant_contact.email_address)"' "$file"
}

# Direcciones físicas
whois_addresses() {
    local file=${1:-/dev/stdin}
    jq -r '.search_result[] | "Domain: \(.domain_name)\nRegistrant: \(.registrant_contact.mailing_address), \(.registrant_contact.city_name), \(.registrant_contact.country_name)\nAdmin: \(.administrative_contact.mailing_address), \(.administrative_contact.city_name), \(.administrative_contact.country_name)\n---"' "$file"
}

# Solo nombres de dominios
whois_domains() {
    local file=${1:-/dev/stdin}
    jq -r '.search_result[] | .domain_name' "$file"
}

# Estadísticas rápidas
whois_stats() {
    local file=${1:-/dev/stdin}
    echo "WHOIS Statistics:"
    echo "================"
    echo "Total domains: $(jq '.total_results' "$file")"
    echo "Unique emails: $(whois_emails "$file" | wc -l)"
    echo "Unique phones: $(whois_phones "$file" | wc -l)"
    echo "Countries: $(jq -r '.search_result[] | .registrant_contact.country_code' "$file" | sort -u | wc -l)"
    echo ""
    echo "Top countries:"
    jq -r '.search_result[] | .registrant_contact.country_code' "$file" | sort | uniq -c | sort -nr | head -5
}

# ==============================
# ALIASES ÚTILES
# ==============================

# Para el JSON de subdominios (primer caso)
alias subdomains='jq -r ".[].subdomain"'
alias active_subs='jq -r ".[] | select(.status == 200) | .subdomain"'
alias sub_ips='jq -r ".[] | \"\(.subdomain) \(.ip)\""'
alias active_sub_ips='jq -r ".[] | select(.status == 200) | \"\(.subdomain) \(.ip)\""'
alias unique_ips='jq -r ".[].ip" | sort -u'

# ==============================
# FUNCIÓN PARA BÚSQUEDA AVANZADA
# ==============================

# Búsqueda multi-criterio en WHOIS
whois_search() {
    local file pattern
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
                shift 2
                ;;
            -e|--email)
                pattern="$2"
                jq -r --arg pattern "$pattern" '.search_result[] | select(.registrant_contact.email_address // "" | test($pattern; "i")) | "\(.domain_name) - \(.registrant_contact.email_address)"' "$file"
                return
                ;;
            -p|--phone)
                pattern="$2"
                jq -r --arg pattern "$pattern" '.search_result[] | select(.registrant_contact.phone_number // "" | test($pattern)) | "\(.domain_name) - \(.registrant_contact.phone_number)"' "$file"
                return
                ;;
            -c|--company)
                pattern="$2"
                jq -r --arg pattern "$pattern" '.search_result[] | select(.registrant_contact.company_name // "" | test($pattern; "i")) | "\(.domain_name) - \(.registrant_contact.company_name)"' "$file"
                return
                ;;
            -h|--help)
                echo "Usage: whois_search -f <file> [-e email_pattern | -p phone_pattern | -c company_pattern]"
                return
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
}

# ==============================
# FUNCIÓN DE AYUDA
# ==============================

whois_help() {
    cat << EOF
WHOIS JSON Parser Functions:
============================

Basic extraction:
  whois_emails [file]         - Extract all unique emails
  whois_phones [file]         - Extract all unique phone numbers
  whois_domains [file]        - Extract domain names only
  whois_addresses [file]      - Extract physical addresses

Formatted output:
  whois_contacts [file]       - Complete contact info
  whois_table [file]          - Formatted table view
  whois_csv [file]            - CSV format
  whois_stats [file]          - Quick statistics

Search functions:
  whois_by_email <email> [file]     - Find domains by email
  whois_by_country <code> [file]    - Find domains by country code
  whois_search -f <file> -e <pattern> - Advanced search

Subdomain aliases (for first JSON type):
  subdomains                  - Extract all subdomains
  active_subs                 - Extract only active subdomains (status 200)
  sub_ips                     - Extract subdomain and IP pairs
  unique_ips                  - Extract unique IPs only

All functions support piping: cat file.json | whois_emails
EOF
}
