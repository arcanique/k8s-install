FROM staging-k8s.gcr.io/debian-base-amd64:0.4.0

COPY kube-scheduler /usr/bin
RUN mkdir -p /usr/local/kubernetes/logs

#    kube-scheduler \
#    --address=127.0.0.1 \
#    --master=${KUBE_APISERVER} \
#    --kubeconfig=/usr/local/k8s/conf/kube-scheduler.kubeconfig \
#    --leader-elect=true \
#    --v=2 \
#    --logtostderr=false \
#    --log-dir=/usr/local/kubernetes/logs

ENTRYPOINT kube-scheduler \
--address=127.0.0.1 \
--master=${KUBE_APISERVER} \
--kubeconfig=/etc/k8s/cert/kube-scheduler/kube-scheduler.kubeconfig \
--leader-elect=true \
--v=2 \
--logtostderr=false \
--log-dir=/usr/local/kubernetes/logs

# docker run -d --net=host -v /var/k8s/cert/:/etc/k8s/cert/ -e KUBE_APISERVER="https://192.168.56.105:6443" --name kube-scheduler  kube-scheduler:v1.13.1