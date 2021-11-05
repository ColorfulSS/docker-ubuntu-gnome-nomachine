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
# This script sets the flags needed for running Wayland applications in Docker
# containers. In particular it sets up XDG_RUNTIME_DIR in the container and
# passes the host's Wayland Unix domain socket as WAYLAND_DISPLAY.
################################################################################

WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}

# Populate the WAYLAND_FLAGS variable as a short cut instead of
# having to set the environment and volume flags individually
# in the docker run command.

WAYLAND_FLAGS="-e XDG_RUNTIME_DIR=/tmp "
WAYLAND_FLAGS+="-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY "
WAYLAND_FLAGS+="-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY "

