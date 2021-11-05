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
# by docker run in order to use dconf/D-bus and also the D-bus system bus.
# The script also sets an environment variable containing the flags needed
# to configure AppArmor in docker run, which is necessary in order to connect
# to D-bus on systems with AppArmor enabled by default.
#
# Use this script if you want to connect to the D-bus session bus.
################################################################################

if [[ $DBUS_SESSION_BUS_ADDRESS == *"abstract"* ]]; then
    echo "Warning: ${DBUS_SESSION_BUS_ADDRESS} is an abstract socket"
    echo "Adding --network=host flag so container can connect to abstract socket"
    DBUS_FLAGS="--network=host -e NO_AT_BRIDGE=1 "
else
    DBUS_FLAGS="-v $XDG_RUNTIME_DIR/bus:$XDG_RUNTIME_DIR/bus:ro -e NO_AT_BRIDGE=1 "
fi

# Add flags for connecting to the D-bus system bus.
DBUS_FLAGS+="-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro "
DBUS_FLAGS+="-e DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS "

if test -f "/etc/apparmor.d/docker-dbus"; then
    APPARMOR_FLAGS="--security-opt apparmor:docker-dbus"
else
    echo "Warning: Enabling D-bus by setting --security-opt apparmor=unconfined"
    echo "For improved security enable the docker-dbus AppArmor profile available in"
    echo "${PWD%docker-gui*}docker-gui/bin/docker-dbus"
    APPARMOR_FLAGS="--security-opt apparmor=unconfined"
fi

# Populate the DCONF_FLAGS variable as a short cut instead of
# having to set the environment and volume flags individually.
DCONF_FLAGS=$DBUS_FLAGS
DCONF_FLAGS+="-v $HOME/.config/dconf/user:$HOME/.config/dconf/user:ro "

