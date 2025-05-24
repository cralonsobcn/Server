#!/usr/bin/env bash

set -o xtrace
set -o pipefail
set -o nounset
set -o errexit

KUBECONFIG="/home/cristian/.kube"

sudo kubeadm reset
sudo yum remove -y kubelet kubeadm kubectl containerd
sudo rm -rf ${KUBECONFIG}/config /etc/cni/net.d/10-flannel.conflist /opt/cni/bin/* /etc/containerd/config.toml