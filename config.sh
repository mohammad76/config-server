#!/bin/bash
host_ip=$(hostname  -i)

echo "updating os ..."
apt update -y && upgrade -y

echo "disable ipv6 ..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -p

echo "install useful packages ...."
apt install -y rkhunter net-tools htop iftop clamav clamav-daemon dnsutils dnsutils dsniff grepcidr

echo "install ddos deflate app ...."
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip -O ddos.zip
unzip ddos.zip
./ddos-deflate-master/install.sh
rm /etc/ddos/ignore.ip.list
cp ./ignore.ip.list /etc/ddos/ignore.ip.list
echo "$host_ip/32" >> /etc/ddos/ignore.ip.list

echo "install docker ...."
apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://dockerhub.ir"]
}
EOF
systemctl restart docker

echo "disable systemd resolved ..."
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved


echo "add shecan dns ..."
rm /etc/resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver 178.22.122.100
nameserver 185.51.200.2
EOF
