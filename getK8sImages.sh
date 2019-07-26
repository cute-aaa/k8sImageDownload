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
echo "卸载旧docker"
$PKG_MANAGER -y remove docker \
               docker-engine \
               docker.io

echo "下载所需工具"   
$PKG_MANAGER -y install curl

echo "获取下载脚本"
curl -fsSL get.docker.com -o get-docker.sh

echo "下载docker"
sh get-docker.sh

echo "清理无关镜像"
docker rmi $(docker images -q)

echo "下载k8s"
if [ $PKG_MANAGER == "apt" ]
then
	$PKG_MANAGER update && $PKG_MANAGER install -y apt-transport-https curl
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
	cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
	deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
	$PKG_MANAGER update
	$PKG_MANAGER install -y kubelet kubeadm kubectl
	apt-mark hold kubelet kubeadm kubectl
elif [ $PKG_MANAGER == "yum" ]
then
	cat <<EOF > /etc/yum.repos.d/kubernetes.repo
	[kubernetes]
	name=Kubernetes
	baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
	# Set SELinux in permissive mode (effectively disabling it)
	setenforce 0
	sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
	yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
	systemctl enable --now kubelet
fi

echo "关闭swap分区"
swapoff -a && sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

echo "获取IP地址"
#hostname -I > ip.txt  $(cut -d ' ' -f 1 ip.txt)
ipaddrs=($(hostname -I))
echo "IP地址："${ipaddrs[0]}

echo "初始化k8s"
kubeadm init --apiserver-advertise-address ${ipaddrs[0]} --pod-network-cidr 10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

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
docker pull calico/kube-controllers:$CALICO_VERSION
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta2/aio/deploy/recommended.yaml
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.5/examples/kubernetes/1.14/cilium.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-kubeadm.yml
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

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

#mkdir canal
#cd canal/
#kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/canal.yaml
#这个没有镜像
#cd ..

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