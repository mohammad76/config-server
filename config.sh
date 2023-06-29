#!/bin/bash
host_ip=$(hostname -i)

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}set Tehran Timezone ...${NC}"
TZ=Asia/Tehran
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

echo -e "${GREEN}disable systemd resolved ...${NC}"
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved

echo -e "${GREEN}add proxy dns ...${NC}"
rm /etc/resolv.conf
cat >/etc/resolv.conf <<EOF
nameserver 10.202.10.202
nameserver 10.202.10.102
EOF

echo -e "${GREEN}change server repo ...${NC}"
sed -i 's/archive.ubuntu.com/mirror.arvancloud.ir/g' /etc/apt/sources.list
sed -i 's/ir.mirror.arvancloud.ir/mirror.arvancloud.ir/g' /etc/apt/sources.list

echo -e "${GREEN}updating os ...${NC}"
apt update -y && upgrade -y

echo -e "${GREEN}disable ipv6 ...${NC}"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -p

debconf-set-selections <<EOF
iptables-persistent iptables-persistent/autosave_v4 boolean true
iptables-persistent iptables-persistent/autosave_v6 boolean true
EOF

echo -e "${GREEN}install useful packages ....${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y rkhunter supervisor net-tools htop fail2ban wget zip nmap git letsencrypt build-essential iftop dnsutils dnsutils dsniff grepcidr software-properties-common
git config --global credential.helper store

echo -e "${GREEN}install python lib ....${NC}"
add-apt-repository ppa:deadsnakes/ppa --yes
apt update && apt install -y python3-pip

pip3 install --upgrade pip
#pip3 config set global.index-url https://pypi.iranrepo.ir/simple
pip3 install ibackupper

echo -e "${GREEN}install Minio mc ....${NC}"
curl https://public-chabok.s3.ir-thr-at1.arvanstorage.com/minio-mc \
  --create-dirs \
  -o /usr/local/bin/mc

chmod +x /usr/local/bin/mc

echo -e "${GREEN}install nodejs 18 ....${NC}"
#curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
#apt install -y nodejs
#npm install -g npm@latest

echo -e "${GREEN}install docker ....${NC}"
apt-get remove docker docker-engine docker.io containerd runc
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
rm -rf /usr/share/keyrings/docker-archive-keyring.gpg
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

bash -c 'cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries" : ["https://docker.arvancloud.ir"],
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF'

docker logout
systemctl restart docker


