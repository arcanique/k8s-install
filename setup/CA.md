## CA证书创建
+ 证书生成工具
sudo wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /usr/local/cfssl/bin/cfssl
sudo wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O /usr/local/cfssl/bin/cfssljson
sudo wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O /usr/local/cfssl/bin/cfssl-certinfo
## 创建CA证书(需要在安装部署时考虑自动化)
> CA 证书是集群所有节点共享的，只需要创建一个 CA 证书，后续创建的所有证书都由它签名。
> CA 配置文件用于配置根证书的使用场景 (profile) 和具体参数 (usage，过期时间、服务端认证、客户端认证、加密等)，后续在签名其它证书时需要指定特定场景
+ 根证书(CA)文件的JSON配置文件
```bash
cat > ${root_path}/cert/ca/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
```
> signing：表示该证书可用于签名其它证书，生成的 ca.pem 证书中 CA=TRUE；
> server auth：表示 client 可以用该该证书对 server 提供的证书进行验证；
> client auth：表示 server 可以用该该证书对 client 提供的证书进行验证；

+ 证书签名请求文件（CSR）的JSON配置文件
```bash
cat > ${root_path}/cert/ca/ca-csr.json <<EOF
{
  "CN": "kubernetes",
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
+ 生成CA 证书 

```bash
# generate
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
# view
openssl x509 -noout -text -in /usr/local/cfssl/cert/ca.pem

```