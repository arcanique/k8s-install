## coredns 安装
https://github.com/coredns/deployment.git
##部署 dashboard 插件
```cassandraql
### 2.1、修改配置文件
* 将下载的 kubernetes-server-linux-amd64.tar.gz 解压后，再解压其中的 kubernetes-src.tar.gz 文件。
* dashboard 对应的目录是：cluster/addons/dashboard。
rm -rf /usr/local/k8s/yaml/dashboard
mkdir -p /usr/local/k8s/yaml/dashboard
\cp -a /usr/local/src/kubernetes/cluster/addons/dashboard/{dashboard-configmap.yaml,dashboard-controller.yaml,dashboard-rbac.yaml,dashboard-secret.yaml,dashboard-service.yaml} /usr/local/k8s/yaml/dashboard
source /usr/local/k8s/bin/environment.sh
sed -i "s@image:.*@image: registry.cn-hangzhou.aliyuncs.com/google_containers/kubernetes-dashboard-amd64:v1.8.3@g" /usr/local/k8s/yaml/dashboard/dashboard-controller.yaml
sed -i "/spec/a\  type: NodePort" /usr/local/k8s/yaml/dashboard/dashboard-service.yaml
sed -i "/targetPort/a\    nodePort: 38443" /usr/local/k8s/yaml/dashboard/dashboard-service.yaml

### 2.2、执行所有定义文件
kubectl delete -f /usr/local/k8s/yaml/dashboard
kubectl create -f /usr/local/k8s/yaml/dashboard

### 2.3、查看分配的 NodePort
kubectl -n kube-system get all -o wide
kubectl -n kube-system describe pod kubernetes-dashboard

* NodePort 86射到 dasrd pod 443 端口；
* dashboard 的 --authentication-mode 支持 token、basic，默认为 token。如果使用 basic，则 kube-apiserver 必须配置 '--authorization-mode=ABAC' 和 '--basic-auth-file' 参数。

### 2.4、查看 dashboard 支持的命令行参数
kubectl exec --namespace kube-system -it kubernetes-dashboard-65f7b4f486-wgc6j  -- /dashboard --help

### 2.5、访问 dashboard
* 为了集群安全，从 1.7 开始，dashboard 只允许通过 https 访问，如果使用 kube proxy 则必须监听 localhost 或 127.0.0.1，对于 NodePort 没有这个限制，但是仅建议在开发环境中使用。
* 对于不满足这些条件的登录访问，在登录成功后浏览器不跳转，始终停在登录界面。
* 参考： https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above https://github.com/kubernetes/dashboard/issues/2540
* 三种访问 dashboard 的方式
* 通过 NodePort 访问 dashboard：
* 通过 kubectl proxy 访问 dashboard：
* 通过 kube-apiserver 访问 dashboard；

### 2.6、通过 NodePort 访问 dashboard
* kubernetes-dashboard 服务暴露了 NodePort，可以使用 http://NodeIP:NodePort 地址访问 dashboard；
* 通过火狐浏览器访问：https://192.168.10.52:38443

### 2.7、通过 kubectl proxy 访问 dashboard
* 启动代理：
kubectl proxy --address='localhost' --port=8086 --accept-hosts='^*$'
* --address 必须为 localhost 或 127.0.0.1；
* 需要指定 --accept-hosts 选项，否则浏览器访问 dashboard 页面时提示 “Unauthorized”；
* 浏览器访问 URL：http://127.0.0.1:8086/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

### 2.8、通过 kube-apiserver 访问 dashboard
* 获取集群服务地址列表：
kubectl cluster-info
* 必须通过 kube-apiserver 的安全端口(https)访问 dashbaord，访问时浏览器需要使用自定义证书，否则会被 kube-apiserver 拒绝访问。
* 创建和导入自定义证书的步骤，参考：A.浏览器访问kube-apiserver安全端口
* 浏览器访问 URL：https://192.168.10.50:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/


### 2.8、创建登录 Dashboard 的 token 和 kubeconfig 配置文件
* 上面提到，Dashboard 默认只支持 token 认证，所以如果使用 KubeConfig 文件，需要在该文件中指定 token，不支持使用 client 证书认证。

* 创建登录 token
kubectl create sa dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
ADMIN_SECRET=$(kubectl get secrets -n kube-system | grep dashboard-admin | awk '{print $1}')
DASHBOARD_LOGIN_TOKEN=$(kubectl describe secret -n kube-system ${ADMIN_SECRET} | grep -E '^token' | awk '{print $2}')
echo ${DASHBOARD_LOGIN_TOKEN}

* 使用输出的 token 登录 Dashboard。

* 创建使用 token 的 KubeConfig 文件
source /usr/local/k8s/bin/environment.sh
cd /usr/local/k8s/conf
* 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/usr/local/k8s/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=dashboard.kubeconfig

* 设置客户端认证参数，使用上面创建的 Token
kubectl config set-credentials dashboard_user \
  --token=${DASHBOARD_LOGIN_TOKEN} \
  --kubeconfig=dashboard.kubeconfig

* 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=dashboard_user \
  --kubeconfig=dashboard.kubeconfig

* 设置默认上下文
kubectl config use-context default --kubeconfig=dashboard.kubeconfig
* 用生成的 dashboard.kubeconfig 登录 Dashboard。
* 由于缺少 Heapster 插件，当前 dashboard 不能展示 Pod、Nodes 的 CPU、内存等统计数据和图表；
* 参考
https://github.com/kubernetes/dashboard/wiki/Access-control https://github.com/kubernetes/dashboard/issues/2558 https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
```