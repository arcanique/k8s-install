FROM staging-k8s.gcr.io/debian-base-amd64:0.4.0

COPY kube-controller-manager /usr/bin
RUN mkdir -p /usr/local/kubernetes/logs

#    kube-controller-manager \
#    --address=127.0.0.1 \
#    --master=${KUBE_APISERVER} \
#    --kubeconfig=/usr/local/k8s/conf/kube-controller-manager.kubeconfig \
#    --allocate-node-cidrs=true \
#    --service-cluster-ip-range=${SERVICE_CIDR} \
#    --cluster-cidr=${CLUSTER_CIDR} \
#    --cluster-name=kubernetes \
#    --cluster-signing-cert-file=/usr/local/k8s/cert/ca.pem \
#    --cluster-signing-key-file=/usr/local/k8s/cert/ca-key.pem \
#    --experimental-cluster-signing-duration=8760h \
#    --leader-elect=true \
#    --feature-gates=RotateKubeletServercertificate=true \
#    --controllers=*,bootstrapsigner,tokencleaner \
#    --horizontal-pod-autoscaler-use-rest-clients=true \
#    --horizontal-pod-autoscaler-sync-period=10s \
#    --tls-cert-file=/usr/local/k8s/cert/kube-controller-manager.pem \
#    --tls-private-key-file=/usr/local/k8s/cert/kube-controller-manager-key.pem \
#    --service-account-private-key-file=/usr/local/k8s/cert/ca-key.pem \
#    --root-ca-file=/usr/local/k8s/cert/ca.pem \
#    --use-service-account-credentials=true \
#    --v=2 \
#    --logtostderr=false \
#    --log-dir=/usr/local/kubernetes/logs

ENTRYPOINT kube-controller-manager \
--address=127.0.0.1 \
--master=${KUBE_APISERVER} \
--kubeconfig=/etc/k8s/cert/kube-controller-manager/kube-controller-manager.kubeconfig \
--allocate-node-cidrs=true \
--service-cluster-ip-range=${SERVICE_CIDR} \
--cluster-cidr=${CLUSTER_CIDR} \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/etc/k8s/cert/ca/ca.pem \
--cluster-signing-key-file=/etc/k8s/cert/ca/ca-key.pem \
--experimental-cluster-signing-duration=8760h \
--leader-elect=true \
--feature-gates=RotateKubeletServerCertificate=true \
--controllers=*,bootstrapsigner,tokencleaner \
--horizontal-pod-autoscaler-use-rest-clients=true \
--horizontal-pod-autoscaler-sync-period=10s \
--tls-cert-file=/etc/k8s/cert/kube-controller-manager/kube-controller-manager.pem \
--tls-private-key-file=/etc/k8s/cert/kube-controller-manager/kube-controller-manager-key.pem \
--service-account-private-key-file=/etc/k8s/cert/ca/ca-key.pem \
--root-ca-file=/etc/k8s/cert/ca/ca.pem \
--use-service-account-credentials=true \
--v=2 \
--logtostderr=false \
--log-dir=/usr/local/kubernetes/logs

# docker run -d --net=host -v /var/k8s/cert/:/etc/k8s/cert/ -e KUBE_APISERVER="https://192.168.56.105:6443" -e SERVICE_CIDR="10.249.0.0/16" -e CLUSTER_CIDR="173.47.0.0/16" --name kuber-controller kube-controller-manager:v1.13.1