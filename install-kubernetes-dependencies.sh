#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o errtrace



disable_swap () 
{
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
}

configure_sysctl ()
{
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
}


install_containerd_runtime () 
{
sudo apt-get update
sudo apt-get  install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository  -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get  update
sudo apt-get install -y containerd.io

sudo systemctl enable containerd.service
sudo systemctl daemon-reload 

sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd.service
}

install_nerdctl_cli ()
{

NERDCTL_VERSION=0.20.0 # see https://github.com/containerd/nerdctl/releases for the latest release

archType="amd64"
if test "$(uname -m)" = "aarch64"
then
    archType="arm64"
fi

wget -q "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-full-${NERDCTL_VERSION}-linux-${archType}.tar.gz" -O /tmp/nerdctl.tar.gz
sudo tar -C /usr/local/bin/ -xzf /tmp/nerdctl.tar.gz --strip-components 1 bin/nerdctl
sudo chown root "$(which nerdctl)"
sudo chmod +s "$(which nerdctl)"

mkdir -p /opt/cni/bin
tar -C /opt/cni/bin/ -xzf  /tmp/nerdctl.tar.gz --strip-components 2 libexec/cni/

}


install_required_packages ()
{
K8S_VERSION="1.24.0-00"
sudo apt-get update
sudo apt-get -y install curl apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt-get -y install vim git curl wget kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl
}


install_required_packages
disable_swap
configure_sysctl
install_containerd_runtime
install_nerdctl_cli

