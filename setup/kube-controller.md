## 部署高可用 kube-controller-manager 集群
> + 本文档介绍部署高可用 kube-controller-manager 集群的步骤。
> + 该集群包含 3 个节点，启动后将通过竞争选举机制产生一个 leader 节点，其它节点为阻塞状态。当 leader 节点不可用后，剩余节点将再次进行选举产生新的 leader 节点，从而保证服务的可用性。
> + 为保证通信安全，本文档先生成 x509 证书和私钥，kube-controller-manager 在如下两种情况下使用该证书：
> + 与 kube-apiserver 的安全端口通信时;在安全端口(https，10252) 输出 prometheus 格式的 metrics；
### 创建 kube-controller-manager 证书和私钥
+ 创建证书签名请求
```bash
cat > /usr/local/cfssl/cert/kube-controller-manager-csr.json <<EOF
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
```
> + hosts 列表包含所有 kube-controller-manager 节点 IP；

> + CN 为 system:kube-controller-manager、O 为 system:kube-controller-manager，kubernetes 内置的 ClusterRoleBindings system:kube-controller-manager 赋予 kube-controller-manager 工作所需的权限。

+ 生成 kube-controller-manager 证书和私钥：
```bash
cfssl gencert -ca=/var/k8s/cert/ca/ca.pem \
  -ca-key=/var/k8s/cert/ca/ca-key.pem \
  -config=/var/k8s/cert/ca/ca-config.json \
  -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
```

### 创建 kube-controller-manager.kubeconfig 文件
+ kubeconfig 文件包含访问 apiserver 的所有信息，如 apiserver 地址、CA 证书和自身使用的证书；
```
cd /usr/local/k8s/conf
kubectl config set-cluster kubernetes \
  --certificate-authority=/var/k8s/cert/ca/ca.pem \
  --embed-certs=true \
  --server=https://192.168.56.105:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=/var/k8s/cert/kube-controller-manager/kube-controller-manager.pem \
  --client-key=/var/k8s/cert/kube-controller-manager/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
```
> + kube-controller-manager 的权限
> + ClusteRole: system:kube-controller-manager 的权限很小，只能创建 secret、serviceaccount 等资源对象，各 controller 的权限分散到 ClusterRole system:controller:XXX 中。
> + 需要在 kube-controller-manager 的启动参数中添加 --use-service-account-credentials=true 参数，这样 main controller 会为各 controller 创建对应的 ServiceAccount XXX-controller。
> + 内置的 ClusterRoleBinding system:controller:XXX 将赋予各 XXX-controller ServiceAccount 对应的 ClusterRole system:controller:XXX 权限。

### docker 调试kube-controller-manager
```
kube-controller-manager \
--address=127.0.0.1 \
--master=${KUBE_APISERVER} \
--kubeconfig=/usr/local/k8s/conf/kube-controller-manager.kubeconfig \
--allocate-node-cidrs=true \
--service-cluster-ip-range=${SERVICE_CIDR} \
--cluster-cidr=${CLUSTER_CIDR} \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/usr/local/k8s/cert/ca.pem \
--cluster-signing-key-file=/usr/local/k8s/cert/ca-key.pem \
--experimental-cluster-signing-duration=8760h \
--leader-elect=true \
--feature-gates=RotateKubeletServercertificate=true \
--controllers=*,bootstrapsigner,tokencleaner \
--horizontal-pod-autoscaler-use-rest-clients=true \
--horizontal-pod-autoscaler-sync-period=10s \
--tls-cert-file=/usr/local/k8s/cert/kube-controller-manager.pem \
--tls-private-key-file=/usr/local/k8s/cert/kube-controller-manager-key.pem \
--service-account-private-key-file=/usr/local/k8s/cert/ca-key.pem \
--root-ca-file=/usr/local/k8s/cert/ca.pem \
--use-service-account-credentials=true \
--v=2 \
--logtostderr=false \
--log-dir=/usr/local/kubernetes/logs
```
> + --kubeconfig：指定 kubeconfig 文件路径，kube-controller-manager 使用它连接和验证 kube-apiserver；
> + --cluster-signing-*-file：签名 TLS Bootstrap 创建的证书；
> + --experimental-cluster-signing-duration：指定 TLS Bootstrap 证书的有效期；
> + --service-cluster-ip-range ：指定 Service Cluster IP 网段，必须和 kube-apiserver 中的同名参数一致；
> + --leader-elerue：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；
> + --feature-gates=RotateKubeletServercertificate=true：开启 kublet server 证书的自动更新特性；
> + --controllers=*,bootstrapsigner,tokencleaner：启用的控制器列表，tokencleaner 用于自动清理过期的 Bootstrap token；
> + --horizontal-pod-autoscaler-*：custom metrics 相关参数，支持 autoscaling/v2alpha1；
> + --tls-cert-file、--tls-private-key-file：使用 https 输出 metrics 时使用的 Server 证书和秘钥；# --root-ca-file：放置到容器 ServiceAccount 中的 CA 证书，用来对 kube-apiserver 的证书进行校验；
> + --service-account-private-key-file：签名 ServiceAccount 中 Token 的私钥文件，必须和 kube-apiserver 的 --service-account-key-file 指定的公钥文件配对使用；
> + --use-service-account-credentials=true:
> + User=k8s：使用 k8s 账户运行；
> + kube-controller-manager 不对请求 https metrics 的 Client 证书进行校验，故不需要指定 --tls-ca-file 参数，而且该参数已被淘汰。

+ kubectl get componentstatus 检查kube-controller
