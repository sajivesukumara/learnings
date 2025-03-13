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

# Send all output to the logfile as well as stdout.
# exec 3< thisfile          # open "thisfile" for reading on file descriptor 3
# exec 4> thatfile          # open "thatfile" for writing on file descriptor 4
# exec 8<> tother           # open "tother" for reading and writing on fd 8
# exec 6>> other            # open "other" for appending on file descriptor 6
# exec 5<&0                 # copy read file descriptor 0 onto file descriptor 5
# exec 7>&4                 # copy write file descriptor 4 onto 7
# exec 3<&-                 # close the read file descriptor 3
# exec 6>&-                 # close the write file descriptor 6

# Send all output to the logfile.
# After the following we get:
# Output to 1 goes to stdout and the logfile.
# Output to 2 goes to stderr and the logfile.
# Output to 3 ONLY goes to stdout. Required when we need to print on shell only and not in file.
# Output to 4 ONLY goes to stderr.
# Output to 5 ONLY goes to the logfile.

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

  if [[ $1 = "crio" ]]; then
    apt-get -y purge cri-o cri-o-runc cri-tools
  elif [[ $1 = "docker" ]]; then
    apt-get -y purge docker-ce docker-ce-cli || true
  elif [[ $1 = "containerd" ]]; then
    apt-get -y purge pigz cgroupfs-mount || true
  else
    log "Cleanup: Container packages not cleaned up"
  fi

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

set -x

# function to find a string, if found update else add new line
# param1 : the search string or the key
# param2 : value to be replaced
# param3 : The file
# Example : option "export http_proxy" $PROXY .profile

function option() {
    name=${1//\//\\/}
    value=${2//\//\\/}
    sed -i \
        -e '/^#\?\(\s*'"${name}"'\s*=\s*\).*/{s//\1'"${value}"'/;:a;n;ba;q}' \
        -e '$a'"${name}"'='"${value}" $3
}

function _system_setup() {
  log "System: Setup proxy"

  # HOST_IP=`ifconfig | awk '/inet 15/{print substr($2,1)}'`   -- for centos
  HOST_IP=`hostname -I  | awk '{print substr($1,1)}'`
  
  export PROXY_VAL=${HTTP_PROXY:-"https://x.x.x.x:443"}
  export NO_PROXY="localhost,127.0.0.1,10.244.0.0/16,10.96.0.0/12,192.168.59.0/24,192.168.39.0/24,192.168.49.0/24,${HOST_IP}"

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

  # option "export http_proxy" $PROXY_VAL .profile
  # option "export https_proxy" $PROXY_VAL .profile
  # option "export no_proxy" $PROXY_VAL .profile
  # option "export NO_PROXY" $PROXY_VAL .profile
  
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

}

# ---------------------------------------
# Install Docker CE
# ---------------------------------------

function _install_docker_ce() {
  # Add repo and Install packages
  log "Install Docker CE "
  apt update
  apt install -y curl \
          gnupg2 software-properties-common \
          apt-transport-https ca-certificates
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt update
  apt install -y containerd.io docker-ce docker-ce-cli

  # Create required directories
  mkdir -p /etc/systemd/system/docker.service.d

  # Create daemon json config file
  sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Start and enable Services
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

}

# ---------------------------------------
# Install CRI-O
# ---------------------------------------

function _install_crio() {
  log "CRIO: Install crio "
  # Ensure you load modules
  modprobe overlay
  modprobe br_netfilter

  # Set up required sysctl params
  sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

  # Reload sysctl
  sysctl --system

  # Add Cri-o repo
  # su -

  printf "Add Cri-o repo"

  #https://github.com/cri-o/cri-o/blob/main/install.md#install-packaged-versions-of-cri-o

  OS="xUbuntu_$(lsb_release -rs)"
  CRIO_VERSION=1.23

  OPENSUSE_BASEURL=download.opensuse.org/repositories/devel
  OPENSUSE_URL=$OPENSUSE_BASEURL:/kubic:/libcontainers:/stable
  echo "deb https://$OPENSUSE_URL/$OS/ /" \
          > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
  echo "deb http://$OPENSUSE_URL:/cri-o:/$CRIO_VERSION/$OS/ /" \
          > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

  # Add Cri-o gpg keys

  printf "Add Cri-o gpg keys"

  curl -L https://$OPENSUSE_BASEURL:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | apt-key add -
  curl -L https://$OPENSUSE_URL/$OS/Release.key | apt-key add -

  # Install CRI-O
  printf "Install CRI-O"
  sudo apt update
  sudo apt install cri-o cri-o-runc cri-tools -y

  # Update CRI-O CIDR subnet
  sudo sed -i 's/10.85.0.0/192.168.0.0/g' /etc/cni/net.d/100-crio-bridge.conf

  # Start and enable Service
  systemctl daemon-reload
  systemctl enable crio --now
  systemctl restart crio
  systemctl status crio
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
# Install containerd from docker registry
# ---------------------------------------
function _install_containerd_from_registry() {
  log "Install containerd "
  # Configure persistent loading of modules
  sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

  # Load at runtime
  sudo modprobe overlay
  sudo modprobe br_netfilter

  # Ensure sysctl params are set
  sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

  # Reload configs
  sudo sysctl --system

  # Install required packages
  sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

  # Add Docker repo
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  # Install containerd
  sudo apt update
  sudo apt install -y containerd.io

  # Configure containerd and start service
  sudo su -
  mkdir -p /etc/containerd
  containerd config default>/etc/containerd/config.toml

  # restart containerd
  sudo systemctl restart containerd
  sudo systemctl enable containerd
  systemctl status  containerd

  # To use the systemd cgroup driver, set plugins.cri.systemd_cgroup = true
  # in /etc/containerd/config.toml.
}

# ---------------------------------------
# Initialize Container Runtime interface
# $1 : Container Type
#      docker
#      crio
#      containerd
# ---------------------------------------
function install_cri() {

  log "Container Engine: Installing Container Runtime - $1"
  if [[ $1 = "crio" ]]; then
    _install_crio
  elif [[ $1 = "docker" ]]; then
    _install_docker_ce
  elif [[ $1 = "containerd" ]]; then
    _install_containerd
  else
    _install_docker_ce
  fi
  log "Container Engine: Completed Installing - $1"
}

# ---------------------------------------
# Configure Docker
# ---------------------------------------
function config_docker() {
  set -e
  sudo dpkg --configure -a

  grep Proxy /etc/apt/apt.conf
  if [[ $? -eq 0 ]]; then
    echo 'Acquire::http::Proxy "$PROXY_VAL";' >> /etc/apt/apt.conf
  fi

  wget -qO- https://get.docker.com/ | sh
  cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
  sudo systemctl restart docker
}

# ---------------------------------------
# Installing kubeadm
# ---------------------------------------
function install_k8s() {

  # Version can be obtained from
  # curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages |\
  #   grep Version | awk '{print $2}'
  K8S_PKG_VERSION=1.25
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
  log "K8S Setup: Initialize kubeadm with $1"

  if [[ $1 = "docker" ]]; then
    ### With Docker CE ###
    kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --cri-socket unix:///run/cri-dockerd.sock
  elif [[ $1 = "crio" ]]; then
    ### With CRI-O###
    kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --cri-socket unix:///var/run/crio/crio.sock
  elif [[ $1 = "containerd" ]]; then
    ### With Containerd ###
    rm /etc/containerd/config.toml 2>/dev/null || true
    systemctl restart containerd
    kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --cri-socket unix:///run/containerd/containerd.sock
  else
    kubeadm init \
      --pod-network-cidr=10.244.0.0/16
  fi

  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

  log "K8S Setup: Deploy Pod Network"
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
  kubectl taint node --all node-role.kubernetes.io/control-plane-

  log "K8S Setup: Completed"
}


# ---------------------------------------
# Deprecated calls
# ---------------------------------------
function installation_old() {
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | \
          sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubeadm
  sudo swapoff -a
  if [ -z ${K8S_VERSION+x} ]
  then
      K8S_VERSION="--kubernetes-version=stable-1"
  else
      K8S_VERSION="--kubernetes-version=$K8S_VERSION"
  fi
  sudo kubeadm init $K8S_VERSION
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

main() {

   _system_setup
   case $1 in
   -c|--container)
       cri_type=$2
       install_cri $cri_type
       ;;
   -i|--install)
       cri_type=$2
       install_k8s
       ;;
   -k| --kinit)
       cri_type=$2
       setup_cluster $cri_type
       ;;
   -a)
       cri_type=$2
       cleanup_installation $cri_type
       install_cri $cri_type
       install_k8s
       setup_cluster $cri_type
       ;;
   -u|--uninstall)
       cleanup_installation
       ;;
   -s)
       _system_setup
       ;;

   *)
       usage;;
   esac
}

main $@

__stop_logging
