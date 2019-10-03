## 生成etcd 证书和私钥(需要在安装部署时考虑自动化)
+ 创建签名请求配置
```bash
cat > ${root_path}/cert/etcd/etcd-csr.json <<EOF
{
"CN": "etcd",
"hosts": [
  "127.0.0.1",
  "$192.168.56.105",
  "$192.168.56.106",
  "$192.168.56.107"
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
```
> + MASTER_IPS[] 是etcd高可用所有节点IP
> + hosts 字段指定授权使用该证书的 etcd 节点 IP 或域名列表，这里将 etcd 集群的三个节点 IP 都列在其中；
+ 生成 etcd 证书和私钥
```bash
cfssl gencert -ca=../ca/ca.pem \
    -ca-key=../ca/ca-key.pem \
    -config=../ca/ca-config.json \
    -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
```
 
 
+ 通过docker 主机网络模式 调试自制etcd镜像
> + 提前下载etcd
> + 启动调试容器
```bash
 docker run -ti --net=host -v /home/wsps/k8s-install/:/wsps --name etcd staging-k8s.gcr.io/debian-base-amd64:0.4.0
 mkdir -p /etc/k8s/cert/
 mkdir -p /var/lib/etcd/
``` 
> + etcd启动参数
 ```
etcd \
--data-dir /var/lib/etcd \
--name s1 \
--cert-file /etc/k8s/cert/etcd/etcd.pem \
--key-file /etc/k8s/cert/etcd/etcd-key.pem \
--trusted-ca-file /etc/k8s/cert/ca/ca.pem \
--peer-cert-file /etc/k8s/cert/etcd/etcd.pem \
--peer-key-file /etc/k8s/cert/etcd/etcd-key.pem \
--peer-trusted-ca-file /etc/k8s/cert/ca/ca.pem \
--listen-peer-urls https://192.168.56.105:2380 \
--initial-advertise-peer-urls https://192.168.56.105:2380 \
--listen-client-urls https://192.168.56.105:2379,http://127.0.0.1:2379 \
--advertise-client-urls https://192.168.56.105:2379 \
--initial-cluster-token k8s-etcd-cluster \
--initial-cluster s1=https://192.168.56.105:2380 \
--initial-cluster-state new \
--logger zap \
--log-level info
```
> + 验证
```bash
docker exec -i etcdnew etcdctl --endpoints=https://192.168.56.105:2379 --cacert /etc/k8s/cert/ca/ca.pem --cert /etc/k8s/cert/etcd/etcd.pem --key /etc/k8s/cert/etcd/etcd-key.pem endpoint health
```