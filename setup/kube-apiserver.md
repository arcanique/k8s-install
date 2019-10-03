## 部署kube-apiserver租件
### 创建 kubernetes 证书和私钥
+ 创建证书签名请求：
```bash
cat > /usr/local/cfssl/cert/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "192.168.56.105",
    "${MASTER_IPS[0]}",
    "${MASTER_IPS[1]}",
    "${MASTER_IPS[2]}",
    "${CLUSTER_KUBERNETES_SVC_IP}",
    "10.249.0.1",
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
```
> * hosts 字段指定授权使用该证书的 IP 或域名列表，这里列出了 apiserver 节点 IP、kubernetes 服务 IP 和域名；

> * kubernetes 服务 IP 是 apiserver 自动创建的，一般是 --service-cluster-ip-range 参数指定的网段的第一个IP，后续可以通过如下命令获取：kubectl get svc kubernetes

+ 生成 kubernetes 证书和私钥：
```bash
cfssl gencert -ca=/var/k8s/cert/ca/ca.pem \
  -ca-key=/var/k8s/cert/ca/ca-key.pem \
  -config=/var/k8s/cert/ca/ca-config.json \
  -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
```

+ 创建加密配置文件
```
cat > /usr/local/k8s/yaml/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: $(head -c 32 /dev/urandom | base64)
      - identity: {}
EOF
```
+ 创建kube-apiserver使用的客户端令牌文件
```
cat <<EOF >/usr/local/k8s/cert/bootstrap-token.csv
${ENCRYPTION_KEY},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
```
+创建基础用户名/密码认证配置
```
cat <<EOF >/usr/local/k8s/cert/basic-auth.csv
admin,admin,1
readonly,readonly,2
EOF
```

+ 容器调试kube-apiserver
```bash
mkdir -p /usr/local/k8s/logs/
-v /var/k8s/cert/:/etc/k8s/cert/
```


```bash
kube-apiserver \
--enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
--anonymous-auth=false \
--experimental-encryption-provider-config=/etc/k8s/cert/kubernetes/yaml/encryption-config.yaml \
--advertise-address=0.0.0.0 \
--bind-address=0.0.0.0 \
--insecure-bind-address=127.0.0.1 \
--secure-port=6443 \
--insecure-port=0 \
--authorization-mode=Node,RBAC \
--runtime-config=api/all \
--enable-bootstrap-token-auth \
--service-cluster-ip-range=${SERVICE_CIDR} \
--service-node-port-range=${NODE_PORT_RANGE} \
--tls-cert-file=/usr/local/k8s/cert/kubernetes.pem \
--tls-private-key-file=/usr/local/k8s/cert/kubernetes-key.pem \
--client-ca-file=/usr/local/k8s/cert/ca.pem \
--kubelet-client-certificate=/usr/local/k8s/cert/kubernetes.pem \
--kubelet-client-key=/usr/local/k8s/cert/kubernetes-key.pem \
--service-account-key-file=/usr/local/k8s/cert/ca-key.pem \
--etcd-cafile=/usr/local/k8s/cert/ca.pem \
--etcd-certfile=/usr/local/k8s/cert/kubernetes.pem \
--etcd-keyfile=/usr/local/k8s/cert/kubernetes-key.pem \
--etcd-servers=${ETCD_ENDPOINTS} \
--enable-swagger-ui=true \
--allow-privileged=true \
--apiserver-count=3 \
--audit-log-maxage=30 \
--audit-log-maxbackup=3 \
--audit-log-maxsize=100 \
--audit-log-path=/usr/local/k8s/logs/api-audit.log \
--event-ttl=1h \
--v=2 \
--logtostderr=false \
--log-dir=/usr/local/k8s/logs \
```


> + --experimental-encryption-provider-config：启用加密特性；
> + --advertise-address: 将apiserver通告给群集成员的IP地址。如果为空，则使用--bind-address。如果未指定--bind-address，则将使用主机的默认接口
> + --authorization-mode=Node,RBAC： 开启 Node 和 RBAC 授权模式，拒绝未授权的请求；
> + --enable-admission-plugins：启用 ServiceAccount 和 NodeRestriction；
> + --service-account-key-file：签名 ServiceAccount Token 的公钥文件，kube-controller-manager 的 --service-account-private-key-file 指定私钥文件，两者配对使用；
> + --tls-*-file：指定 apiserver 使用的证书、私钥和 CA 文件。--client-ca-file 用于验证 client (kue-controller-manager、kube-scheduler、kubelet、kube-proxy 等)请求所带的证书；
> + --kubelet-client-certificate、--kubelet-client-key：如果指定，则使用 https 访问 kubelet APIs；需要为 kubernete 用户定义 RBAC 规则，否则无权访问 kubelet API；
> + --bind-address： 不能为 127.0.0.1，否则外界不能访问它的安全端口 6443；
> + --insecure-port=0：关闭监听非安全端口(8080)；
> + --service-cluster-ip-range： 指定 Service Cluster IP 地址段；
> + --service-node-port-range： 指定 NodePort 的端口范围；
> + --runtime-config=api/all=true： 启用所有版本的 APIs，如 autoscaling/v2alpha1；
> + --enable-bootstrap-token-auth：启用 kubelet bootstrap 的 token 认证；
> + --apiserver-count=3：指定集群运行模式，多台 kube-apiserver 会通过 leader 选举产生一个工作节点，其它节点处于阻塞状态；
> + User=k8s：使用 k8s 账户运行；
> + 替换后的 unit 文件：kube-apiserver.service

***--apiserver-count***

+ 检查api-server 状态
```
docker exec -i etcdnew etcdctl --endpoints=https://192.168.56.105:2379 --cacert /etc/k8s/cert/ca/ca.pem --cert /etc/k8s/cert/etcd/etcd.pem --key /etc/k8s/cert/etcd/etcd-key.pem get /registry/ --prefix --keys-only
```
```
kubectl get componentstatus
```
+ 授予 kubernetes 证书访问 kubelet API 的权限
在执行 kubectl exec、run、logs 等命令时，apiserver 会转发到 kubelet。这里定义 RBAC 规则，授权 apiserver 调用 kubelet API。
kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes
预定义的 ClusterRole system:kubelet-api-admin 授予访问 kubelet 所有 API 的权限：
kubectl describe clusterrole system:kubelet-api-admin
