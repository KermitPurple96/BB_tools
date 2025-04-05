
alias jqurls='jq -r ".[].url" $FILE'
alias jqsubs='jq -r ".[].subdomain" $FILE | sort -u'
alias jqips='jq -r ".[].ip" $FILE | tr "," "\n" | sort -u'
alias jqcnames='jq -r ".[].cname" $FILE | tr "," "\n" | sort -u'
alias jqasn='jq -r ".[].asn" $FILE | tr "," "\n" | sort -u'
alias jqcidr='jq -r ".[].cidr" $FILE | tr "," "\n" | sort -u'
alias jqorg='jq -r ".[].org" $FILE | tr "," "\n" | sort -u'
alias jqstatus='jq -r ".[] | \"\(.url) => [\(.status)] \(.reason)\"" $FILE'
alias jqbanner='jq -r ".[] | select(.banner != \"\") | \"\(.url) => \(.banner)\"" $FILE'

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

function rmk
    scrub -p dod $argv[1]
    shred -zun 10 -v $argv[1]
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
