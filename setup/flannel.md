
# 安装NODE 网络插件(容器化部署)
## 1、部署 flanneld 网络
> kubernetes 要求集群内各节点(包括 master 节点)能通过 Pod 网段互联互通。flannel 使用 vxlan 技术为各节点创建一个可以互通的 Pod 网络。
flaneel 第一次启动时，从 etcd 获取 Pod 网段信息，为本节点分配一个未使用的 /24 段地址，然后创建 flannedl.1（也可能是其它名称，如 flannel1 等） 接口。
flannel 将分配的 Pod 网段信息写入 /run/flannel/docker 文件，docker 后续使用这个文件中的环境变量设置 docker0 网桥。

### 创建 flannel 证书和私钥
>flannel 从 etcd 集群存取网段分配信息，而 etcd 集群启用了双向 x509 证书认证，所以需要为 flanneld 生成证书和私钥。
+ 创建证书签名请求：
```
cat > ./flanneld-csr.json <<EOF
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
```
> 该证书只会被 kubectl 当做 client 证书使用，所以 hosts 字段为空；

+ 生成证书和私钥：
```
cfssl gencert -ca=/var/k8s/cert/ca/ca.pem \
  -ca-key=/var/k8s/cert/ca/ca-key.pem \
  -config=/var/k8s/cert/ca/ca-config.json \
  -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld
```
+ 向 etcd 写入集群 Pod 网段信息
> ***注意：本步骤只需执行一次。***
```
docker exec -i etcdnew etcdctl --endpoints=https://192.168.56.105:2379 --cacert /etc/k8s/cert/ca/ca.pem --cert /etc/k8s/cert/etcd/etcd.pem --key /etc/k8s/cert/etcd/etcd-key.pem endpoint health \
  set /kubernetes/network/config '{"Network":"'173.47.0.0/16'", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'
```

### docker 调试 flannel\
docker pull quay.io/coreos/flannel:v0.11.0-amd64
```
flanneld \
-etcd-cafile=/etc/k8s/cert/ca/ca.pem \
-etcd-certfile=/etc/k8s/cert/flannel/flanneld.pem \
-etcd-keyfile=/etc/k8s/cert/flannel/flanneld-key.pem \
-etcd-endpoints=${ETCD_ENDPOINTS} \
-etcd-prefix=${FLANNEL_ETCD_PREFIX} \
-iface=${IFACE} \
-ip-masq
```
