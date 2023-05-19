#!/bin/bash
host_ip=$(hostname -i)

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}disable systemd resolved ...${NC}"
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved

echo -e "${GREEN}add shecan dns ...${NC}"
rm /etc/resolv.conf
cat >/etc/resolv.conf <<EOF
nameserver 178.22.122.100
nameserver 185.51.200.2
EOF

echo -e "${GREEN}updating os ...${NC}"
apt update -y && upgrade -y

echo -e "${GREEN}disable ipv6 ...${NC}"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -p

echo -e "${GREEN}install useful packages ....${NC}"
apt install -y rkhunter supervisor net-tools htop fail2ban wget zip nmap git letsencrypt build-essential iftop clamav clamav-daemon dnsutils dnsutils dsniff grepcidr software-properties-common
git config --global credential.helper store

echo -e "${GREEN}install python 3.9 ....${NC}"
add-apt-repository ppa:deadsnakes/ppa
apt update && apt install -y python3.9 python-pip
update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 3
pip3 install --upgrade pip

echo -e "${GREEN}install nodejs 14 ....${NC}"
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs
npm install -g npm@latest

echo -e "${GREEN}install ddos deflate app ....${NC}"
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip -O ddos.zip
unzip ddos.zip
./ddos-deflate-master/install.sh
rm /etc/ddos/ignore.ip.list
cp ./ignore.ip.list /etc/ddos/ignore.ip.list
echo "$host_ip/32" >>/etc/ddos/ignore.ip.list

echo -e "${GREEN}install docker ....${NC}"
apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
rm /usr/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

cat >/etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://dockerhub.ir"]
}
EOF
systemctl restart docker

