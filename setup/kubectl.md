## 部署 kubectl 命令行工具
> kubectl 是 kubernetes 集群的命令行管理工具，本文档介绍安装和配置它的步骤。
本文档只需要部署一次，生成的 kubeconfig 文件与机器无关。
kubectl 默认从 ~/.kube/config 文件读取 kube-apiserver 地址、证书、用户名等信息，如果没有配置，执行 kubectl 命令时可能会出错：kubectl get pods
The connection to the server localhost:8080 was refused - did you specify the right host or port?

+ 创建 admin 证书和私钥
> kubectl 与 apiserver https 安全端口通信，apiserver 对提供的证书进行认证和授权。
 
> kubectl 作为集群的管理工具，需要被授予最高权限。这里创建具有最高权限的 admin 证书。
 
> 创建证书签名请求:

```
cat > /usr/local/cfssl/cert/admin-csr.json <<EOF
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
```
> O 为 system:masters，kube-apiserver 收到该证书后将请求的 Group 设置为 system:masters；
预定义的 ClusterRoleBinding cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该 Role 授予所有 API的权限；
该证书只会被 kubectl 当做 client 证书使用，所以 hosts 字段为空；

+ 生成 admin 证书和私钥
```
cfssl gencert -ca=../ca/ca.pem \
  -ca-key=../ca/ca-key.pem \
  -config=../ca/ca-config.json \
  -profile=kubernetes admin-csr.json | cfssljson -bare admin
```

+ 设置集群参数
```
kubectl config set-cluster kubernetes \
  --certificate-authority=/var/k8s/cert/ca/ca.pem \
  --embed-certs=true \
  --server=https://192.168.56.105:6443
```

+ 设置客户端认证参数
```bash
kubectl config set-credentials admin \
  --client-certificate=/var/k8s/cert/admin/admin.pem \
  --client-key=/var/k8s/cert/admin/admin-key.pem \
  --embed-certs=true
```

+ 设置上下文参数
```
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin \
```

+ 设置默认上下文
```
kubectl config use-context kubernetes
```

> --certificate-authority：验证 kube-apiserver 证书的根证书
> --client-certificate、--client-key：刚生成的 admin 证书和私钥，连接 kube-apiserver 时使用
> --embed-certs=true：将 ca.pem 和 admin.pem 证书内容嵌入到生成的 kubectl.kubeconfig 文件中(不加时，写入的是证书文件路径)
