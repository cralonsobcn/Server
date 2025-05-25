#!/usr/bin/env bash

set -o xtrace
set -o pipefail
set -o nounset
set -o errexit

KUBECONFIG="/home/cristian/.kube"

# Opens the required ports in the Controlplane
sudo firewall-cmd --permanent --zone=public --add-port=6783/tcp  # Weave
sudo firewall-cmd --permanent --zone=public --add-port=6784/tcp  # Weave
sudo firewall-cmd --permanent --zone=public --add-port=6443/tcp  # Kubernetes API Server
sudo firewall-cmd --permanent --zone=public --add-port=10250/tcp # Kubelet API (from control plane). Enables communication with the Metrics Server
sudo firewall-cmd --reload

# Disables swap memory
sudo swapoff -a # TODO Persist in /etc/fstab

# Downloads containerd CRI
wget https://github.com/containerd/containerd/releases/download/v2.1.0/containerd-2.1.0-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-2.1.0-linux-amd64.tar.gz
rm containerd-2.1.0-linux-amd64.tar.gz

# Downloads and installs runc. This is a containerd requirement as per Installation guide as it provides OCI support.
wget https://github.com/opencontainers/runc/releases/download/v1.3.0/runc.amd64
sudo mkdir -p /usr/local/sbin/runc
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
rm runc.amd64

# Installs CNI general plugins. This is a containerd and CNI requirement.
wget https://github.com/containernetworking/plugins/releases/download/v1.7.1/cni-plugins-linux-amd64-v1.7.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.7.1.tgz
rm cni-plugins-linux-amd64-v1.7.1.tgz

# Downloads and starts containerd.service 
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/containerd.service
sudo systemctl daemon-reload && systemctl enable --now containerd

# Copies containerd config.toml into the containerd folder
sudo cp containerd-config.toml /etc/containerd/config.toml
sudo systemctl restart containerd

# Sets SELinux to permissive mode. This is required to allow containers to access the host filesystem
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Installs kubelet, kubeadm and kubectl
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl daemon-reload && sudo systemctl enable --now kubelet && sudo systemctl start kubelet

# Sets up autocomplete in bash shell, bash-completion package should be installed first $ sudo dnf install bash-completion.
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -o default -F __start_kubectl k" >> ~/.bashrc
source ~/.bashrc

# Initiates kubeadm and creates /var/lib/kubelet/config.yaml
sudo kubeadm init --config ./kubeadm-config.yaml
sudo mkdir -p ${KUBECONFIG}
sudo cp -i /etc/kubernetes/admin.conf ${KUBECONFIG}/config
sudo chown 1000:1000 ${KUBECONFIG}/config

sudo systemctl daemon-reload && sudo  systemctl restart kubelet

# Installs nerdctl CLI. Run with sudo
wget https://github.com/containerd/nerdctl/releases/download/v2.1.2/nerdctl-2.1.2-linux-amd64.tar.gz
sudo mkdir -p /bin
sudo tar Cxzvvf /bin nerdctl-2.1.2-linux-amd64.tar.gz
rm nerdctl-2.1.2-linux-amd64.tar.gz 

# Downloads and installs Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
bash ./get_helm.sh
rm ./get_helm.sh

# Adds bitnami helm chart repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Waits 60 seconds for the controlplane to be ready and installs Weave CNI. Make sure it matches the K8s version
sleep 60
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.33/net.yaml

# Wait 30 seconds for the CNI to be ready and installs the Metrics Server.
sleep 30
kubectl apply -f ./metrics-server.yaml # Adds --kubelet-insecure-tls flag to the original deployment



# TODO Wait 30 seconds for the metrics server to be ready and deploy Traefik-Ingress Controller
# NOTE: Copy .kube/config into the worker node if you want kubectl access in the worker node

