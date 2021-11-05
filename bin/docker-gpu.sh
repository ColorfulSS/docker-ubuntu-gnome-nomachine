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

################################################################################
# This script exports the various volumes and environment variables required
# by docker run in order to use GPU 3D acceleration. The script detects the GPU
# "family" with support for Nvidia, Mesa and VirtualBox, though the latter is
# a somewhat limited Virtual GPU. The script exports the required information in
# the GPU_FLAGS environment variable. This script also checks whether the user
# is in the docker group, if so then DOCKER_COMMAND is set to "docker" otherwise
# it is set to "sudo docker". N.B. use this script in place of docker-command.sh
# as this script may also set DOCKER_COMMAND as Nvidia Docker Version 1 used
# the command nvidia-docker rather than docker.
################################################################################

DOCKER_COMMAND=docker
DST=/usr/lib/x86_64-linux-gnu
if test -c "/dev/nvidia-modeset"; then
    # Nvidia GPU
    GPU_FLAGS="--device=/dev/nvidia-modeset "
    if test -f "/usr/bin/nvidia-container-runtime"; then
        # Nvidia Docker Version 2
        # See https://github.com/NVIDIA/nvidia-container-runtime.

        # Attempt to find the actual Nvidia library path. It should be
        # something like /usr/lib/nvidia-<driver version> or
        # /usr/lib/x86_64-linux-gnu. This has only been tested on
        # Linux Mint and YMMV depending on host distro it may be
        # necessary to manually set the SRC, e.g. with:
        #SRC=/usr/lib/x86_64-linux-gnu
        SRC=$(dirname $(ldconfig -p | grep libGL.so.1 | head -n 1 | tr ' ' '\n' | grep /))
        if test -f "/etc/ld.so.conf.d/x86_64-linux-gnu_GL.conf"; then
            SRC=$(cat /etc/ld.so.conf.d/x86_64-linux-gnu_GL.conf | grep /lib/)
        fi

        GPU_FLAGS+="--runtime=nvidia "
        GPU_FLAGS+="-e NVIDIA_VISIBLE_DEVICES=all "
        GPU_FLAGS+="-e NVIDIA_DRIVER_CAPABILITIES=all "
        GPU_FLAGS+="-v $SRC/libGL.so.1:$DST/libGL.so.1:ro "
        GPU_FLAGS+="-v $SRC/libGLX.so.0:$DST/libGLX.so.0:ro "
        GPU_FLAGS+="-v $SRC/libGLdispatch.so.0:$DST/libGLdispatch.so.0:ro "
        GPU_FLAGS+="-v $SRC/libEGL.so.1:$DST/libEGL.so.1:ro "
        GPU_FLAGS+="-v $SRC/libGLESv2.so.2:$DST/libGLESv2.so.2:ro "
        GPU_FLAGS+="-v $SRC/vdpau/libvdpau_nvidia.so:$DST/libvdpau_nvidia.so:ro "
    else
        # Nvidia Docker Version 1
        DOCKER_COMMAND=nvidia-docker
        SRC=/usr/local/nvidia
        GPU_FLAGS+="-e LD_LIBRARY_PATH=$SRC/lib:$SRC/lib64:${LD_LIBRARY_PATH} "
    fi
else
    # Non-Nvidia GPU path
    if test -d "/var/lib/VBoxGuestAdditions"; then
        # VirtualBox GPU
        GPU_FLAGS="--device=/dev/vboxuser "
        GPU_FLAGS+="-v /var/lib/VBoxGuestAdditions/lib/libGL.so.1:$DST/libGL.so.1 "
        for f in $DST/VBox*.so $DST/libXcomposite.so.1
        do
            GPU_FLAGS+="-v $f:$f "
        done
    else
        # Open Source Mesa GPU.
        GPU_FLAGS="--device=/dev/dri "
        # Adding video group's gid seems more reliable than adding by name.
        GPU_FLAGS+="--group-add $(cut -d: -f3 < <(getent group video)) "
    fi
fi

# If user isn't in docker group prefix docker with sudo 
if ! (id -nG $(id -un) | grep -qw docker); then
    DOCKER_COMMAND="sudo $DOCKER_COMMAND"
fi

