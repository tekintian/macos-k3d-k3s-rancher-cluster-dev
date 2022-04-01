# Macos K3D +k3s rancher 集群开发环境部署安装

在安装 k3d, k3s 和rancher 之前应该在本机先安装 命令行工具 kubectl 和 helm 包管理工具, 这2个工具的安装很简单,基本上就是下载后放到 bin目录运行即可

- kubectl安装
~~~sh
# 下载最新版  https://kubernetes.io/docs/tasks/tools/
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"

chmod +x ./kubectl
sudo mv -f ./kubectl /usr/local/bin/kubectl
sudo chown root: /usr/local/bin/kubectl
# test
kubectl version --client
~~~

- helm 安装
https://github.com/helm/helm/releases
https://helm.sh/docs/intro/install/
~~~sh
# 手动安装
wget https://get.helm.sh/helm-v3.8.1-darwin-amd64.tar.gz
tar -zxvf helm-v3.8.1-linux-amd64.tar.gz
# -f 为强制覆盖原来的
mv -f linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm

# brew 安装
brew install helm
~~~


## k3d安装和升级

提示：k3d安装需要Xcode CLT，因此请确保先已经安装过。
https://github.com/rancher/k3d/releases/

- 使用官方提供的脚本安装
https://raw.githubusercontent.com/rancher/k3d/main/install.sh

- 手动安装
https://github.com/k3d-io/k3d/releases 
下载最新的 k3d-darwin-amd64 重命名为 k3d 后保存到 /usr/local/bin/k3d
~~~sh
# 下载 https://github.com/k3d-io/k3d/releases/download/v5.4.1/k3d-darwin-amd64
mv -f k3d-darwin-amd64 /usr/local/bin/k3d
chmod +x /usr/local/bin/k3d

# 获取最新版
#K3D_VERSION=$(curl -w "%{url_effective}" -I -L -s -S https://github.com/rancher/k3d/releases/latest -o /dev/null | sed -e "s|.*/||")

#VERSION=$(curl -w "%{url_effective}" -I -L -s -S https://github.com/rancher/k3s/releases/latest -o /dev/null | sed -e "s|.*/||")

~~~


## k3s集群安装

默认计算机上已经运行一个单节点测试集群。我们创建另一个名为k3s-rancher的，集群有一个主服务器和和1个代理节点：
~~~sh
# 创建k3s集群 1服务 1 agent 并暴露本地443 80 端口到负载均衡器 loadbalancer
k3d cluster create k3s-rancher --api-port 6550 --servers 1 --agents 1 --port 443:443@loadbalancer --port 80:80@loadbalancer
# 查看集群信息
kubectl get nodes,all
~~~

## 安装Rancher

安装Rancher,首先是证书管理器。 

### 安装证书管理器
https://artifacthub.io/packages/helm/cert-manager/cert-manager
cert-manager是安装Rancher的先决条件。安装并验证证书管理器。这是基础结构的重要组成部分。
Add repository
~~~sh
### Install cert-manager with helm
helm repo add jetstack https://charts.jetstack.io
helm repo update
# 创建NS
kubectl create namespace cert-manager
# 执行安装 并输出 debug日志
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.7.2 \
    --set installCRDs=true \
    --wait --debug

# 部署 deployment rolle out
kubectl -n cert-manager rollout status deploy/cert-manager

# 查看状态
kubectl get pods --namespace cert-manager

~~~

### 安装Rancher到集群中
部署了证书管理器后，使用Helm将Rancher安装到集群中
https://artifacthub.io/packages/helm/rancher-stable/rancher
https://rancher.com/docs/rancher/v2.6/en/installation/install-rancher-on-k8s/#install-the-rancher-helm-chart
~~~sh
### 
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

kubectl create namespace cattle-system

helm install rancher rancher-latest/rancher \
    --namespace cattle-system \
    --set hostname=k3s.localhost \
    --set bootstrapPassword=admin888 \
    --set replicas=1 \
    --set auditLog.level=1 \
    --wait --debug

# 使用以下命令监视Rancher部署部署的状态：
kubectl -n cattle-system rollout status deploy/rancher

#部署Rancher完成，可使用以下命令检查安装：
kubectl -n cattle-system get rs,pods,ingresses


# 要具体查看每个节点的运行情况，可以使用下面的命令：
docker exec -it k3d-k3s-rancher-server-0 crictl ps && \
docker exec -it k3d-k3s-rancher-agent-0 crictl ps
~~~

### 其他
- 访问Rancher控制面板
https://k3s.localhost/

密码: admin888


- 停止并重新启动集群 删除集群
可以通过运行docker ps 进行确认，以查看k3s集群的服务器节点状态。
~~~sh
# 停止并重新启动集群
k3d cluster stop k3s-rancher && \
k3d cluster start k3s-rancher

# 集群清理
k3d cluster delete k3s-rancher
~~~
