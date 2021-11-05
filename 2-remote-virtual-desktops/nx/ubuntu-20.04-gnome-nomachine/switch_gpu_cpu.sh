#!/bin/bash
# 使用的渲染器类型 RenderType
echo "======Cpu渲染速度较快 特殊需求可以选择Gpu======"
read -p "请选择渲染器类型（例:Gpu / Cpu）:" RenderType
while test -z "$RenderType"
do
    read -p "输入内容为空，请重新输入:" RenderType
done
# 停止lightdm管理模块
sudo /etc/init.d/lightdm stop

# 判断是否设置Gpu渲染
if [ "$RenderType" == "Gpu" ]; then
  echo "使用Gpu渲染 开始配置虚拟显示器"
  # Gpu渲染 配置虚拟显示器
  echo "X11 set"

  if [ -f "/etc/X11/xorg.conf" ]; then
    sudo rm /etc/X11/xorg.conf
  fi

  echo "UUID"
  if [ "$NVIDIA_VISIBLE_DEVICES" == "all" ]; then
    export GPU_SELECT=$(sudo nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)
  elif [ -z "$NVIDIA_VISIBLE_DEVICES" ]; then
    export GPU_SELECT=$(sudo nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)
  else
    export GPU_SELECT=$(sudo nvidia-smi --id=$(echo "$NVIDIA_VISIBLE_DEVICES" | cut -d ',' -f1) --query-gpu=uuid --format=csv | sed -n 2p)
    if [ -z "$GPU_SELECT" ]; then
      export GPU_SELECT=$(sudo nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)
    fi
  fi

  if [ -z "$GPU_SELECT" ]; then
    echo "No NVIDIA GPUs detected. Exiting."
    exit 1
  fi

  echo "Allow Empty"
  export SIZEW=1920
  export SIZEH=1200
  export CDEPTH=24
  HEX_ID=$(sudo nvidia-smi --query-gpu=pci.bus_id --id="$GPU_SELECT" --format=csv | sed -n 2p)
  IFS=":." ARR_ID=($HEX_ID)
  BUS_ID=PCI:$((16#${ARR_ID[1]})):$((16#${ARR_ID[2]})):$((16#${ARR_ID[3]}))
  export MODELINE=$(cvt -r ${SIZEW} ${SIZEH} | sed -n 2p)
  sudo nvidia-xconfig --virtual="${SIZEW}x${SIZEH}" --depth="$CDEPTH" --allow-empty-initial-configuration --busid="$BUS_ID" 
  sudo sed -i '/Driver\s\+"nvidia"/a\    Option       "HardDPMS" "false"' /etc/X11/xorg.conf
  sudo sed -i '/Section\s\+"Monitor"/a\    '"$MODELINE" /etc/X11/xorg.conf
  sudo sed -i '/SubSection\s\+"Display"/a\        Viewport 0 0' /etc/X11/xorg.conf
  sudo sed -i '/Section\s\+"ServerLayout"/a\    Option "AllowNVIDIAGPUScreens"' /etc/X11/xorg.conf
else
  echo "使用默认Cpu渲染模式 开始配置"
  if [ -f "/etc/X11/xorg.conf" ]; then
    sudo rm /etc/X11/xorg.conf
  fi
  # 下载配置文件
  sudo cd /etc/X11
  sudo wget https://git.ustc.edu.cn/Colorful/file_download/-/raw/main/xorg.conf
  sudo chmod 755 xorg.conf

fi

sudo gsettings set org.gnome.desktop.interface enable-animations false
sudo /etc/init.d/lightdm restart
sleep 5
sudo /etc/NX/nxserver --restart
sudo tail -f /usr/NX/var/log/nxserver.log
