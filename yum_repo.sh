#!/bin/bash
#Author: 小白扮大神.
#Date & Time: 2017-09-28
#Version: 1.0.1.

function checkos(){
	if [ -f /etc/redhat-release ];then
		VER=`cat /etc/centos-release | tr -d -c '0-9' | cut -c1`
		if [ ! -f /etc/centos-release ];then
			VER=`cat /etc/os-release | tr -d -c '0-9' | cut -c1`
		fi
		centos_version=`grep -oE  "[0-9.]+" /etc/redhat-release`
		echo -e "SYSTEM VERSION:${centos_version}"
		if [ "$VER" == "6" ];then
			prepare
			centos6_yum
		elif [ "$VER" == "7" ];then
			prepare
			centos7_yum
		else
			echo -e "\033[31m The installation is terminated\a! Please check and try again! \033[0m";
			exit;
		fi
	fi
}

function centos6_yum(){
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
yum clean all
yum makecache
}

function centos7_yum(){
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache
}
