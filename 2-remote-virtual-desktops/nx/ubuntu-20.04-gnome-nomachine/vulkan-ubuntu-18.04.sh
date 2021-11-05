#!/bin/bash
wget -qO - https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo apt-key add -
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-1.2.189-bionic.list https://packages.lunarg.com/vulkan/1.2.189/lunarg-vulkan-1.2.189-bionic.list
sudo apt update
sudo apt install vulkan-sdk
