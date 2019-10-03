#!/bin/bash
worker_name=${1}
KUBE_APISERVER=${2}

echo ">>> ${worker_name}"
echo "${KUBE_APISERVER}"
if [ "${worker_name}" = "" ]; then
        exit 0
fi

if [ "${KUBE_APISERVER}" = "" ]; then
        exit 0
fi
# 创建 token
export BOOTSTRAP_TOKEN=$(kubeadm token create \
  --description kubelet-bootstrap-token \
  --groups system:bootstrappers:${worker_name} \
  --kubeconfig ~/.kube/config)

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/var/k8s/cert/ca/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kubelet-bootstrap-${worker_name}.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=kubelet-bootstrap-${worker_name}.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=kubelet-bootstrap-${worker_name}.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap-${worker_name}.kubeconfig
