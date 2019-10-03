## 安装软件地址
+ k8s: https://storage.googleapis.com/kubernetes-release/release/v1.13.1/kubernetes-server-linux-amd64.tar.gz
```bash
 wget  https://storage.googleapis.com/kubernetes-release/release/v1.13.1/kubernetes-server-linux-amd64.tar.gz
```
+ etcd: https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-amd64.tar.gz
```bash
wget https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-amd64.tar.gz
```
   > 或者 使用官方镜像  quay.io/coreos/etcd
```bash
docker pull  quay.io/coreos/etcd 
```
+ flannel 
https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-arm.tar.gz

sudo sysctl -p /etc/sysctl.d/kubernetes.conf
sudo modprobe br_netfilter
## build base image provided by k8s
+ 




##安装前准备
+ 设置系统参数
```bash
cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl -p /etc/sysctl.d/kubernetes.conf
sudo modprobe br_netfilter