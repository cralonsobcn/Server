#!/usr/bin/env bash

set -o xtrace
set -o pipefail
set -o nounset
set -o errexit

KUBECONFIG="/home/cristian/.kube"
KUBERNETES_VERSION="v1.33"
CRIO_VERSION="v1.33"
CALICO_VERSION="v3.30.0"

# Opens the required ports in the Controlplane
sudo firewall-cmd --permanent --zone=public --add-port=4789/udp
sudo firewall-cmd --permanent --zone=public --add-port=179/tcp  
sudo firewall-cmd --permanent --zone=public --add-port=6784/tcp
sudo firewall-cmd --permanent --zone=public --add-port=443/tcp
sudo firewall-cmd --permanent --zone=public --add-port=6443/tcp  # Kubernetes API Server
sudo firewall-cmd --permanent --zone=public --add-port=10250/tcp # Kubelet API (from control plane). Enables communication with the Metrics Server
sudo firewall-cmd --reload

# Disables swap memory
sudo swapoff -a # TODO Persist in /etc/fstab. Just comment the swap line.

# Sets SELinux to permissive mode. This is required to allow containers to access the host filesystem
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Enables IPv4 packet forwarding
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system # sysctl params required by setup, params persist across reboots

# Adds /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Adds /etc/yum.repos.d/cri-o.repo
cat <<EOF | sudo tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key
EOF

# Installs kubelet, kubeadm, kubectl and cri-o
sudo dnf install -y container-selinux
sudo yum install -y cri-o kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl daemon-reload
sudo systemctl enable --now kubelet && sudo systemctl start kubelet
sudo systemctl enable --now crio.service && sudo systemctl start crio.service

# Copies custom crio configuration. Sets the cgorup driver of crio-o
sudo cp 10-crio.conf /etc/crio/crio.conf.d/10-crio.conf 

# Initiates kubeadm and creates /var/lib/kubelet/config.yaml
sudo kubeadm init --config ./kubeadm-config.yaml                        # CRI socket is /var/run/crio/crio.sock. Modify controlplane IP
sudo mkdir -p ${KUBECONFIG}
sudo cp -i /etc/kubernetes/admin.conf ${KUBECONFIG}/config              # Copies admin conf into the users's kubeconfig
sudo chown 1000:1000 ${KUBECONFIG}/config
sudo systemctl daemon-reload && sudo  systemctl restart kubelet

# Sets up autocomplete in bash shell, bash-completion package should be installed first $ sudo dnf install bash-completion.
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -o default -F __start_kubectl k" >> ~/.bashrc
source ~/.bashrc

# Downloads and installs Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
bash ./get_helm.sh
rm ./get_helm.sh

# Adds bitnami helm chart repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Installs the Metrics Server.
kubectl apply -f ./metrics-server.yaml # Adds --kubelet-insecure-tls flag to the original deployment

# Waits 60 seconds for the controlplane to be ready and installs Calico CNI. Make sure it matches the K8s version
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/operator-crds.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml
kubectl apply -f custom-resources.yaml # curl https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/custom-resources.yaml -O





# TODO: Wait 30 seconds for the metrics server to be ready and deploy Traefik-Ingress Controller
# NOTE: Copy .kube/config into the worker node if you want kubectl access in the worker node
