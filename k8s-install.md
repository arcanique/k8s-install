# kubernetes 安装配置指导

+ [Prepare](./setup/prepare.md)
+ [CA generate](./setup/CA.md)
+ [Etcd install](./setup/etcd.md)
+ [kubectl install](./setup/kubectl.md)
+ [kube-apiserver install](./setup/kube-apiserver.md)
+ [kube-controller-manager install](./setup/kube-controller.md)
+ [kube-scheduler install](./setup/kube-scheduler.md)
+ [flannel install](./setup/flannel.md)
+ [kubelet install](./setup/kubelet.md)
+ [kube-proxy install](./setup/kube-proxy.md)
+ [addon install](./setup/addon.md)


***教程 https://www.jianshu.com/p/c492f5efdadf***
https://www.jianshu.com/p/c492f5efdadf


.
├── cert
│   ├── 1.1.1.1
│   ├── admin
│   │   ├── admin.csr
│   │   ├── admin-csr.json
│   │   ├── admin-key.pem
│   │   └── admin.pem
│   ├── ca
│   │   ├── ca-config.json
│   │   ├── ca.csr
│   │   ├── ca-csr.json
│   │   ├── ca-key.pem
│   │   └── ca.pem
│   ├── etcd
│   │   ├── etcd.csr
│   │   ├── etcd-csr.json
│   │   ├── etcd-key.pem
│   │   └── etcd.pem
│   ├── flannel
│   │   ├── flanneld.csr
│   │   ├── flanneld-csr.json
│   │   ├── flanneld-key.pem
│   │   └── flanneld.pem
│   ├── kube-controller-manager
│   │   ├── kube-controller-manager.csr
│   │   ├── kube-controller-manager-csr.json
│   │   ├── kube-controller-manager-key.pem
│   │   ├── kube-controller-manager.kubeconfig
│   │   └── kube-controller-manager.pem
│   ├── kube-proxy
│   │   ├── conf
│   │   ├── kube-proxy.csr
│   │   ├── kube-proxy-csr.json
│   │   ├── kube-proxy-key.pem
│   │   ├── kube-proxy.pem
│   │   └── yaml
│   ├── kubernetes
│   │   ├── bootstrap
│   │   ├── kubernetes.csr
│   │   ├── kubernetes-csr.json
│   │   ├── kubernetes-key.pem
│   │   ├── kubernetes.pem
│   │   └── yaml
│   └── kube-scheduler
│       ├── kube-scheduler.csr
│       ├── kube-scheduler-csr.json
│       ├── kube-scheduler-key.pem
│       ├── kube-scheduler.kubeconfig
│       └── kube-scheduler.pem
├── config
│   └── encryption-config.yaml
├── deployment
│   ├── debian
│   │   ├── changelog
│   │   ├── compat
│   │   ├── control
│   │   ├── coredns.manpages
│   │   ├── coredns.postinst
│   │   ├── coredns.service
│   │   ├── Corefile
│   │   └── rules
│   ├── docker
│   │   ├── dns.yml
│   │   └── README.md
│   ├── HomebrewFormula
│   │   └── coredns.rb
│   ├── kubernetes
│   │   ├── CoreDNS-k8s_version.md
│   │   ├── coredns.yaml
│   │   ├── coredns.yaml.sed
│   │   ├── corefile-tool
│   │   ├── deploy.sh
│   │   ├── FAQs.md
│   │   ├── migration
│   │   ├── README.md
│   │   ├── rollback.sh
│   │   ├── Scaling_CoreDNS.md
│   │   └── Upgrading_CoreDNS.md
│   ├── LICENSE
│   ├── Makefile
│   ├── README.md
│   └── systemd
│       ├── coredns.service
│       ├── coredns-sysusers.conf
│       ├── coredns-tmpfiles.conf
│       └── README.md
├── etcd-v3.4.1-linux-amd64
│   ├── default.etcd
│   │   └── member
│   ├── Documentation
│   │   ├── benchmarks
│   │   ├── branch_management.md
│   │   ├── demo.md
│   │   ├── dev-guide
│   │   ├── dev-internal
│   │   ├── dl_build.md
│   │   ├── docs.md
│   │   ├── etcd-mixin
│   │   ├── faq.md
│   │   ├── integrations.md
│   │   ├── learning
│   │   ├── metrics
│   │   ├── metrics.md
│   │   ├── op-guide
│   │   ├── platforms
│   │   ├── production-users.md
│   │   ├── README.md -> docs.md
│   │   ├── reporting_bugs.md
│   │   ├── rfc
│   │   ├── triage
│   │   ├── tuning.md
│   │   ├── upgrades
│   │   └── v2
│   ├── etcd
│   ├── etcdctl
│   ├── README-etcdctl.md
│   ├── README.md
│   └── READMEv2-etcdctl.md
├── etcd-v3.4.1-linux-amd64.tar.gz
├── example
│   └── ngx.yaml
├── img
│   ├── back
│   │   ├── flannel.tar
│   │   ├── kube-proxy.tar
│   │   └── pause.tar
│   ├── etcd
│   │   ├── Dockerfile
│   │   ├── etcd
│   │   └── etcdctl
│   ├── flannel
│   │   ├── dad.yaml
│   │   └── kube-flannel.yml
│   ├── kube-apiserver
│   │   ├── Dockerfile
│   │   └── kube-apiserver
│   ├── kube-controller
│   │   ├── Dockerfile
│   │   └── kube-controller-manager
│   ├── kubelet
│   │   ├── csr-crb.yaml
│   │   ├── genKubeletconfig.sh
│   │   ├── kubelet-bootstrap-192-168-56-105.kubeconfig
│   │   └── kubelet.config.json
│   ├── kube-proxy
│   │   ├── Dockerfile
│   │   ├── ipset
│   │   ├── iptables
│   │   ├── kube-proxy
│   │   ├── libip4tc.so.0
│   │   ├── libip6tc.so.0
│   │   ├── libipset.so.3
│   │   ├── libxtables.so.12
│   │   └── netstat
│   └── kube-scheduler
│       ├── Dockerfile
│       └── kube-scheduler
