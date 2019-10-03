#!/bin/bash
# etcd
export cert=/etc/k8s/cert/etcd/etcd.pem
export key=/etc/k8s/cert/etcd/etcd-key.pem
export ca=/etc/k8s/cert/ca/ca.pem
export peer_cert=/etc/k8s/cert/etcd/etcd.pem
export peer_key=/etc/k8s/cert/etcd/etcd-key.pem
export peer_ca=/etc/k8s/cert/ca/ca.pem
export HOST_IP=192.168.56.105
export ETCD_CLUISTER="s1=https://192.168.56.105:2380"

export MASTER_IPS=(192.168.56.105)
export CLUSTER_KUBERNETES_SVC_IP="10.249.0.1"

export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
# apiserver
export SERVICE_CIDR="10.249.0.0/16"
export NODE_PORT_RANGE="30000-50000"
# exportt ETCD_ENDPOINTS="https://192.168.10.51:2379,https://192.168.10.52:2379,https://192.168.10.53:2379"
exportt ETCD_ENDPOINTS="https://192.168.56.105:2379"

#kube-controller-manager
## export KUBE_APISERVER="https://${MASTER_VIP}:6443"
export KUBE_APISERVER="https://192.168.56.105:6443"
# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
CLUSTER_CIDR=173.47.0.0/16

# flannel
export FLANNEL_ETCD_PREFIX="/kubernetes/network"
CLUSTER_CIDR=173.47.0.0/16
IFACE=enp0s8

#kubelet
${WORKER_IPS[0]}=192.168.56.105
CLUSTER_DNS_DOMAIN="cluster.local"
CLUSTER_DNS_SVC_IP=10.249.0.2

#kube-proxy
export KUBE_APISERVER="https://192.168.56.105:6443"


