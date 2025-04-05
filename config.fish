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

alias v='nvim'

function rmk
    scrub -p dod $argv[1]
    shred -zun 10 -v $argv[1]
end

alias openports='netstat -nape --inet'

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
