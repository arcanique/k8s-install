FROM staging-k8s.gcr.io/debian-base-amd64:0.4.0

COPY kube-apiserver /usr/bin/
RUN mkdir -p /usr/local/k8s/logs/

#    kube-apiserver \
#    --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
#    --anonymous-auth=false \
#    --experimental-encryption-provider-config=/etc/k8s/cert/kubernetes/yaml/encryption-config.yaml \
#    --advertise-address=0.0.0.0 \
#    --bind-address=0.0.0.0 \
#    --insecure-bind-address=127.0.0.1 \
#    --secure-port=6443 \
#    --insecure-port=0 \
#    --authorization-mode=Node,RBAC \
#    --runtime-config=api/all \
#    --enable-bootstrap-token-auth \
#    --service-cluster-ip-range=${SERVICE_CIDR} \
#    --service-node-port-range=${NODE_PORT_RANGE} \
#    --tls-cert-file=/usr/local/k8s/cert/kubernetes.pem \
#    --tls-private-key-file=/usr/local/k8s/cert/kubernetes-key.pem \
#    --client-ca-=/usr/local/k8s/cert/ca.pem \
#    --kubelet-client-certificate=/usr/local/k8s/cert/kubernetes.pem \
#    --kubelet-client-key=/usr/local/k8s/cert/kubernetes-key.pem \
#    --service-account-key-file=/usr/local/k8s/cert/ca-key.pem \
#    --etcd-cafile=/usr/local/k8s/cert/ca.pem \
#    --etcd-certfile=/usr/local/k8s/cert/kubernetes.pem \
#    --etcd-keyfile=/usr/local/k8s/cert/kubernetes-key.pem \
#    --etcd-servers=${ETCD_ENDPOINTS} \
#    --enable-swagger-ui=true \
#    --allow-privileged=true \
#    --apiserver-count=3 \
#    --audit-log-maxage=30 \
#    --audit-log-maxbackup=3 \
#    --audit-log-maxsize=100 \
#    --audit-log-path=/usr/local/k8s/logs/api-audit.log \
#    --event-ttl=1h \
#    --v=2 \
#    --logtostderr=false \
#    --log-dir=/usr/local/k8s/logs \

ENTRYPOINT kube-apiserver \
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
--tls-cert-file=/etc/k8s/cert/kubernetes/kubernetes.pem \
--tls-private-key-file=/etc/k8s/cert/kubernetes/kubernetes-key.pem \
--client-ca-file=/etc/k8s/cert/ca/ca.pem \
--kubelet-client-certificate=/etc/k8s/cert/kubernetes/kubernetes.pem \
--kubelet-client-key=/etc/k8s/cert/kubernetes/kubernetes-key.pem \
--service-account-key-file=/etc/k8s/cert/ca/ca-key.pem \
--etcd-cafile=/etc/k8s/cert/ca/ca.pem \
--etcd-certfile=/etc/k8s/cert/kubernetes/kubernetes.pem \
--etcd-keyfile=/etc/k8s/cert/kubernetes/kubernetes-key.pem \
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

# docker run -d --net=host -v /var/k8s/cert/:/etc/k8s/cert/ -e SERVICE_CIDR="10.249.0.0/16" -e NODE_PORT_RANGE="30000-50000" -e ETCD_ENDPOINTS="https://192.168.56.105:2379" --name kuber-apiserver kuber-apiserver:v1.13.1