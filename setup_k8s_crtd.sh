#!/bin/bash
# Script to install a single node K8s cluster on VM
#
# To use:  $ single_k8s.sh | sh
#
# N.B. The script turns off swap for the K8s control plane install but does
#      not disable swap permenantly. Please comment out any swap volumes in
#      the /etc/fstab before rebooting the VM.
#
#      This script will fail to run if the apt db is locked (wait 10 mins
#      and retry or reboot and retry).
#
#      Kubernetes single node clusters require a 4GB ram VM to run properly.


usage() {
cat <<EOF
    Usage: $0 [OPTION]...[CONTAINER Runtime]
    -h, --help          Print this usage message"
    -u, --uninstall     Uninstall k8s instalatino"
    -c, --container     Install container runtime [docker, ccio, containerd]
    -i, --install       Install k8s components kubeadm,kubectl,kubelet
    -k, --kinit         Initialize the k8s cluster
    -a, --cleaninstall  Cleanup and install k8s cluster

    CONTAINER Runtime are docker, crio, containerd

    Note: with no options specified, the script will print usage."
EOF
}

log() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color
  printf "${GREEN}# ---------------------------------------\n"
  printf "${GREEN}${1} \n"
  printf "${GREEN}# ---------------------------------------${NC}\n"
}

export __LOG=$HOME/singlek8s.log

function __new_logging() {
    # shellcheck disable=SC2094
    exec \
        3>&1 \
        4>&2 \
        5>> "$logfile" \
        > >(tee -a "$logfile") \
        2> >(tee -a "$logfile" >&2)

    # List nocolor last here so that -x doesn't bork the display.
    errcolor=$(tput setaf 1)
    infocolor=$(tput setaf 6)
    nocolor=$(tput op)
    printf '%s%s%s' "$infocolor" "$msg" "$nocolor" >&3
}


function __start_logging() {
    # Setup PS4 value which will be used by set -x command. Backup old PS4
    export OLD_PS4=$PS4
    export PS4='+($(date +"%b %d %H:%M:%S") ${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

    exec 11<&1
    exec 22<&2
    exec 1>> "$__LOG" 2>&1
    set -v
    # Enable debugging
    set -x
}

function __stop_logging() {
    # Disable debugging
    set +xv
    # Restore stdin from fd11 and stdout from fd22
    # and close fd11 and fd22
    exec 1>&11 11>&-
    exec 2>&22 22>&-
    # Restore original PS4
    export PS4=$OLD_PS4
}

__start_logging

# ---------------------------------------
# Cleanup installation
# ---------------------------------------

function cleanup_apt() {
    sudo apt-get clean
    sudo mv /var/lib/apt/lists /tmp
    sudo mkdir -p /var/lib/apt/lists/partial
    sudo apt-get clean
    sudo apt-get update
}

function cleanup_installation() {
  log "# Cleanup installation"

  log "Cleaup: Disabling swap...."
  swapoff -a
  sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

  echo "Installing necessary dependencies...."
  apt-get -y install apt-transport-https ca-certificates \
          curl gnupg-agent software-properties-common

  log "Cleanup: Setting up hostname...."
  hostnamectl set-hostname "k8s-master"
  PUBLIC_IP_ADDRESS=`hostname -I|cut -d" " -f 1`
  echo "${PUBLIC_IP_ADDRESS}  k8s-master" >> /etc/hosts
  log "Cleanup: Removing existing Docker Installation..."

  apt-get -y purge aufs-tools pigz cgroupfs-mount || true

  log "Cleanup containerd installation" 
  apt-get -y purge pigz cgroupfs-mount || true
  
  cleanup_k8s_installation
  log "Cleanup: Completed"
  }

function cleanup_k8s_installation() {
  log "Cleanup: Remove kubectl, kubelet and kubeadm."
  apt-get -y purge kubectl kubelet kubeadm kubernetes-cni \
          --allow-change-held-packages

  rm -rf /etc/kubernetes
  rm -rf $HOME/.kube/config
  rm -rf /var/lib/etcd
  rm -rf /var/lib/docker
  rm -rf /opt/containerd
  apt autoremove -y
}


# ---------------------------------------
# Setup the machine
# ---------------------------------------

function _system_setup() {
  log "System: Setup proxy"

  HOST_IP=`hostname -I  | awk '{print substr($1,1)}'`
  
  PROXY_VAL=https://x.x.x.x:443
  NO_PROXY="localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24,192.168.49.0/24,${HOST_IP}"

  echo "==> Setup proxy to user profile"
  # Add proxy information to .profile
  if [[ ! -f ~/.profile ]]
  then
    touch ~/.profile
  fi
  sed -i '/proxy/d' ~/.profile
  echo "export http_proxy=$PROXY_VAL"    >> ~/.profile
  echo "export https_proxy=\$http_proxy" >> ~/.profile
  echo "export HTTP_PROXY=\$http_proxy"  >> ~/.profile
  echo "export HTTPS_PROXY=\$http_proxy" >> ~/.profile
  echo "export no_proxy=$NO_PROXY"       >> ~/.profile
  echo "export NO_PROXY=\$no_proxy"      >> ~/.profile

  . .profile

  log "system: Setup proxy in /etc/environment"

  sudo tee /etc/environment<<EOL
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
export NO_PROXY=$NO_PROXY
export no_proxy=$NO_PROXY
EOL

  log "system: Setup proxy for CRIO"
  echo "HTTP_PROXY=$PROXY_VAL"  >> /etc/default/crio
  echo "HTTPS_PROXY=$PROXY_VAL" >> /etc/default/crio
  echo "NO_PROXY=$NO_PROXY"     >> /etc/default/crio

  log "system: Setup proxy for CRIO"
  sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf<<EOL
[Service]
Environment="HTTP_PROXY=$PROXY_VAL"
Environment="HTTPS_PROXY=$PROXY_VAL"
Environment="NO_PROXY=$NO_PROXY"
EOL

#---------Disable IPV6  ----------- 
  sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
  sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
}


# ---------------------------------------
# Install containerd using binaries
# ---------------------------------------
function _install_containerd() {
  version=1.7.6
  wget https://github.com/containerd/containerd/releases/download/v${version}/containerd-${version}-linux-amd64.tar.gz
  sudo tar Czxvf /usr/local containerd-${version}-linux-amd64.tar.gz

  #install runc
  wget https://github.com/opencontainers/runc/releases/download/v1.1.19/runc.amd64
  sudo install -m 755 runc.amd64 /usr/local/sbin/runc

  # install CNI
  cni_version=1.3.0
  sudo mkdir -p /opt/cni/bin/
  sudo wget https://github.com/containernetworking/plugins/releases/download/v${cni_version}/cni-plugins-linux-amd64-v${cni_version}.tgz
  sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v${cni_version}.tgz
  sudo systemctl restart containerd

  # Configure containerd to run in k8s
  wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
  sudo mv containerd.service /usr/lib/systemd/system/

  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd

  # Containerd configuration for Kubernetes

  sudo mkdir -p /etc/containerd/
  containerd config default | sudo tee /etc/containerd/config.toml
  sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
  sudo systemctl restart containerd

  sudo mkdir -p /etc/systemd/system/containerd.service.d/
  sudo tee /etc/systemd/system/containerd.service.d/http-proxy.conf<<EOL
[Service]
Environment="HTTP_PROXY=$PROXY_VAL"
Environment="HTTPS_PROXY=$PROXY_VAL"
Environment="NO_PROXY=$NO_PROXY"
EOL

}


# ---------------------------------------
# Install Container Runtime interface
# ---------------------------------------
function install_cri() {
    _install_containerd
    log "Container Engine: Completed Installing - containerd"
}

# ---------------------------------------
# Installing kubeadm
# ---------------------------------------
function install_k8s() {

  # Version can be obtained from
  # curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages |\
  #   grep Version | awk '{print $2}'
  K8S_PKG_VERSION=v1.25
  K8S_VERSION=1.25.12-00
  log "K8S Install: Starting installation of Version: $K8S_VERSION"

  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl
    
  curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_PKG_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  
  echo "deb [signed-by=/etc/apt/keyring/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_PKG_VERSION/deb/ /" |\
          tee /etc/apt/sources.list.d/kubernetes.list
 
  apt-get update
  apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION  --allow-change-held-packages

  apt-mark hold kubelet kubeadm kubectl
  sed -i '/ swap / s/^\(.*\)$/# \1/g' /etc/fstab
  swapoff -a
  free -h

  log "K8S Install: Enable kernel modules"
  #Enable kernel modules
  modprobe overlay
  modprobe br_netfilter

  # Add some settings to sysctl
  tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
  # Reload sysctl without restart
  sysctl --system

  log "K8S Install: Enable kubelet service"
  systemctl enable kubelet
  log "K8S Install: Complete"
}

# ---------------------------------------
# Initialize kubeadm
# ---------------------------------------
function setup_cluster() {
  log "K8S Setup: Initialize kubeadm with containerd"

  ### With Containerd ###
  rm /etc/containerd/config.toml 2>/dev/null || true
  systemctl restart containerd
  kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --cri-socket unix:///run/containerd/containerd.sock
  
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

  log "K8S Setup: Deploy Pod Network"
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
  kubectl taint node --all node-role.kubernetes.io/control-plane-

  log "K8S Setup: Completed"
}

function check_setup() {
  # Check Proxy values
  env | grep -v proxy
  cat /etc/environments
  cat /etc/systemd/system/docker.service.d/http-proxy.conf
  
  
}
main() {

   cleanup_installation
   _system_setup
   install_cri
   install_k8s
   setup_cluster
}

main $@

__stop_logging
