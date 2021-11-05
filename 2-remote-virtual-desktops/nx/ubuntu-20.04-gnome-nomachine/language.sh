#!/bin/bash
echo "开始配置中文语言支持..."
echo "安装中文支持包language-pack-zh-hans"
# 安装中文支持包language-pack-zh-hans：
sudo apt-get install language-pack-zh-hans -y
echo "修改/etc/environmen"
# 然后，修改/etc/environment（在文件的末尾追加）：
if [ ! -f "/etc/environment" ]; then
    touch "/etc/environment"
fi
sudo sed -i '$a LANG="zh_CN.UTF-8"' /etc/environment
sudo sed -i '$a LANGUAGE="zh_CN:zh:en_US:en"' /etc/environment
echo "修改/var/lib/locales/supported.d/local"
# 再修改/var/lib/locales/supported.d/local(没有这个文件就新建，同样在末尾追加)：
 # 这里的-f参数判断$myFile是否存在
if [ ! -f "/var/lib/locales/supported.d/local" ]; then
    touch "/var/lib/locales/supported.d/local"
fi
sudo sed -i '$a en_US.UTF-8 UTF-8' /var/lib/locales/supported.d/local
sudo sed -i '$a zh_CN.UTF-8 UTF-8' /var/lib/locales/supported.d/local
sudo sed -i '$a zh_CN.GBK GBK' /var/lib/locales/supported.d/local
sudo sed -i '$a zh_CN GB2312' /var/lib/locales/supported.d/local
# 最后，执行命令：
sudo locale-gen
# 对于中文乱码是空格的情况，安装中文字体解决。
sudo apt-get install fonts-droid-fallback ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming -y
echo "中文语言支持配置完成"