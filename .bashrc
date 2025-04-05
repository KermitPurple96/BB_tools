alias sshfail='sudo grep "Failed password for invalid user" /var/log/auth.log | awk "{print \$(NF-5)}" | sort | uniq -c | sort -nr'
alias v="nvim"


jqurls() {
  jq -r '.[].url' "$1"
}

jqsubs() {
  jq -r '.[].subdomain' "$1" | sort -u
}

jqips() {
  jq -r '.[].ip' "$1" | tr ',' '\n' | sort -u
}

jqcnames() {
  jq -r '.[].cname' "$1" | tr ',' '\n' | sort -u
}

jqasn() {
  jq -r '.[].asn' "$1" | tr ',' '\n' | sort -u
}

jqcidr() {
  jq -r '.[].cidr' "$1" | tr ',' '\n' | sort -u
}

jqorg() {
  jq -r '.[].org' "$1" | tr ',' '\n' | sort -u
}

jqstatus() {
  jq -r '.[] | "\(.url) => [\(.status)] \(.reason)"' "$1"
}

jqbanner() {
  jq -r '.[] | select(.banner != "") | "\(.url) => \(.banner)"' "$1"
}

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



rmk() {
    if [ -f "$1" ]; then
        scrub -p dod "$1"
        shred -zun 10 -v "$1"
    else
        echo "Archivo no válido: $1"
    fi
}

extract() {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case "$archive" in
                *.tar.bz2)  tar xvjf "$archive" ;;
                *.tar.gz)   tar xvzf "$archive" ;;
                *.bz2)      bunzip2 "$archive" ;;
                *.rar)      rar x "$archive" ;;
                *.gz)       gunzip "$archive" ;;
                *.tar)      tar xvf "$archive" ;;
                *.tbz2)     tar xvjf "$archive" ;;
                *.tgz)      tar xvzf "$archive" ;;
                *.zip)      unzip "$archive" ;;
                *.Z)        uncompress "$archive" ;;
                *.7z)       7z x "$archive" ;;
                *)          echo "No sé cómo extraer '$archive'..." ;;
            esac
        else
            echo "'$archive' no es un archivo válido."
        fi
    done
}



# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
