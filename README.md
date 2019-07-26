# k8sImageDownload
用于下载kubeadm初始化时需要的镜像

环境：
- Katacoda https://www.katacoda.com/courses/ubuntu/playground
- 百度网盘（Baidu PCS）
- PanDownload

原理：
在katacoda上下载好所需镜像，然后通过百度网盘上传到百度云，再通过Pandownload下载（有百度云会员可以不用PanDownload）

getK8sImages.sh和getK8sImage_lite.sh是下载镜像，区别是前者会先去下载k8s，然后通过k8s下载镜像，后者直接使用docker拉取镜像。得到的镜像都是一样的。

打包好之后，如果有公网服务器可以直接用ftp传过去。没有的话可以借助百度网盘：
uploadToBaidu.sh是上传镜像，把刚才打包的镜像上传到百度云。使用了[这位大佬](https://github.com/liuzhuoling2011/BaiduPCS-Go)的Baidu PCS客户端
loadImage.sh是导入镜像，镜像下载好并放到服务器里之后，把压缩包解压，然后在images/add-on/目录里把不需要的网络附件删除，只留一个就够了。然后在镜像所在目录执行这个脚本就行了。
具体操作可以看https://blog.csdn.net/oooo2316/article/details/97396779
