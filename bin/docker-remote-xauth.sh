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
# This script is for applications launched remotely using ssh X11 forwarding
# which automatically sets the DISPLAY on the remote server to something like
# localhost:10.0 and populates a .Xauthority adding the remote host.
# This script creates an .Xauthority.docker file with a wildcarded hostname.
# Include this file in any Docker launch script that needs X11 authentication.
################################################################################

# Copies .Xauthority to a temporary location based on the pid of this shell
# then nmerges an nlist from DISPLAY, with the hostname wildcarded, into
# the temporary .Xauthority before finally renaming that to .Xauthority.docker
XAUTH=${XAUTHORITY:-$HOME/.Xauthority}
DOCKER_XAUTHORITY=${XAUTH}.docker
cp --preserve=all $XAUTH $DOCKER_XAUTHORITY.$$
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $DOCKER_XAUTHORITY.$$ nmerge -
mv $DOCKER_XAUTHORITY.$$ $DOCKER_XAUTHORITY

if ! grep -Fxq "X11UseLocalhost no" /etc/ssh/sshd_config; then
    echo "Warning /etc/ssh/sshd_config does not contain \"X11UseLocalhost no\""
    echo "Containers will therefore need --network=host to do X11 forwarding."
else
    # Modify the DISPLAY to replace the hostname part with the
    # IP of the docker0 interface on the remote host.
    DOCKER_NETWORK=172.17.0.1
    DISPLAY=$(echo $DISPLAY | sed "s/^[^:]*\(.*\)/$DOCKER_NETWORK\1/")
fi

# Populate the X11_FLAGS variable as a short cut instead of
# having to set the environment and volume flags individually
# in the docker run command.

X11_FLAGS="-e DISPLAY=$DISPLAY "
X11_FLAGS+="-e XAUTHORITY=$DOCKER_XAUTHORITY "
X11_FLAGS+="-v $DOCKER_XAUTHORITY:$DOCKER_XAUTHORITY:ro "

