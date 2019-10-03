FROM staging-k8s.gcr.io/debian-base-amd64:0.4.0

COPY kube-apiserver /usr/bin/
RUN mkdir -p /usr/local/k8s/logs/

#    flanneld \
#    -etcd-cafile=/etc/k8s/cert/ca/ca.pem \
#    -etcd-certfile=/etc/k8s/cert/flannel/flanneld.pem \
#    -etcd-keyfile=/etc/k8s/cert/flannel/flanneld-key.pem \
#    -etcd-endpoints=${ETCD_ENDPOINTS} \
#    -etcd-prefix=${FLANNEL_ETCD_PREFIX} \
#    -iface=${IFACE} \
#    -ip-masq

ENTRYPOINT flanneld \
-etcd-cafile=/etc/k8s/cert/ca/ca.pem \
-etcd-certfile=/etc/k8s/cert/flannel/flanneld.pem \
-etcd-keyfile=/etc/k8s/cert/flannel/flanneld-key.pem \
-etcd-endpoints=${ETCD_ENDPOINTS} \
-etcd-prefix=${FLANNEL_ETCD_PREFIX} \
-iface=${IFACE} \
-ip-masq

# docker run -d --net=host -v /var/k8s/cert/:/etc/k8s/cert/  -e ETCD_ENDPOINTS="https://192.168.56.105:2379" -e FLANNEL_ETCD_PREFIX="/kubernetes/network" -e IFACE=enp0s8 --name flannel flannel:v