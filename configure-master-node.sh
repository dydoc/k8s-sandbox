#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o errtrace

MASTER_IP="${1}"
POD_NETWORK_CIDR="${2}"
SERVICES_NETWORK_CIDR="${3}"
API_SERVER_DNS_RECORD="${4}"

initialize_master_node ()
{
sudo systemctl enable kubelet
sudo kubeadm config images pull
FILE="/etc/kubernetes/admin.conf"
if [ ! -f "${FILE}" ]; then
    sudo kubeadm init \
        --apiserver-advertise-address="${MASTER_IP}" \
        --pod-network-cidr="${POD_NETWORK_CIDR}" \
        --control-plane-endpoint="${API_SERVER_DNS_RECORD}" \
        --service-cidr="${SERVICES_NETWORK_CIDR}" \
        --ignore-preflight-errors=NumCPU,Mem 
else
    echo "the k8s master is already running"
fi
}

create_join_command ()
{
kubeadm token create --print-join-command | tee /vagrant/join_command.sh
chmod +x /vagrant/join_command.sh
}

configure_kubectl () 
{
mkdir -p "$HOME"/.kube
sudo cp -f /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

##For vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
}

install_network_cni ()
{
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

initialize_master_node
configure_kubectl
install_network_cni
create_join_command