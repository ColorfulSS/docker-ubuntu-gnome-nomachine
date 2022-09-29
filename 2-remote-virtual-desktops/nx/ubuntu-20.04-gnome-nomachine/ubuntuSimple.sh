#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# 镜像名称 IMAGE
read -p "请输入需要使用的镜像名称（例: colorfulsky/ubuntu-gnome-nomachine:20.04）:" IMAGE
while test -z "$IMAGE"
do
    read -p "请输入内容为空，请重新输入:" IMAGE
done

# 容器名称 CONTAINER
read -p "请设置容器名称（例:ubuntu-gnome-nomachine-1）:" CONTAINER
while test -z "$CONTAINER"
do
    read -p "输入内容为空，请重新输入:" CONTAINER
done

# Nomachine映射端口 NomachineBindPort
read -p "请设置Nomachine映射端口（例:23333）:" NomachineBindPort
while test -z "$NomachineBindPort"
do
    read -p "输入内容为空，请重新输入:" NomachineBindPort
done

# SSH 映射端口 SshBindPort
read -p "请设置SSH映射端口（例:22222）:" SshBindPort
while test -z "$SshBindPort"
do
    read -p "输入内容为空，请重新输入:" SshBindPort
done

# 工作空间映射目录 WorkSpaceBind 
read -p "请设置目录映射（例:/data/workspace/xxx）:" WorkSpaceBind
while test -z "$WorkSpaceBind"
do
    read -p "输入内容为空，请重新输入:" WorkSpaceBind
done

# 创建用户名 CreateUserAccount
read -p "请设置登录用户名（例:user）:" CreateUserAccount
while test -z "$CONTAINER"
do
    read -p "输入内容为空，请重新输入:" CreateUserAccount
done

# 使用的渲染器类型 RenderType
echo "======Cpu渲染速度较快 特殊需求可以选择Gpu======"
read -p "请选择渲染器类型（例:Gpu / Cpu）:" RenderType
while test -z "$RenderType"
do
    read -p "输入内容为空，请重新输入:" RenderType
done

# 自动安装配置显卡驱动脚本
# 判断；显卡类型，安装对应驱动程序
echo "Tesla系列: V100 A100 ... | GeForce系列: 3090 2080 ..."
read -p "请确认显卡系列[例: V100输入Tesla / RTX3090输入GeForce]:" NvidiaDriver
while test -z "$NvidiaDriver"
do
    read -p "输入内容为空，请重新输入:" NvidiaDriver
done


# Default
# IMAGE=ubuntu-gnome-nomachine:20.04
# CONTAINER=ubuntu-nomachine20
# NomachineBindPort=25008
# SshBindPort=24001
# WorkSpaceBind=/data/workspace/youguoliang
# CreateUserAccount=colorful
# Launch container as root to init core Linux services and
# launch the Display Manager and greeter. Switches to
# unprivileged user after login.
# --device=/dev/tty0 makes session creation cleaner.
# --ipc=host is set to allow Xephyr to use SHM XImages
docker run -d \
    --restart=always \
    -p $NomachineBindPort:4000 \
    -p $SshBindPort:22 \
    --privileged=true\
    --userns host \
    --device=/dev/tty0 \
    --name $CONTAINER \
    --ipc=host \
    --shm-size 2g \
    --security-opt apparmor=unconfined \
    --cap-add=SYS_ADMIN --cap-add=SYS_BOOT \
    -e CreateUserAccount=$CreateUserAccount \
    -e RenderType=$RenderType \
    -e NvidiaDriver=$NvidiaDriver \
    -v /sys/fs/cgroup:/sys/fs/cgroup \
    -v $WorkSpaceBind:/data \
    $IMAGE /sbin/init
    
echo "Docker Container 启动成功"
echo "开始自动安装显卡驱动并配置虚拟显示器..."
# 开始安装配置
echo [ $NvidiaDriver == "Tesla" ]
if [ $NvidiaDriver == "Tesla" ]
then
    docker exec -it $CONTAINER /home/Tesla-XorgDisplaySettingAuto.sh
elif [ $NvidiaDriver == "GeForce" ]
then
# GeForce系列显卡使用更新后的脚本文件
    docker exec -it $CONTAINER curl -o GeForce-XorgDisplaySettingAuto_DP.sh https://raw.githubusercontent.com/ColorfulSS/docker-ubuntu-gnome-nomachine/master/2-remote-virtual-desktops/nx/ubuntu-20.04-gnome-nomachine/GeForce-XorgDisplaySettingAuto.sh
    docker exec -it $CONTAINER chmod +x /home/GeForce-XorgDisplaySettingAuto_DP.sh
    docker exec -it $CONTAINER /home/GeForce-XorgDisplaySettingAuto_DP.sh
    #docker exec -it $CONTAINER /home/GeForce-XorgDisplaySettingAuto.sh
else
    echo "当前显卡类型不在自动脚本支持范围内-请手动修改脚本安装配置"
fi
