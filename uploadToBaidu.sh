#!/bin/bash

PKG_MANAGER="apt"

$PKG_MANAGER -y install unzip wget
cd ~
#https://github.com/liuzhuoling2011/BaiduPCS-Go
wget https://github.com/iikira/BaiduPCS-Go/releases/download/v3.5.6/BaiduPCS-Go-v3.5.6-linux-amd64.zip
unzip BaiduPCS-Go-v3.5.6-linux-amd64.zip
mv BaiduPCS-Go-v3.5.6-linux-amd64/BaiduPCS-Go /usr/bin/baidupcs
baidupcs login
baidupcs upload ~/images.tar /我的资源