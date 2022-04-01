#!/bin/sh
# k3d kubeclt helm install/upgrade script for maxos
# @author tekintian@gmail.com
# 
# k3d download url: https://github.com/k3d-io/k3d/releases/download/v5.4.1/k3d-darwin-amd64
# 
echo "---------------------k3d------------------------";
# Get Current Installed k3d version
INSTALLED_VERSION=$(k3d --version|awk 'NR==1{print $3}')
if [ -x "/usr/local/bin/k3d" ];then
	echo "当前已安装的K3D版本 ${INSTALLED_VERSION}"
else
	echo "当前未安装K3D, 正在准备安装中......"
fi

#get latest k3d version
LATEST_VERSION=$(curl -w "%{url_effective}" -I -L -s -S https://github.com/rancher/k3d/releases/latest -o /dev/null | sed -e "s|.*/||");

if [ $INSTALLED_VERSION != $LATEST_VERSION ] || [ ! -x "/usr/local/bin/k3d" ];then
	echo "发现最新版本 ${LATEST_VERSION} 正在安装中....."
	curl -LO "https://github.com/k3d-io/k3d/releases/download/${LATEST_VERSION}/k3d-darwin-amd64"
	# wget https://github.com/k3d-io/k3d/releases/download/${LATEST_VERSION}/k3d-darwin-amd64
	mv -f k3d-darwin-amd64 /usr/local/bin/k3d
	chmod +x /usr/local/bin/k3d
	echo "k3d ${LATEST_VERSION} 安装/升级成功!"
else
	echo "当前 k3d 版本${INSTALLED_VERSION} 为最新版本,无需升级!"
fi

echo "---------------------kubectl------------------------";
echo "检测 kubectl 版本信息....";

# 获取已安装的kubectl 版本信息
# kubectl version | sed 's/.*GitVersion:"\(.*\)", GitCommit.*/\1/g'|awk 'NR==1{print}'
KUBECTL_IVER=$(kubectl version|awk -F '[:]' 'NR==1{print $5}'|awk -F '["]' '{print $2}')
# 获取最新版 kubectl信息
KUBECTL_LVER=$(curl -L -s https://dl.k8s.io/release/stable.txt)

# 如果本地版本和远程版本不一致 或者没有邦迪版本,则执行安装
if [ ${KUBECTL_IVER} != ${KUBECTL_LVER} ] || [ ! -x "/usr/local/bin/kubectl" ];then
	echo "发现最新版本 ${KUBECTL_LVER} 正在安装中....."
	curl -LO "https://dl.k8s.io/release/${KUBECTL_LVER}/bin/darwin/amd64/kubectl"
	mv -f ./kubectl /usr/local/bin/kubectl
	chmod +x /usr/local/bin/kubectl
	echo "kubectl ${KUBECTL_LVER} 安装/升级成功!"
else
	echo "当前kubectl版本 ${KUBECTL_IVER} 为最新版本,无需升级!"
fi

echo "---------------------helm------------------------";
echo "检测 helm 版本信息...."
# 获取已安装的 helm 版本信息
HELM_IVER=$(helm version|sed 's/.*Version:"\(.*\)", GitCommit.*/\1/g')

# 检测最新helm版本信息
HELM_LVER=$(curl -w "%{url_effective}" -I -L -s -S https://github.com/helm/helm/releases/latest -o /dev/null | sed -e "s|.*/||");

# 如果本地版本和远程版本不一致 或者没有邦迪版本,则执行安装
if [ ${HELM_IVER} != ${HELM_LVER} ] || [ ! -x "/usr/local/bin/kubectl" ];then
	echo "发现最新版本 ${HELM_LVER} 正在安装中....."
	curl -LO "https://get.helm.sh/helm-${HELM_LVER}-darwin-amd64.tar.gz"
	# 直接解压tar.gz文件中的helm到本级目录 --strip-components=1
	tar -zxvf helm-${HELM_LVER}-darwin-amd64.tar.gz --strip-components=1
	# -f 为强制覆盖原来的
	mv -f helm /usr/local/bin/helm
	chmod +x /usr/local/bin/helm
	echo "helm ${HELM_LVER} 安装/升级成功!"
else
	echo "当前helm版本 ${HELM_IVER} 为最新版本,无需升级!"
fi
