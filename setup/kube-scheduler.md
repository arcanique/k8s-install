## 部署高可用 kube-scheduler 集群
> + 该集群包含 3 个节点，启动后将通过竞争选举机制产生一个 leader 节点，其它节点为阻塞状态。当 leader 节点不可用后，剩余节点将再次进行选举产生新的 leader 节点，从而保证服务的可用性。
为保证通信安全，本文档先生成 x509 证书和私钥，kube-scheduler 在如下两种情况下使用该证书：
与 kube-apiserver 的安全端口通信;在安全端口(https，10251) 输出 prometheus 格式的 metrics；

### 创建 kube-scheduler 证书和私钥
+ 创建证书签名请求：

```
cat > ./kube-scheduler-csr.json <<EOF
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
```
> + hosts 列表包含所有 kube-scheduler 节点 IP；

> + CN 为 system:kube-scheduler、O 为 system:kube-scheduler，kubernetes 内置的 ClusterRoleBindings system:kube-scheduler 将赋予 kube-scheduler 工作所需的权限。

+ 生成证书和私钥：
```
cfssl gencert -ca=/var/k8s/cert/ca/ca.pem \
  -ca-key=/var/k8s/cert/ca/ca-key.pem \
  -config=/var/k8s/cert/ca/ca-config.json \
  -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler
```
+ 创建 kube-scheduler.kubeconfig 文件
kubeconfig 文件包含访问 apiserver 的所有信息，如 apiserver 地址、CA 证书和自身使用的证书
```
kubectl config set-cluster kubernetes \
  --certificate-authority=/var/k8s/cert/ca/ca.pem \
  --embed-certs=true \
  --server=//192.168.56.105:6443 \
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
```
### docker 调试kube-scheduler
```
kube-scheduler \
--address=127.0.0.1 \
--master=${KUBE_APISERVER} \
--kubeconfig=/usr/local/k8s/conf/kube-scheduler.kubeconfig \
--leader-elect=true \
--v=2 \
--logtostderr=false \
--log-dir=/usr/local/kubernetes/logs
```

> + --address：在 127.0.0.1:10251 端口接收 http /metrics 请求；kube-scheduler 目前还不支持接收 https 请求；
> + --kubeconfig：指定 kubeconfig 文件路径，kube-scheduler 使用它连接和验证 kube-apiserver；
> + --leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；
> + 完整 unit 见 kube-scheduler.service

+ 检查是否安装成功
kubectl get componentstatus
