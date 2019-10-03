FROM staging-k8s.gcr.io/debian-base-amd64:0.4.0

COPY kube-proxy ipset iptables netstat /usr/bin/
COPY lib* /lib/
RUN mkdir -p /usr/local/kubernetes/logs

ENTRYPOINT kube-proxy \
--config=/etc/k8s/cert/kube-proxy/yaml/kube-proxy.config.yaml \
--v=2 \
--logtostderr=false \
--log-dir=/usr/local/kubernetes/logs

# docker run -d --privileged=true  --net=host -v /var/k8s/cert/:/etc/k8s/cert/  --name kube-proxy kube-proxy:v1.13.1