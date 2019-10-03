## 部署 kubelet 组件
>kublet 运行在每个 worker 节点上，接收 kube-apiserver 发送的请求，管理 Pod 容器，执行交换式命令如 exec、run、logs 等。
kublet 启动时自动向 kube-apiserver 注册节点信息，内置的 cadvisor 统计和监控节点的资源使用情况。
为确保安全，本文档只开启接收 https 请求的安全端口，对请求进行认证和授权，拒绝未授权的访问(如 apiserver、heapster)。

### 准备
ipset ipvsadm
ipvs 模块

### 创建 kubelet-bootstrap.kubeconfig 文件
[!](./img/kubelet/genKubeletconfig.sh)
拷贝好 kubeadm
sh genKubeletconfig.sh 192.168.56.105 "https://192.168.56.105:6443"

```bash
for worker_name in ${WORKER_NAMES[@]};do
    echo ">>> ${worker_name}"
    # 创建 token
    export BOOTSTRAP_TOKEN=$(kubeadm token create \
      --description kubelet-bootstrap-token \
      --groups system:bootstrappers:${worker_name} \
      --kubeconfig ~/.kube/config)

    # 设置集群参数
    kubectl config set-cluster kubernetes \
      --certificate-authority=/usr/local/k8s/cert/ca.pem \
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
done
```
> + 证书中写入 Token 而非证书，证书后续由 controller-manager 创建。

> + 查看 kubeadm 为各节点创建的 token：
kubeadm token list --kubeconfig ~/.kube/config

> + 删除
kubeadm token --kubeconfig ~/.kube/config delete tukj1l

> + 创建的 token 有效期为 1 天，超期后将不能再被使用，且会被 kube-controller-manager 的 tokencleaner 清理(如果启用该 controller 的话)；

> + kube-apiserver 接收 kubelet 的 bootstrap token 后，将请求的 user 设置为 system:bootstrap:，group 设置为 system:bootstrappers；

> + 各 token 关联的 Secret：
kubectl get secrets -n kube-system


### 创建和分发 kubelet 参数配置文件
>从 v1.10 开始，kubelet 部分参数需在配置文件中配置，kubelet --help 会有提示
+ 创建 kubelet 参数配置模板文件
```bash
cat > ./kubelet.config.json <<EOF
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "authentication": {
    "x509": {
      "clientCAFile": "/var/k8s/cert/ca/ca.pem"
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
  "address": "192.168.56.105",
  "port": 10250,
  "readOnlyPort": 0,
  "cgroupDriver": "systemd",
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientcertificate": true,
    "RotateKubeletServercertificate": true
  },
  "clusterDomain": "cluster.local",
  "clusterDNS": ["10.249.0.2"]
}
EOF
```
> + address：API 监听地址，不能为 127.0.0.1，否则 kube-apiserver、heapster 等不能调用 kubelet 的 API；
> + readOnlyPort=0：关闭只读端口(默认 10255)，等效为未指定；
> + authentication.anonymous.enabled：设置为 false，不允许匿名访问 10250 端口；
> + authentication.x509.clientCAFile：指定签名客户端证书的 CA 证书，开启 HTTP 证书认证；
> + authentication.webhook.enabled=true：开启 HTTPs bearer token 认证；
> + 对于未通过 x509 证书和 webhook 认证的请求(kube-apiserver 或其他客户端)，将被拒绝，提示 Unauthorized；
> + authroization.mode=Webhook：kubelet 使用 SubjectAccessReview API 查询 kube-apiserver 某 user、group 是否具有操作资源的权限(RBAC)；
> + featureGates.RotateKubeletClientCertificate、featureGates.RotateKubeletServerCertificate：自动 rotate 证书，证书的有效期取决于 kube-controller-manager 的 --experimental-cluster-signing-duration 参数；

需要 root 账户运行；
### 创建kubelet 运行配置目录
```
mkdir -p /var/k8s/kubelet-config/
mkdir -p  /var/k8s/kubelet-config/cert
mkdir -p /var/lib/kubelet
```
### 创建kubelet Service配置文件
```
sudo bash -c "cat > /lib/systemd/system/kubelet.service" <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=kubelet \
  --hostname-override="192.168.56.105" \
  --bootstrap-kubeconfig=/var/k8s/kubelet-config/kubelet-bootstrap.kubeconfig \
  --config=/var/k8s/kubelet-config/kubelet.config.json \
  --cert-dir=/var/k8s/kubelet-config/cert \
  --network-plugin=cni \
  --cni-conf-dir=/etc/cni/net.d \
  --cni-bin-dir=/usr/local/k8s/bin/cni \
  --fail-swap-on=false \
  --kubeconfig=/var/k8s/kubelet-config/kubelet.kubeconfig \
  --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.0 \
  --v=2 \
  --logtostderr=false \
  --log-dir=/usr/local/kubernetes/logs
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
>如果设置了 --hostname-override 选项，则 kube-proxy 也需要设置该选项，否则会出现找不到 Node 的情况；
--bootstrap-kubeconfig：指向 bootstrap kubeconfig 文件，kubelet 使用该文件中的用户名和 token 向 kube-apiserver 发送 TLS Bootstrapping 请求；
K8S approve kubelet 的 csr 请求后，在 --cert-dir 目录创建证书和私钥文件，然后写入 --kubeconfig 文件；
--feature-gates：启用 kuelet 证书轮转功能；
替换后的 unit 文件：kubelet.service

+ Bootstrap Token Auth 和授予权限
> + kublet 启动时查找配置的 --kubeletconfig 文件是否存在，如果不存在则使用 --bootstrap-kubeconfig 向 kube-apiserver 发送证书签名请求 (CSR)。
> + kube-apiserver 收到 CSR 请求后，对其中的 Token 进行认证（事先使用 kubeadm 创建的 token），认证通过后将请求的 user 设置为 system:bootstrap:，group 设置为 system:bootstrappers，这一过程称为 Bootstrap Token Auth。
> + 默认情况下，这个 user 和 group 没有创建 CSR 的权限，kubelet 启动失败
> + 解决办法是：创建一个 clusterrolebinding，将 group system:bootstrappers 和 clusterrole system:node-bootstrapper 绑定：
```
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --group=system:bootstrappers
```

### 配置CNI插件
```
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
```


### approve kubelet CSR 请求
> + kubelet 启动后使用 --bootstrap-kubeconfig 向 kube-apiserver 发送 CSR 请求，当这个 CSR 被 approve 后，kube-controller-manager 为 kubelet 创建 TLS 客户端证书、私钥和 --kubeletconfig 文件。
```cassandraql
# 查看csr 状态
kubectl get csr 
```
> + 注意：kube-controller-manager 需要配置 --cluster-signing-cert-file 和 --cluster-signing-key-file 参数，才会为 TLS Bootstrap 创建证书和私钥。
> + 三个 work 节点的 csr 均处于 pending 状态；
> + 可以手动或自动 approve CSR 请求。推荐使用自动的方式，因为从 v1.8 版本开始，可以自动轮转approve csr 后生成的证书。
+ 手动 approve CSR 请求
```
#查看 CSR 列表：
kubectl get csr
kubectl get csr|grep 'Pending' | awk 'NR>0{print $1}'| xargs kubectl certificate approve
kubectl get nodes

# 查看 Approve 结果：
kubectl get csr|awk 'NR==3{print $1}'| xargs kubectl describe csr

# Requesting User：请求 CSR 的用户，kube-apiserver 对它进行认证和授权；
# Subject：请求签名的证书信息；
# 证书的 CN 是 system:node:k8s-02m， Organization 是 system:nodes，kube-apiserver 的 Node 授权模式会授予该证书的相关权限；
```
+ 自动 approve CSR 请求
```
创建三个 ClusterRoleBinding，分别用于自动 approve client、renew client、renew server 证书：
cat > ./csr-crb.yaml <<EOF
 # Approve all CSRs for the group "system:bootstrappers"
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: auto-approve-csrs-for-group
 subjects:
 - kind: Group
   name: system:bootstrappers
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
   apiGroup: rbac.authorization.k8s.io
---
 # To let a node of the group "system:bootstrappers" renew its own credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-client-cert-renewal
 subjects:
 - kind: Group
   name: system:bootstrappers
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
   apiGroup: rbac.authorization.k8s.io
---
# A ClusterRole which instructs the CSR approver to approve a node requesting a
# serving cert matching its client cert.
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: approve-node-server-renewal-csr
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
---
 # To let a node of the group "system:nodes" renew its own server credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-server-cert-renewal
 subjects:
 - kind: Group
   name: system:nodes
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: approve-node-server-renewal-csr
   apiGroup: rbac.authorization.k8s.io
EOF
```
# 生效配置：
kubectl delete -f ./csr-crb.yaml
kubectl apply -f ./csr-crb.yamlvim 
vim 
* 查看 kublet 的情况
* 等待一段时间(1-10 分钟)，三个节点的 CSR 都被自动 approve：
kubectl get csr

* 所有节点均 ready：
kubectl get --all-namespaces -o wide nodes

* kube-controllanager 为各 node 生成了 kubeconfig 文件和公私钥：
cat /usr/local/k8s/conf/kubelet.kubeconfig
ls -l /usr/local/k8s/cert/|grep kubelet

* kubelet-server 证书会周期轮转；
