# macOS K3D +k3s rancher 集群开发环境部署安装

## k3d, kubectl, helm 安装升级脚本
~~~sh 
sh kkh_install.sh
~~~

# k3s + rancher服务器集群 maxos开发环境安装部署

## k3s集群安装

默认计算机上已经运行一个单节点测试集群。我们创建另一个名为k3s-rancher的，集群有一个主服务器和和1个代理节点：
~~~sh
# 创建k3s集群 1服务 3 agent 并暴露本地443 80 端口到负载均衡器 loadbalancer
k3d cluster create k3s-rancher --api-port 6550 --servers 1 --agents 3 --port 443:443@loadbalancer --port 80:80@loadbalancer
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


