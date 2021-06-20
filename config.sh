#!/bin/bash
host_ip=$(hostname -i)

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "${RED}updating os ..."
apt update -y && upgrade -y

echo "${RED}disable ipv6 ..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -p

echo "${RED}install useful packages ...."
apt install -y rkhunter supervisor net-tools htop build-essential iftop clamav clamav-daemon dnsutils dnsutils dsniff grepcidr software-properties-common

echo "${RED}install python 3.9 ...."
add-apt-repository ppa:deadsnakes/ppa
apt update && apt install -y python3.9 python-pip
update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 3
update-alternatives --config python

echo "${RED}install nodejs 14 ...."
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt install -y nodejs
npm install -g npm@latest

echo "${RED}install ddos deflate app ...."
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip -O ddos.zip
unzip ddos.zip
./ddos-deflate-master/install.sh
rm /etc/ddos/ignore.ip.list
cp ./ignore.ip.list /etc/ddos/ignore.ip.list
echo "$host_ip/32" >>/etc/ddos/ignore.ip.list

echo "${RED}install docker ...."
apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
cat >/etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://dockerhub.ir"]
}
EOF
systemctl restart docker

echo "${RED}disable systemd resolved ..."
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved

echo "${RED}add shecan dns ..."
rm /etc/resolv.conf
cat >/etc/resolv.conf <<EOF
nameserver 178.22.122.100
nameserver 185.51.200.2
EOF
