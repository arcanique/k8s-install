#!/bin/bash
WORK_PATH=$(pwd)
export cert=/etc/k8s/cert/etcd/etcd.pem
export key=/etc/k8s/cert/etcd/etcd-key.pem
export ca=/etc/k8s/cert/ca/ca.pem
export peer_cert=/etc/k8s/cert/etcd/etcd.pem
export peer_key=/etc/k8s/cert/etcd/etcd-key.pem
export peer_ca=/etc/k8s/cert/ca/ca.pem
export HOST_IP=192.168.56.105
# etcd cluster "s1=https://192.168.56.105:2380,s2=https://192.168.56.105:2380..."
export ETCD_CLUISTER=
# master node IPs array
MASTER_IPS=()
MASTER_VIP=
# k8s security
K8S_PORT=6443
KUBE_APISERVER="https://${MASTER_VIP}:${K8S_PORT}"
# svc CIDR
SERVICE_CIDR="10.249.0.0/16"
# k8s cluster svc ip , default is the first ip of the svc CIDR
CLUSTER_KUBERNETES_SVC_IP="10.249.0.1"
CLUSTER_DNS="10.249.0.1"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
# apiserver
NODE_PORT_RANGE="30000-50000"
# ETCD_ENDPOINTS="https://192.168.10.51:2379,https://192.168.10.52:2379,https://192.168.10.53:2379"
ETCD_ENDPOINTS="https://192.168.56.105:2379"

#kube-controller-manager
## export KUBE_APISERVER="https://${MASTER_VIP}:6443"
export KUBE_APISERVER="https://192.168.56.105:6443"
# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
CLUSTER_CIDR=173.47.0.0/16

# flannel
export FLANNEL_ETCD_PREFIX="/kubernetes/network"
CLUSTER_CIDR=173.47.0.0/16
IFACE=enp0s8

#default
CLUSTER_DNS_DOMAIN="cluster.local"
CLUSTER_DNS_SVC_IP="10.249.0.2"

#kube-proxy
export KUBE_APISERVER="https://192.168.56.105:6443"
function usage() {
	echo 'this is the edgemesh-iptables usage'
	echo "${0} -m MASTER_IPS [-i HIJACK_IP] [-t HIJACK_PORT] [-b EXCLUDE_IP] [-c EXCLUDE_PORT] [-h]"
	echo ''
	echo '  -m: master ips array with ,'
	echo '  -b: Comma separated list of outbound IP for which tarffic is to be redirectd to edgemesh. The'
	echo '      wildcard character "*" can be used to configure redirection for all IPs. (default "*")'
	echo '  -c: Comma separated list of outbound Port for which tarffic is to be redirectd to edgemesh. The'
	echo '      wildcard character "*" can be used to configure redirection for all Ports. (default "*")'
	echo '  -d: Comma separated list of outbound IP range in CIDR to be excluded from redirection to edgemesh.'
	echo '      The Empty character "" can be used to configure redirection for all IPs. (default "")'
	echo '  -e: Comma separated list of outbound Port to be excluded from redirection to edgemesh. The'
	echo '      Empty character "" can be used to configure redirection for all Ports. (default "")'
	echo '  -f: for some help'
	echo '  -g: for some help'
	echo '  -h: for some help'
}

function isValidIP() {
	if isIPv4 "${1}"; then
		true
	elif isIPv6 "${1}"; then
		true
	else
		false
	fi
}

function isIPv4() {
	local ipv4matchString="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
	if [[ ${1} =~ ${ipv4matchString} ]]; then
		true
	else
		false
	fi
}

function ensure_tools() {


}

function ensure_package() {


}


function generate_cert() {
## verify the tools
if command -v kubectl > /dev/null 2>&1 ; then
	#docker build
    echo 'kubectl command found'
else
	echo 'kubectl command is no found!!'
	exit 1
fi

if command -v cfssl > /dev/null 2>&1 ; then
	#docker build
    echo 'cfssl command found'
else
	echo 'cfssl command is no found!!'
	exit 1
fi

if command -v cfssljson > /dev/null 2>&1 ; then
	#docker build
    echo 'cfssljson command found'
else
	echo 'cfssljson command is no found!!'
	exit 1
fi

if command -v cfssl-certinfo > /dev/null 2>&1 ; then
	#docker build
    echo 'cfssl-certinfo command found'
else
	echo 'cfssl-certinfo command is no found!!'
	exit 1
fi

mkdir ${WORK_PATH}/cert
# CA
mkdir ${WORK_PATH}/cert/ca
cat > ${WORK_PATH}/cert/ca/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
cat > ${WORK_PATH}/cert/ca/ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
cd ${WORK_PATH}/cert/ca/
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

echo '============================================================'
echo 'ca certificate generate successful'
echo '============================================================'

# etcd
mkdir ${WORK_PATH}/cert/etcd
cat > ${WORK_PATH}/cert/etcd/etcd-csr.json <<EOF
{
"CN": "etcd",
"hosts": [
  "127.0.0.1",
  "${MASTER_IPS[0]}",
  "${MASTER_IPS[1]}",
  "${MASTER_IPS[2]}"
],
"key": {
  "algo": "rsa",
  "size": 2048
},
"names": [
  {
    "C": "CN",
    "ST": "BeiJing",
    "L": "BeiJing",
    "O": "k8s",
    "OU": "System"
  }
]
}
EOF
cd ${WORK_PATH}/cert/etcd/
cfssl gencert -ca=${WORK_PATH}/cert/ca/ca.pem \
    -ca-key=${WORK_PATH}/cert/ca/ca-key.pem \
    -config=${WORK_PATH}/cert/ca/ca-config.json \
    -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
echo '============================================================'
echo 'etcd certificate generate successful!!'
echo '============================================================'

#kubectl
mkdir  ${WORK_PATH}/cert/admin
cat > ${WORK_PATH}/cert/admin/admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF
cd ${WORK_PATH}/cert/admin/
cfssl gencert -ca= ${WORK_PATH}/cert/ca/ca.pem \
  -ca-key= ${WORK_PATH}/cert/ca/ca-key.pem \
  -config= ${WORK_PATH}/cert/ca/ca-config.json \
  -profile=kubernetes admin-csr.json | cfssljson -bare admin

kubectl config set-cluster kubernetes \
  --certificate-authority= ${WORK_PATH}/cert/ca/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER}

kubectl config set-credentials admin \
  --client-certificate= ${WORK_PATH}/cert/admin/admin.pem \
  --client-key= ${WORK_PATH}/cert/admin/admin-key.pem \
  --embed-certs=true

kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin
kubectl config use-context kubernetes

echo '============================================================'
echo 'kubectl certificate generate successful!!'
echo '============================================================'

# kube-apiserver

mkdir -p ${WORK_PATH}/cert/kubernetes/

cat > ${WORK_PATH}/cert/kubernetes/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "${MASTER_IPS[0]}",
    "${MASTER_IPS[1]}",
    "${MASTER_IPS[2]}",
    "${CLUSTER_KUBERNETES_SVC_IP}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local",
    "kubernetes.default.svc.${CLUSTER_DNS_DOMAIN}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
cd ${WORK_PATH}/cert/kubernetes/
cfssl gencert -ca=${WORK_PATH}/cert/ca/ca.pem \
  -ca-key=${WORK_PATH}cert/ca/ca-key.pem \
  -config=${WORK_PATH}cert/ca/ca-config.json \
  -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

mkdir -p ${WORK_PATH}/cert/kubernetes/yaml
cat > ${WORK_PATH}/cert/kube-apiserver/yaml/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
mkdir -p ${WORK_PATH}/cert/kubernetes/boostrap
cat <<EOF >${WORK_PATH}/cert/kube-apiserver/boostrap/bootstrap-token.csv
${ENCRYPTION_KEY},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
cat <<EOF >${WORK_PATH}/cert/kubernetes/boostrap/basic-auth.csv
admin,admin,1
readonly,readonly,2
EOF

echo '============================================================'
echo 'kube-apiserver certificate generate successful!!'
echo '============================================================'

# kube-controller-manager
mkdir -p ${WORK_PATH}/cert/kube-controller-manager/
cat > ${WORK_PATH}/cert/kube-controller-manager/kube-controller-manager-csr.json <<EOF
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "${MASTER_IPS[0]}",
      "${MASTER_IPS[1]}",
      "${MASTER_IPS[2]}"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "system:kube-controller-manager",
        "OU": "System"
      }
    ]
}
EOF
cd mkdir -p ${WORK_PATH}/cert/kube-controller-manager
cfssl gencert -ca=${WORK_PATH}/cert/ca/ca.pem \
  -ca-key=${WORK_PATH}/cert/ca/ca-key.pem \
  -config=${WORK_PATH}/cert/ca/ca-config.json \
  -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

kubectl config set-cluster kubernetes \
  --certificate-authority==${WORK_PATH}/cert/ca/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=${WORK_PATH}/cert/kube-controller-manager/kube-controller-manager.pem \
  --client-key=${WORK_PATH}/cert/kube-controller-manager/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
echo '============================================================'
echo 'kube-controller-manager certificate generate successful!!'
echo '============================================================'

# kube-scheduler
mkdir -p ${WORK_PATH}/cert/ kube-scheduler/

cat > ${WORK_PATH}/cert/ kube-scheduler/kube-scheduler-csr.json <<EOF
{
    "CN": "system:kube-scheduler",
    "hosts": [
      "127.0.0.1",
      "${MASTER_IPS[0]}",
      "${MASTER_IPS[1]}",
      "${MASTER_IPS[2]}"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "system:kube-scheduler",
        "OU": "System"
      }
    ]
}
EOF
cd ${WORK_PATH}/cert/ kube-scheduler/
cfssl gencert -ca=${WORK_PATH}/cert/ca/ca.pem \
  -ca-key=${WORK_PATH}/cert/ca/ca-key.pem \
  -config=${WORK_PATH}/cert/ca/ca-config.json \
  -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler

kubectl config set-cluster kubernetes \
  --certificate-authority=${WORK_PATH}/cert/ca/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=./kube-scheduler.pem \
  --client-key=./kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context system:kube-scheduler \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig

echo '============================================================'
echo 'kube-scheduler certificate generate successful!!'
echo '============================================================'

# flannel
mkdir -p ${WORK_PATH}/cert/flannel/
cat > ${WORK_PATH}/cert/flannel/flanneld-csr.json <<EOF
{
  "CN": "flanneld",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
cd ${WORK_PATH}/cert/flannel/
cfssl gencert -ca=${WORK_PATH}/cert/ca/ca.pem \
  -ca-key=${WORK_PATH}/cert/ca/ca-key.pem \
  -config=${WORK_PATH}/cert/ca/ca-config.json \
  -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld

echo '============================================================'
echo 'flannel certificate generate successful!!'
echo '============================================================'

rm -rf /var/k8s/cert/
mkdir -p /var/k8s/cert/
cp -rf ${WORK_PATH}/cert/* /var/k8s/cert/
cd ${WORK_PATH}/
tar -zcvf cert.tar.gz  ${WORK_PATH}/cert/*
echo '============================================================'
echo 'certificate generate successful!!'
echo '============================================================'
}

function prepare_cni_plugin() {
sudo wget https://github.com/containernetworking/plugins/releases/download/v0.7.1/cni-plugins-amd64-v0.7.1.tgz -P /usr/local/src
mkdir -p /usr/local/k8s/bin/cni
tar zxf /usr/local/src/cni-plugins-amd64-v0.7.1.tgz -C /usr/local/k8s/bin/cni
chmod +x /usr/local/k8s/bin/cni/*
sudo mkdir -p /etc/cni/net.d
sudo bash -c "cat > /etc/cni/net.d/10-default.conf" <<EOF
{
    "name": "flannel",
    "type": "flannel",
    "delegate": {
        "bridge": "cni0",
        "isDefaultGateway": true,
        "mtu": 1400
    }
}
EOF
}
function prepare_kubelet() {
#worker_name=${1}
#KUBE_APISERVER=${2}
if command -v kubectl > /dev/null 2>&1 ; then
	#docker build
    echo 'kubectl command found'
else
	echo 'kubectl command is no found!!'
	exit 1
fi
if command -v kubeadm > /dev/null 2>&1 ; then
	#docker build
    echo 'kubeadm command found'
else
	echo 'kubeadm command is no found!!'
	exit 1
fi
echo "work name: ${worker_name}"
echo "KUBE_APISERVER : ${KUBE_APISERVER}"
if [ "${worker_name}" = "" ]; then
        exit 0
fi

if [ "${KUBE_APISERVER}" = "" ]; then
        exit 0
fi
cd ${WORK_PATH}
mkdir -p ${WORK_PATH}/kubelet/${worker_name}
cd ${WORK_PATH}/kubelet/${worker_name}
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
  --kubeconfig=kubelet-bootstrap.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=kubelet-bootstrap.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=kubelet-bootstrap.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap.kubeconfig

cat > ${WORK_PATH}/kubelet/${worker_name}/kubelet.config.json <<EOF
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "authentication": {
    "x509": {
      "clientCAFile": " ${WORK_PATH}/cert/ca/ca.pem"
    },
    "webhook": {
      "enabled": true,
      "cacheTTL": "2m0s"
    },
    "anonymous": {
      "enabled": false
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "address": "${worker_name}",
  "port": 10250,
  "readOnlyPort": 0,
  "cgroupDriver": "systemd",
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientCertificate": true,
    "RotateKubeletServerCertificate": true
  },
  "clusterDomain": "${CLUSTER_DNS_DOMAIN}",
  "clusterDNS": [${CLUSTER_DNS_SVC_IP}]
}
EOF
}

function prepare_kubeproxy(){
cat > ./kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=/var/k8s/cert/ca/ca.pem \
  -ca-key=/var/k8s/cert/ca/ca-key.pem \
  -config=/var/k8s/cert/ca/ca-config.json \
  -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
kubectl config set-cluster kubernetes \
  --certificate-authority=/var/k8s/cert/ca/ca.pem \
  --embed-certs=true \
  --server="https://192.168.56.105:6443" \
  --kubeconfig=kube-proxy.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=/var/k8s/cert/kube-proxy/kube-proxy.pem \
  --client-key=/var/k8s/cert/kube-proxy/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
# --embed-certs=true 将 ca.pem 和 admin.pem 证书内容嵌入到生成的 kubectl-proxy.kubeconfig 文件中(不加时，写入的是证书文件路径)；

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

cat > ./kube-proxy.config.yaml <<EOF
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 192.168.56.105
clientConnection:
  kubeconfig: /usr/local/k8s/conf/kube-proxy.kubeconfig
clusterCIDR: 173.47.0.0/16
healthzBindAddress: 192.168.56.105:10256
hostnameOverride: 192.168.56.105
kind: KubeProxyConfiguration
metricsBindAddress: 192.168.56.105:10249
mode: "ipvs"
EOF
}

function install_flannel(){

}

function prepare_addon() {

}

function build_images() {
if command -v docker > /dev/null 2>&1 ; then
	#docker build
    echo 'docker command found'
else
	echo 'docker command is no found!!'
	exit 1
fi

}

function main() {
while getopts ":m:t:v:b:c:h" opt; do
		case ${opt} in
			m)
				masterips=${OPTARG}
				;;
			t)
				type=${OPTARG}
				;;
			v)
				vip=${OPTARG}
				;;
			b)
				EDGEMESH_EXCLUDE_IP=${OPTARG}
				;;
			c)
				EDGEMESH_EXCLUDE_PORT=${OPTARG}
				;;
			h)
				usage
				exit 0
				;;
			?)
				echo "Invalid option: -$OPTARG" >&2
				usage
				exit 1
				;;
		esac
	done

	if [ "${masterips}" = "" ]; then
	    echo 'please specify the master node ips'
	    exit 1
	fi

    splt='/*'
	# parse parameter
	IFS=',' read -ra tmp_ip <<< "${masterips}"
	# echo "EXCLUDE_IP: ${EXCLUDE_IP}"
	for range in "${tmp_ip[@]}"; do
		r=${range%$splt}
		if isValidIP "$r"; then
			if isIPv4 "$r"; then
				MASTER_IPS=("$range")
			fi
		fi
	done

	if [ "${type}" = "" ]; then
	    echo 'please specify the mode of the k8s cluster. single or ha'
	    exit 1
	fi

	if [ "${type}" = "single" ]; then
	    MASTER_VIP=${MASTER_IPS[0]}
	elif [ "${type}" = "ha" ]; then
	    MASTER_VIP=${vip}
	else
	    echo 'mode is invalid'
	    exit 1
	fi


}

main "${@}"
