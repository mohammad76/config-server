#!/bin/bash

# Color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

SERVER_IP=$(hostname -I | awk '{print $1}')
IP_CHECK_URL="https://api.country.is/$SERVER_IP"
CHECK_IP=$(curl -s "$IP_CHECK_URL")
if echo "$CHECK_IP" | grep -q "\"error\""; then
  echo -e "${RED} Error! IP address not found ${NC}"
  exit 1
fi

COUNTRY=$(echo "$CHECK_IP" | grep -o -P '"country":"\K[^"]+' | tr -d \")
export COUNTRY

echo -e "${GREEN}Server IP: ${SERVER_IP} ${NC}"
echo -e "${GREEN}Server Country: ${COUNTRY} ${NC}"


# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "${RED}Failed to check the system OS, please contact the server author!${NC}" >&2
    exit 1
fi

os_version=""
export os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 20 ]]; then
        echo -e "${RED} Please use Ubuntu 20 or higher ${NC}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${RED} Please use Debian 11 or higher ${NC}\n" && exit 1
    fi
else
    echo -e "${RED}Your operating system is not supported by this script.${NC}\n"
    echo "Please ensure you are using one of the following supported operating systems:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    exit 1
fi


echo -e "${GREEN}set Tehran Timezone ...${NC}"
TZ=Asia/Tehran
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

echo -e "${GREEN}disable systemd resolved ...${NC}"
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved

if [ "$COUNTRY" = "IR" ]; then
 curl https://ddns.shecan.ir/update?password=1e24cbe0ff267c08
    echo -e "\nAdding Server IP to Our System, Please Wait ..."
    sleep 90
    rm /etc/resolv.conf
    cat >/etc/resolv.conf <<EOF
options timeout:1
nameserver 178.22.122.101
nameserver 185.51.200.1
EOF
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
apt update -y

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
DEBIAN_FRONTEND=noninteractive apt install -y jq iptables-persistent sqlite3 pigz default-mysql-client rkhunter supervisor btop net-tools htop fail2ban wget zip nmap git letsencrypt build-essential iftop dnsutils dsniff grepcidr iotop rsync atop software-properties-common
git config --global credential.helper store

echo -e "${GREEN}install python lib ....${NC}"
add-apt-repository ppa:deadsnakes/ppa --yes
apt update && apt install -y python3-pip

pip3 install --upgrade pip
pip3 install ibackupper

echo -e "${GREEN}install Minio mc ....${NC}"
curl https://public-chabok.s3.ir-thr-at1.arvanstorage.com/minio-mc-new \
  --create-dirs \
  -o /usr/local/bin/mc

chmod +x /usr/local/bin/mc

echo -e "${GREEN}install docker ....${NC}"
if [ $os_version = "22" ]; then
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done
elif [ $os_version = "24" ]; then
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done
elif [ $os_version = "20" ]; then
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 containerd runc; do apt-get remove $pkg; done
fi
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
if [ $os_version = "22" ]; then
    VERSION_STRING=5:26.1.4-1~ubuntu.22.04~jammy
    DEBIAN_FRONTEND=noninteractive apt install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
elif [ $os_version = "24" ]; then
    VERSION_STRING=5:26.1.4-1~ubuntu.24.04~noble
    DEBIAN_FRONTEND=noninteractive apt install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
elif [ $os_version = "20" ]; then
    VERSION_STRING=5:26.1.4-1~ubuntu.20.04~focal
    DEBIAN_FRONTEND=noninteractive apt install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo -e "${RED} not proper version, please check your ubuntu version first.${NC}"
    exit 1
fi
apt-mark hold docker-ce docker-ce-cli
apt purge postfix -y

service docker start

if [  $COUNTRY = "IR"  ]; then
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



