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
