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

BIN=$(cd $(dirname $0); echo ${PWD%docker-gui*})docker-gui/bin
. $BIN/docker-xauth.sh
. $BIN/docker-gpu.sh

IMAGE=ubuntu-gnome-vgl:18.04
CONTAINER=ubuntu-vgl

# Create initial /etc/passwd /etc/shadow /etc/group
# credentials. We use template files from a container
# spawned from the image we'll be using in the main
# run so that users and groups will be correct.
# If we copy from the host we may see problems if the
# host distro is different to the container distro,
# so don't do that.
if ! test -f "etc.tar.gz"; then
    echo "Creating /etc/passwd /etc/shadow and /etc/group for container."
    $DOCKER_COMMAND run --rm -it \
        -v $PWD:/mnt \
        $IMAGE sh -c 'adduser --uid '$(id -u)' --no-create-home '$(id -un)'; usermod -aG sudo '$(id -un)'; tar zcf /mnt/etc.tar.gz -C / ./etc/passwd ./etc/shadow ./etc/group'
fi

# Create home directory
mkdir -p $(id -un)

# Launch container as root to init core Linux services and
# launch the Display Manager and greeter. Switches to
# unprivileged user after login.
# --device=/dev/tty0 makes session creation cleaner.
# --ipc=host is set to allow Xephyr to use SHM XImages
$DOCKER_COMMAND run --rm -d \
    --device=/dev/tty0 \
    --name $CONTAINER \
    --ipc=host \
    --shm-size 2g \
    --security-opt apparmor=unconfined \
    --cap-add=SYS_ADMIN --cap-add=SYS_BOOT \
    -v /sys/fs/cgroup:/sys/fs/cgroup \
    -v $PWD/$(id -un):/home/$(id -un) \
    -v $DOCKER_XAUTHORITY:/root/.Xauthority.docker:ro \
    -v $DOCKER_XAUTHORITY:/home/$(id -un)/.Xauthority.docker:ro \
    -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0:ro \
    $GPU_FLAGS \
    $IMAGE /sbin/init

# cp credentials bundle to container
cat etc.tar.gz | $DOCKER_COMMAND cp - $CONTAINER:/

