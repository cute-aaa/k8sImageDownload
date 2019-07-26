#!/bin/bash

# 环境：https://www.katacoda.com/courses/ubuntu/playground
# 也可以直接在配置好的环境下载镜像：
# https://www.katacoda.com/courses/kubernetes/launch-single-node-cluster
# 不过版本需要变更一下

#包管理程序
PKG_MANAGER="apt"


#镜像总数
imageNum=24
#核心镜像版本
K8S_VERSION="v1.15.1"
COREDNS_VERSION="1.3.1"
ETCD_VERSION="3.3.10"
PAUSE_VERSION="3.1"

#dashboard版本
DASHBOARD_VERSION="v1.10.1"
DASHBOARD_BETA_VERSION="v2.0.0-beta2"
#dashboard-beta的依赖
METRICS_SCRAPER_VERSION="v1.0.1"

#网络附件镜像版本
#calico
CALICO_VERSION="v3.8.0"

#cilium
CILIUM_ETCD_OPERATOR_VERSION="v2.0.6"
CILIUM_INIT_VERSION="2019-04-05"
CILIUM_VERSION="v1.5.5"

#flannel
FLANNEL_VERSION="v0.11.0-amd64"

#romana
ROMANA_VERSION="v2.0.2"
#romana依赖
ETCD_AMD64_VERSION="3.0.17"

#weavenet
WEAVENET_VERSION="2.5.2"


echo "只用于镜像下载，不可用于生产环境"

echo "下载所需工具"   
$PKG_MANAGER -y install curl

echo "获取下载脚本"
curl -fsSL get.docker.com -o get-docker.sh

echo "下载docker"
sh get-docker.sh

echo "清理无关镜像"
docker rmi $(docker images -q)

echo "下载基础镜像"
docker pull k8s.gcr.io/kube-proxy:$K8S_VERSION
docker pull k8s.gcr.io/kube-apiserver:$K8S_VERSION
docker pull k8s.gcr.io/kube-scheduler:$K8S_VERSION
docker pull k8s.gcr.io/kube-controller-manager:$K8S_VERSION
docker pull k8s.gcr.io/coredns:$COREDNS_VERSION
docker pull k8s.gcr.io/etcd:$ETCD_VERSION
docker pull k8s.gcr.io/pause:$PAUSE_VERSION

echo "保存基础镜像"
mkdir ~/images
cd ~/images
docker save k8s.gcr.io/kube-proxy:$K8S_VERSION > k8s.gcr.io#kube-proxy.tar
docker save k8s.gcr.io/kube-apiserver:$K8S_VERSION > k8s.gcr.io#kube-apiserver.tar
docker save k8s.gcr.io/kube-scheduler:$K8S_VERSION > k8s.gcr.io#kube-scheduler.tar
docker save k8s.gcr.io/kube-controller-manager:$K8S_VERSION > k8s.gcr.io#kube-controller-manager.tar
docker save k8s.gcr.io/coredns:$COREDNS_VERSION > k8s.gcr.io#coredns.tar
docker save k8s.gcr.io/etcd:$ETCD_VERSION > k8s.gcr.io#etcd.tar
docker save k8s.gcr.io/pause:$PAUSE_VERSION > k8s.gcr.io#pause.tar

echo "下载附件"
docker pull k8s.gcr.io/kubernetes-dashboard-amd64:$DASHBOARD_VERSION
docker pull kubernetesui/dashboard:$DASHBOARD_BETA_VERSION
docker pull kubernetesui/metrics-scraper:$METRICS_SCRAPER_VERSION
docker pull calico/node:$CALICO_VERSION
docker pull calico/cni:$CALICO_VERSION
docker pull calico/kube-controllers:$CALICO_VERSION
docker pull calico/pod2daemon-flexvol:$CALICO_VERSION
docker pull cilium/cilium-etcd-operator:$CILIUM_ETCD_OPERATOR_VERSION
docker pull cilium/cilium-init:$CILIUM_INIT_VERSION
docker pull cilium/cilium:$CILIUM_VERSION
docker pull quay.io/coreos/flannel:$FLANNEL_VERSION
docker pull quay.io/romana/daemon:$ROMANA_VERSION
docker pull quay.io/romana/listener:$ROMANA_VERSION
docker pull quay.io/romana/agent:$ROMANA_VERSION
docker pull gcr.io/google_containers/etcd-amd64:$ETCD_AMD64_VERSION
docker pull weaveworks/weave-kube:$WEAVENET_VERSION
docker pull weaveworks/weave-npc:$WEAVENET_VERSION

while [ $(docker images -q | wc -l) -lt $imageNum ]
do
    echo "当前镜像数：" $(docker images -q | wc -l)
	echo "目标镜像数：" $imageNum
    echo "等待镜像下载完成"
	sleep 5
done

echo "保存dashboard"
mkdir dashboard
cd dashboard/
docker save k8s.gcr.io/kubernetes-dashboard-amd64:$DASHBOARD_VERSION > k8s.gcr.io#kubernetes-dashboard-amd64.tar
docker save kubernetesui/dashboard:$DASHBOARD_BETA_VERSION > kubernetesui#dashboard.tar
docker save kubernetesui/metrics-scraper:$METRICS_SCRAPER_VERSION > kubernetesui#metrics-scraper.tar
cd ..

echo "保存网络附件"
mkdir add-on/
cd add-on/

mkdir calico
cd calico/
docker save calico/node:$CALICO_VERSION > calico#node.tar
docker save calico/cni:$CALICO_VERSION > calico#cni.tar
docker save calico/kube-controllers:$CALICO_VERSION > calico#kube-controllers.tar
docker save calico/pod2daemon-flexvol:$CALICO_VERSION > calico#pod2daemon-flexvol.tar
cd ..

mkdir cilium
cd cilium/
docker save cilium/cilium-etcd-operator:$CILIUM_ETCD_OPERATOR_VERSION > cilium#cilium-etcd-operator.tar
docker save cilium/cilium-init:$CILIUM_INIT_VERSION > cilium#cilium-init.tar
docker save cilium/cilium:$CILIUM_VERSION > cilium#cilium.tar
cd ..

mkdir flannel && cd flannel
docker save quay.io/coreos/flannel:$FLANNEL_VERSION > quay.io#coreos#flannel.tar
cd ..

mkdir romana && cd romana/
docker save quay.io/romana/daemon:$ROMANA_VERSION > quay.io#romana#daemon.tar
docker save quay.io/romana/listener:$ROMANA_VERSION > quay.io#romana#listener.tar
docker save quay.io/romana/agent:$ROMANA_VERSION > quay.io#romana#agent.tar
docker save gcr.io/google_containers/etcd-amd64:$ETCD_AMD64_VERSION > gcr.io#google_containers#etcd-amd64.tar
cd ..

mkdir weavenet && cd weavenet
docker save weaveworks/weave-kube:$WEAVENET_VERSION > weaveworks#weave-kube.tar
docker save weaveworks/weave-npc:$WEAVENET_VERSION > weaveworks#weave-npc.tar
cd ..

cd ~

echo "打包镜像"
tar czvf images.tar images/
echo "完成!"