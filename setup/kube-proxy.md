## 部署 kube-proxy 组件
+ kube-proxy 运行在所有 worker 节点上，，它监听 apiserver 中 service 和 Endpoint 的变化情况，创建路由规则来进行服务负载均衡。
+ 本文档讲解部署 kube-proxy 的部署，使用 ipvs 模式。

### 创建 kube-proxy 证书和私钥
+ 创建证书签名请求：
```
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
```
> + CN：指定该证书的 User 为 system:kube-proxy；

> + 预定义的 RoleBinding system:node-proxier 将User system:kube-proxy 与 Role system:node-proxier 绑定，该 Role 授予了调用 kube-apiserver Proxy 相关 API 的权限；

> + 该证书只会被 kube-proxy 当做 client 证书使用，所以 hosts 字段为空；

+ 生成 kube-proxy 证书和私钥
```
cfssl gencert -ca=/var/k8s/cert/ca/ca.pem \
  -ca-key=/var/k8s/cert/ca/ca-key.pem \
  -config=/var/k8s/cert/ca/ca-config.json \
  -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

+ 创建 kube-proxy.kubeconfig 文件
> 一个集群创建一个
```
cd /usr/local/k8s/conf
* 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/var/k8s/cert/ca/ca.pem \
  --embed-certs=true \
  --server="https://192.168.56.105:6443" \
  --kubeconfig=kube-proxy.kubeconfig

* 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=/var/k8s/cert/kube-proxy/kube-proxy.pem \
  --client-key=/var/k8s/cert/kube-proxy/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
* --embed-certs=true 将 ca.pem 和 admin.pem 证书内容嵌入到生成的 kubectl-proxy.kubeconfig 文件中(不加时，写入的是证书文件路径)；

* 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

* 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```


### 创建 kube-proxy 配置文件
> 从 v1.10 开始，kube-proxy 部分参数可以配置文件中配置。可以使用 --write-config-to 选项生成该配置文件，或者参考 kubeproxyconfig 的类型定义源文件 ：https://github.com/kubernetes/kubernetes/blob/master/pkg/proxy/apis/kubeproxyconfig/types.go

+ 创建 kube-proxy config 文件模板
```
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
```
> + bindAddress: 监听地址；
> + clientConnection.kubeconfig: 连接 apiserver 的 kubeconfig 文件；
> + clusterCIDR: 必须与 kube-controller-manager 的 --cluster-cidr 选项值一致；kube-proxy 根据 --cluster-cidr 判断集群内部和外部流量，指定 --cluster-cidr 或 --masquerade-all 选项后 kube-proxy 才会对访问 Service IP 的请求做 SNAT；
> + hostnameOverride: 参数值必须与 kubelet 的值一致，否则 kube-proxy 启动后会找不到该 Node，从而不会创建任何 ipvs 规则；
> + mode: 使用 ipvs 模式；
> + 为各节点创建和分发 kube-proxy 配置文件：

### docker 调试
modprobe ip_vs_rr  
modprobe ip_vs_wrr
modprobe ip_vs_sh
```
kube-proxy \
--config=/usr/local/k8s/yaml/kube-proxy.config.yaml \
--v=2 \
--logtostderr=false \
--log-dir=/usr/local/kubernetes/logs
```
