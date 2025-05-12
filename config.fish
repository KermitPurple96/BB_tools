# Colors
set -g endcolor "\033[0m\e[0m"
set -g green "\e[0;32m\033[1m"
set -g red "\e[0;31m\033[1m"
set -g blue "\e[0;34m\033[1m"
set -g yellow "\e[0;33m\033[1m"
set -g purple "\e[0;35m\033[1m"
set -g turquoise "\e[0;36m\033[1m"
set -g gray "\e[0;37m\033[1m"
set -g negro "\e[0;30m\033{1m"
set -g fondonegro "\e[0;40m\033[1m"
set -g fondoverde "\e[0;42m\033[1m"
set -g fondoamarillo "\e[0;43m\033[1m"
set -g fondoazul "\e[0;44m\033[1m"
set -g fondopurple "\e[0;46m\033[1m"
set -g fondogris "\e[0;47m\033[1m"


set -U fish_user_paths /usr/local/go/bin $fish_user_paths

set -Ux fish_user_paths /home/kermit/go/bin/ $fish_user_paths
source "$HOME/.cargo/env.fish"

# =========================
# Funciones disponibles 🧠
# =========================

set_color cyan
echo -e "\n[+] Funciones útiles disponibles:\n"

set_color green
echo "jqinfo"
set_color normal
echo "  → Muestra ayuda para funciones JQ que extraen info de OneForAll (urls, IPs, subdominios...)"

set_color green
echo "whoxy"
set_color normal
echo "  → Hace un whois a la api de whoxy: whoxy <domain.com>"

set_color green
echo "whoxyinfo"
set_color normal
echo "  → Muestra cómo usar la función whoxyreverse para buscar dominios por email, nombre, empresa o keyword"

set_color green
echo "jqwhoxyinfo"
set_color normal
echo "  → Explica cómo usar los comandos jq* para extraer dominios, teléfonos, correos, empresas... desde el JSON de Whoxy reverso"

set_color green
echo "whoxyhistory"
set_color normal
echo "  → Hace un whois al historico la api de whoxy: whoxyhistory <domain.com>"

set_color green
echo "jqhistinfo"
set_color normal
echo "  → Muestra cómo usar las funciones jqhist* para analizar el historial WHOIS de un dominio"

set_color green
echo "jqhttpxinfo"
set_color normal
echo "  → Muestra como usar las funcionalidades jqhttpx* para analizar respuestas http"

echo ""

alias v='nvim'

set -Ux WHOXY_API_KEY (cat /home/kermit/whoxy_api)


function whoxy
    if test (count $argv) -ne 1
        echo "Uso: whoxy <dominio.com>"
        return 1
    end

    if not set -q WHOXY_API_KEY
        echo "No variable WHOXY_API_KEY"
        return 1
    end

    set domain $argv[1]
    curl -s "https://api.whoxy.com/?key=$WHOXY_API_KEY&whois=$domain" | jq
end



function whoxyreverse
    if test (count $argv) -lt 2
        echo "Uso: whoxyreverse <name|email|company|keyword> <valor>"
        return 1
    end

    set type $argv[1]

    # Validar tipo
    switch $type
        case name email company keyword
            # OK
        case '*'
            echo "❌ Tipo no válido: $type"
            echo "Tipos válidos: name, email, company, keyword"
            return 1
    end

    set value (string join "+" $argv[2..-1])

    if not set -q WHOXY_API_KEY
        echo "❌ No has configurado WHOXY_API_KEY"
        echo "👉 Ejecutá: set -Ux WHOXY_API_KEY (cat /home/kermit/whoxy_api)"
        return 1
    end

    set url "https://api.whoxy.com/?key=$WHOXY_API_KEY&reverse=whois&$type=$value"
    echo -e "[+] Consultando: $url\n"
    curl -s "$url" | jq
end



function whoxyinfo
    set_color cyan
    echo -e "\n[+] Uso del comando whoxyreverse (Reverse WHOIS):\n"

    set_color green
    echo "[*] whoxyreverse email <correo>"
    set_color normal
    echo "    - Busca dominios registrados con un correo. Ej:"
    echo "      whoxyreverse email admin@example.com"

    set_color green
    echo "[*] whoxyreverse name \"Nombre Completo\""
    set_color normal
    echo "    - Busca dominios por nombre de persona o entidad. Ej:"
    echo "      whoxyreverse name \"John Smith\""

    set_color green
    echo "[*] whoxyreverse company \"Nombre de Empresa\""
    set_color normal
    echo "    - Busca dominios por nombre de empresa. Ej:"
    echo "      whoxyreverse company \"Amazon Technologies Inc.\""

    set_color green
    echo "[*] whoxyreverse keyword <palabra>"
    set_color normal
    echo "    - Busca dominios por keyword en su nombre. Ej:"
    echo "      whoxyreverse keyword boozt"

    echo ""
end



function jqinfo
    set_color cyan
    echo -e "\n[+] Funciones JQ disponibles:\n"

    set_color green
    echo "[*] jqurls <archivo.json>"
    set_color normal
    echo "    - Muestra todas las URLs del archivo JSON."

    set_color green
    echo "[*] jqsubs <archivo.json>"
    set_color normal
    echo "    - Lista los subdominios únicos."

    set_color green
    echo "[*] jqips <archivo.json>"
    set_color normal
    echo "    - Lista todas las IPs únicas separadas por coma."

    set_color green
    echo "[*] jqcnames <archivo.json>"
    set_color normal
    echo "    - Lista todos los CNAMEs únicos."

    set_color green
    echo "[*] jqasn <archivo.json>"
    set_color normal
    echo "    - Muestra los ASNs relacionados."

    set_color green
    echo "[*] jqcidr <archivo.json>"
    set_color normal
    echo "    - Lista todos los rangos CIDR."

    set_color green
    echo "[*] jqorg <archivo.json>"
    set_color normal
    echo "    - Lista las organizaciones relacionadas."

    set_color green
    echo "[*] jqstatus <archivo.json>"
    set_color normal
    echo "    - Muestra los códigos de estado HTTP con su motivo."

    set_color green
    echo "[*] jqbanner <archivo.json>"
    set_color normal
    echo "    - Muestra los banners expuestos (nginx, etc)."

    echo ""
end


function extract
    for archive in $argv
        if test -f $archive
            switch $archive
                case "*.tar.bz2"
                    tar xvjf $archive
                case "*.tar.gz"
                    tar xvzf $archive
                case "*.bz2"
                    bunzip2 $archive
                case "*.rar"
                    rar x $archive
                case "*.gz"
                    gunzip $archive
                case "*.tar"
                    tar xvf $archive
                case "*.tbz2"
                    tar xvjf $archive
                case "*.tgz"
                    tar xvzf $archive
                case "*.zip"
                    unzip $archive
                case "*.Z"
                    uncompress $archive
                case "*.7z"
                    7z x $archive
                case "*"
                    echo "don't know how to extract '$archive'..."
            end
        else
            echo "'$archive' is not a valid file!"
        end
    end
end


function get
    # Verifica si se proporcionaron los argumentos necesarios
    if test (count $argv) -lt 2
        echo "Uso: get <n campo> [FS] <archivo>"
        return 1
    end

    # Guarda los argumentos en variables
    set campo $argv[1]
    set FS $argv[2]
    set archivo $argv[3]

    # Verifica si el archivo existe
    if not test -f $archivo
        echo "El archivo '$archivo' no existe."
        return 1
    end

    # Usa awk para imprimir el campo especificado con el delimitador especificado
    awk -v campo=$campo -v FS="$FS" '{print $campo}' $archivo
end

# JQ functions
function jqurls
    jq -r '.[].url' $argv[1]
end

function jqsubs
    jq -r '.[].subdomain' $argv[1] | sort -u
end

function jqips
    jq -r '.[].ip' $argv[1] | tr ',' '\n' | sort -u
end

function jqcnames
    jq -r '.[].cname' $argv[1] | tr ',' '\n' | sort -u
end

function jqasn
    jq -r '.[].asn' $argv[1] | tr ',' '\n' | sort -u
end

function jqcidr
    jq -r '.[].cidr' $argv[1] | tr ',' '\n' | sort -u
end

function jqorg
    jq -r '.[].org' $argv[1] | tr ',' '\n' | sort -u
end

function jqstatus
    jq -r '.[] | "\(.url) => [\(.status)] \(.reason)"' $argv[1]
end

function jqbanner
    jq -r '.[] | select(.banner != "") | "\(.url) => \(.banner)"' $argv[1]
end

# Aliases
alias openports='netstat -nape --inet'
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'
alias diskspace='du -S | sort -n -r | more'
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

# rmk en Fish
function rmk
    if test -f $argv[1]
        scrub -p dod $argv[1]
        shred -zun 10 -v $argv[1]
    else
        echo "Archivo no válido: $argv[1]"
    end
end


function rmk
    scrub -p dod $argv[1]
    shred -zun 10 -v $argv[1]
end

# Reboot aliases
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# Disk and space information
alias diskspace='du -S | sort -n -r | more'
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'


# extract en Fish
function extract
    for archive in $argv
        if test -f $archive
            switch $archive
                case "*.tar.bz2"
                    tar xvjf $archive
                case "*.tar.gz"
                    tar xvzf $archive
                case "*.bz2"
                    bunzip2 $archive
                case "*.rar"
                    rar x $archive
                case "*.gz"
                    gunzip $archive
                case "*.tar"
                    tar xvf $archive
                case "*.tbz2"
                    tar xvjf $archive
                case "*.tgz"
                    tar xvzf $archive
                case "*.zip"
                    unzip $archive
                case "*.Z"
                    uncompress $archive
                case "*.7z"
                    7z x $archive
                case "*"
                    echo "No sé cómo extraer '$archive'..."
            end
        else
            echo "'$archive' no es un archivo válido."
        end
    end
end


function jqwhoxyinfo
    set_color cyan
    echo -e "\n[+] Comandos para analizar el JSON de whoxyreverse:\n"

    set_color green
    echo "[*] jqdomains <archivo.json>"
    set_color normal
    echo "    - Lista todos los dominios encontrados"

    set_color green
    echo "[*] jqemails <archivo.json>"
    set_color normal
    echo "    - Extrae todos los correos del registrante"

    set_color green
    echo "[*] jqphones <archivo.json>"
    set_color normal
    echo "    - Muestra todos los teléfonos únicos"

    set_color green
    echo "[*] jqcompanies <archivo.json>"
    set_color normal
    echo "    - Organizaciones/empresas registrantes"

    set_color green
    echo "[*] jqcountries <archivo.json>"
    set_color normal
    echo "    - Países de los contactos registrantes"

    set_color green
    echo "[*] jqwhoisdates <archivo.json>"
    set_color normal
    echo "    - Fechas de creación, actualización y expiración por dominio"

    echo ""
end



function jqdomains
    jq -r '.search_result[].domain_name' $argv[1] | sort -u
end

function jqphones
    jq -r '.search_result[].registrant_contact.phone_number' $argv[1] | sort -u
end

function jqemails
    jq -r '.search_result[].registrant_contact.email_address' $argv[1] | sort -u
end

function jqcompanies
    jq -r '.search_result[].registrant_contact.company_name' $argv[1] | sort -u
end

function jqcountries
    jq -r '.search_result[].registrant_contact.country_name' $argv[1] | sort -u
end

function jqwhoisdates
    jq -r '.search_result[] | "\(.domain_name) | Created: \(.create_date) | Updated: \(.update_date) | Expires: \(.expiry_date)"' $argv[1]
end



function whoxyhistory
    if test (count $argv) -ne 1
        echo "Uso: whoxyhistory <dominio.com>"
        return 1
    end

    if not set -q WHOXY_API_KEY
        echo "❌ WHOXY_API_KEY no está configurado"
        echo "👉 Ejecutá: set -Ux WHOXY_API_KEY (cat /home/kermit/whoxy_api)"
        return 1
    end

    set domain $argv[1]
    set url "https://api.whoxy.com/?key=$WHOXY_API_KEY&history=$domain"

    echo -e "[+] Consultando historial WHOIS de: $domain\n"
    curl -s "$url" | jq
end

function jqhistdomains
    jq -r '.whois_records[].domain_name' $argv[1] | sort -u
end

function jqhistemails
    jq -r '.whois_records[].registrant_contact.email_address' $argv[1] | sort -u
end

function jqhistphones
    jq -r '.whois_records[].registrant_contact.phone_number' $argv[1] | sort -u
end

function jqhistcompanies
    jq -r '.whois_records[].registrant_contact.company_name' $argv[1] | sort -u
end

function jqhistcountries
    jq -r '.whois_records[].registrant_contact.country_name' $argv[1] | sort -u
end

function jqhistwhoisdates
    jq -r '.whois_records[] | "\(.domain_name) | Created: \(.create_date) | Updated: \(.update_date) | Expires: \(.expiry_date)"' $argv[1]
end



function jqhistinfo
    set_color cyan
    echo -e "\n[+] Comandos para analizar el JSON de historial WHOIS:\n"

    set_color green
    echo "[*] jqhistdomains <archivo.json>"
    set_color normal
    echo "    - Lista todos los dominios con historial (en general, uno)"

    set_color green
    echo "[*] jqhistemails <archivo.json>"
    set_color normal
    echo "    - Extrae todos los correos del historial"

    set_color green
    echo "[*] jqhistphones <archivo.json>"
    set_color normal
    echo "    - Muestra todos los teléfonos únicos del historial"

    set_color green
    echo "[*] jqhistcompanies <archivo.json>"
    set_color normal
    echo "    - Empresas/organizaciones del historial"

    set_color green
    echo "[*] jqhistcountries <archivo.json>"
    set_color normal
    echo "    - Países de los contactos históricos"

    set_color green
    echo "[*] jqhistwhoisdates <archivo.json>"
    set_color normal
    echo "    - Muestra las fechas WHOIS históricas por snapshot (creación, actualización, expiración)"

    echo ""
end






function jqhttpxstatus
    jq -r '. | "\(.url) [\(.status_code)] - \(.title) - \(.webserver)"' $argv[1]
end
function jqhttpxtls
    jq -r '
    select(.tls != null) |
    "\(.url)\n  TLS Version: \(.tls.tls_version)\n  Subject CN: \(.tls.subject_cn)\n  Issuer: \(.tls.issuer_cn)\n  Válido desde: \(.tls.not_before) hasta: \(.tls.not_after)\n"
    ' $argv[1]
end
function jqhttpxalt
    jq -r '
    select(.tls.subject_an != null) |
    .url, (.tls.subject_an[] | "  - " + .)
    ' $argv[1]
end
function jqhttpxfingerprint
    jq -r '
    select(.tls != null) |
    "\(.url)\n  SHA1: \(.tls.fingerprint_hash.sha1)\n  SHA256: \(.tls.fingerprint_hash.sha256)"
    ' $argv[1]
end





function takeover
    if test (count $argv) -ne 2
        echo "Uso: takeover <archivo_subdominios> <archivo_salida>"
        return 1
    end

    set subsfile $argv[1]
    set outfile $argv[2]
    set cnamefile "all_cnames.txt"

    if not test -f "$subsfile"
        echo "❌ No se encontró el archivo $subsfile"
        return 1
    end

    echo "[*] Analizando posibles takeovers en $subsfile..."
    echo -n > $outfile
    echo -n > $cnamefile

    for sub in (cat $subsfile)
        set cname (dig +short $sub CNAME)
        if test -n "$cname"
            echo "$sub => $cname" | tee -a $cnamefile

            if not whois $cname ^/dev/null | grep -iqE "Domain Status:.*(ok|active|client|server)"
                echo "[!] Posible takeover: $sub → $cname" | tee -a $outfile
            end
        end
    end

    echo "[✓] Finalizado."
    echo "→ CNAMEs en: $cnamefile"
    echo "→ Posibles takeovers en: $outfile"
end

#!/usr/bin/env fish

function verify_takeover
    if test (count $argv) -ne 1
        echo "Uso: verify_takeover <archivo_subdominios>"
        return 1
    end

    set subsfile $argv[1]

    if not test -f "$subsfile"
        echo "❌ No se encontró el archivo $subsfile"
        return 1
    end

    echo "[*] Verificando posibles takeovers con httpx..."

    cat $subsfile | httpx -title -status-code -tech-detect -tls-probe -server -json -silent | tee httpx_takeover_results.json

    echo "[✓] Resultados guardados en httpx_takeover_results.json"
    echo "Usá 'jq' para analizarlos (por ejemplo: jq '.url, .status_code, .title')"
end


function duckduckgo
    if test (count $argv) -ne 1
        echo "Uso: duckduckgo <dominio>"
        return 1
    end

    set dominio $argv[1]
    set token (curl "https://api.duckduckgo.com/?q=site%3A$dominio" -s | grep -Po '(?<=vqd=).*?(?=&)' | tail -1)

    if test -z "$token"
        echo "❌ No se pudo obtener el token vqd de DuckDuckGo"
        return 1
    end

    curl "https://duckduckgo.com/d.js?q=site%3A$dominio&vqd=$token" -s | grep -Po '(?<=u":")[^"]+'
end


function redirects
    awk -F '\\[|\\]' '{print $NF}' | sort -u
end
#!/usr/bin/env fish

function keywordhunt
    if test (count $argv) -lt 1
        echo "Uso: keywordhunt <archivo_urls>"
        return 1
    end

    set file $argv[1]

    if not test -f $file
        echo "❌ No se encontró el archivo: $file"
        return 1
    end

    echo "[*] Buscando URLs interesantes en: $file"

    set keywords api auth login logout token debug test dev stage config admin passwd password secret key reset upload backup database query email id redirect private

    set pattern ""
    for word in $keywords
        set pattern "$pattern\|$word"
    end
    set pattern (string replace -r '^\|' '' $pattern)

    grep -Evi '\.(jpg|jpeg|png|gif|svg|ico|css|js|woff|woff2|ttf|eot|mp4|webm)$' $file | \
        grep -Ei "$pattern" | sort -u | tee found_keywords.txt

    echo "[✓] Resultados guardados en: found_keywords.txt"
end

