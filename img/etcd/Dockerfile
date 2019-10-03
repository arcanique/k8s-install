FROM staging-k8s.gcr.io/debian-base-amd64:0.4.0

COPY etcd* /usr/bin/
RUN mkdir -p /var/lib/etcd
# --data-dir /var/lib/etcd \
# --name s1 \
# --cert-file /etc/k8s/cert/etcd/etcd.pem \
# --key-file /etc/k8s/cert/etcd/etcd-key.pem \
# --trusted-ca-file /etc/k8s/cert/ca/ca.pem \
# --peer-cert-file /etc/k8s/cert/etcd/etcd.pem \
# --peer-key-file /etc/k8s/cert/etcd/etcd-key.pem \
# --peer-trusted-ca-file /etc/k8s/cert/ca/ca.pem \
# --listen-peer-urls https://192.168.56.105:2380 \
# --initial-advertise-peer-urls https://192.168.56.105:2380 \
# --listen-client-urls https://192.168.56.105:2379,http://127.0.0.1:2379 \
# --advertise-client-urls https://192.168.56.105:2379 \
# --initial-cluster-token k8s-etcd-cluster \
# --initial-cluster s1=https://192.168.56.105:2380 \
# --initial-cluster-state new \
# --logger zap \
# --log-level info
ENTRYPOINT etcd \
--data-dir /var/lib/etcd \
--name s1 \
--cert-file ${cert} \
--key-file ${key} \
--trusted-ca-file ${ca} \
--peer-cert-file ${peer_cert} \
--peer-key-file ${peer_key} \
--peer-trusted-ca-file ${peer_ca} \
--listen-peer-urls https://${HOST_IP}:2380 \
--initial-advertise-peer-urls https://${HOST_IP}:2380 \
--listen-client-urls https://${HOST_IP}:2379,http://127.0.0.1:2379 \
--advertise-client-urls https://${HOST_IP}:2379 \
--initial-cluster-token k8s-etcd-cluster \
--initial-cluster ${ETCD_CLUISTER} \
--initial-cluster-state new \
--logger zap \
--log-level info

# docker run -d --net=host -v /var/k8s/cert/:/etc/k8s/cert/ -e cert=/etc/k8s/cert/etcd/etcd.pem -e key=/etc/k8s/cert/etcd/etcd-key.pem -e ca=/etc/k8s/cert/ca/ca.pem -e peer_cert=/etc/k8s/cert/etcd/etcd.pem -e peer_key=/etc/k8s/cert/etcd/etcd-key.pem -e peer_ca=/etc/k8s/cert/ca/ca.pem -e HOST_IP=192.168.56.105 -e ETCD_CLUISTER="s1=https://192.168.56.105:2380" --name etcdnew etcd:v3.4.1