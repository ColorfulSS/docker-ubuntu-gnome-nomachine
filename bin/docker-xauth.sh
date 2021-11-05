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

# Populate the X11_FLAGS variable as a short cut instead of
# having to set the environment and volume flags individually
# in the docker run command. The X11_FLAGS_RW variable is
# similar except the X11 socket directory is bind-mounted rw
# for use-cases such as nested X servers where we might need
# to open additional displays and thus write to that directory.

X11_XAUTH="-e XAUTHORITY=$DOCKER_XAUTHORITY "
X11_XAUTH+="-v $DOCKER_XAUTHORITY:$DOCKER_XAUTHORITY:ro "

X11_DISPLAY="-e DISPLAY=unix$DISPLAY "
X11_DISPLAY+="-v /tmp/.X11-unix:/tmp/.X11-unix:ro "

X11_DISPLAY_RW="-e DISPLAY=unix$DISPLAY "
X11_DISPLAY_RW+="-v /tmp/.X11-unix:/tmp/.X11-unix:rw "

X11_FLAGS=$X11_XAUTH$X11_DISPLAY
X11_FLAGS_RW=$X11_XAUTH$X11_DISPLAY_RW


