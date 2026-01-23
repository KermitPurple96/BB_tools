#!/usr/bin/env bash
set -e

echo "[+] Updating system..."
sudo apt update

echo "[+] Installing base packages..."

sudo apt install -y \
    net-tools \
    coreutils \
    moreutils \
    libpcap-dev \
    curl \
    wget \
    git \
    build-essential \
    dnsutils \
    whois \
    traceroute \
    iputils-ping \
    jq \
    tmux \
    tree \
    unzip \
    xclip \
    neovim \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    golang-go

# -------------------------
# Python goodies
# -------------------------
echo "[+] Installing python tooling..."
pipx ensurepath



# -------------------------
# Go tools (bug bounty stack)
# -------------------------
echo "[+] Installing Go recon tools..."

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/anew@latest
go install github.com/tomnomnom/unfurl@latest
go install github.com/tomnomnom/httprobe@latest

go install github.com/ffuf/ffuf/v2@latest
go install github.com/hakluke/hakrawler@latest

go install github.com/owasp-amass/amass/v4/...@master

# -------------------------
# Wordlists básicas
# -------------------------
echo "[+] Creating tools directory..."
mkdir -p $HOME/tools
cd $HOME/tools

if [ ! -d SecLists ]; then
    git clone https://github.com/danielmiessler/SecLists.git
fi

# -------------------------
# PATH persistente
# -------------------------
if ! grep -q 'go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
fi

echo
echo "=================================="
echo "✅ Ready to hack."
echo "Open a new shell or: source ~/.bashrc"
echo "Tools installed in ~/go/bin"
echo "Wordlists: ~/tools/SecLists"
echo "=================================="


curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
snap install atuin
git clone https://github.com/jimeh/tmux-themepack.git /root/.tmux-themepack.git
wget https://raw.githubusercontent.com/KermitPurple96/i3-kitty/refs/heads/main/tmux.conf -O /root/.tmux.conf
wget https://raw.githubusercontent.com/KermitPurple96/BB_tools/refs/heads/main/bashrc -O /root/.bashrc
wget https://raw.githubusercontent.com/KermitPurple96/i3-kitty/refs/heads/main/basic.tmuxtheme -O /root/.tmux-themepack/basic.tmuxtheme
source /root/.bashrc


