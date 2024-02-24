#!/bin/bash
read -p "Enter Server IP: " NODE_IP
read -p "is an Iran Server?[y/n] " IR_SERVER

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

if [ $IR_SERVER = "y" ]; then
    echo -e "${GREEN}add proxy dns ...${NC}"
    rm /etc/resolv.conf
cat >/etc/resolv.conf <<EOF
options timeout:1
nameserver 178.22.122.100
nameserver 185.51.200.2
EOF


echo -e "${GREEN}change server repo ...${NC}"
sed -i 's/archive.ubuntu.com/mirror.arvancloud.ir/g' /etc/apt/sources.list
sed -i 's/ir.mirror.arvancloud.ir/mirror.arvancloud.ir/g' /etc/apt/sources.list
sed -i 's/us.mirror.arvancloud.ir/mirror.arvancloud.ir/g' /etc/apt/sources.list

else
    echo -e "${GREEN}add base dns ...${NC}"
    rm /etc/resolv.conf
cat >/etc/resolv.conf <<EOF
options timeout:1
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
fi

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
DEBIAN_FRONTEND=noninteractive apt install -y rkhunter supervisor net-tools htop fail2ban wget zip nmap git letsencrypt build-essential iftop dnsutils dsniff grepcidr iotop rsync atop software-properties-common
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

#echo -e "${GREEN}install nodejs 18 ....${NC}"
#curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
#apt install -y nodejs
#npm install -g npm@latest

echo -e "${GREEN}install docker ....${NC}"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
#sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

UBUNTU_VERSION=$(lsb_release -c)
UBUNTU_VERSION=${UBUNTU_VERSION#*:}
if [ $UBUNTU_VERSION = "focal" ]; then

    echo "install focal"
    VERSION_STRING=5:25.0.3-1~ubuntu.20.04~focal
    sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

elif [ $UBUNTU_VERSION = "jammy" ]; then
    echo "install jammy"
    VERSION_STRING=5:25.0.3-1~ubuntu.22.04~jammy
    sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

else

    echo "not proper version, please check your ubuntu version first."

fi
apt-mark hold docker-ce docker-ce-cli

#sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#chmod +x /usr/local/bin/docker-compose
#rm /usr/bin/docker-compose
# ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

if [ $IR_SERVER = "y" ]; then
bash -c 'cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries" : ["https://docker.chabokan.net"],
  "registry-mirrors": ["https://docker.chabokan.net"]
}
EOF'
docker logout
systemctl restart docker
fi

apt purge postfix -y

echo -e "${GREEN}server configed successfully. enjoy your server :)${NC}"



