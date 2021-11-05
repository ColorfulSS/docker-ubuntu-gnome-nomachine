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
# The D-bus session bus is used by many applications, and GNOME applications in
# particular don't behave especially well without connecting to a session bus,
# as things like dconf won't work, which breaks application config. settings
#
# On a desktop environment connecting is usually fairly straightforward as D-bus
# will be running and DBUS_SESSION_BUS_ADDRESS will be set, but when running
# remote applications, e.g. over ssh, D-bus won't usually be running for that
# remote session.
#
# The script launches a D-bus session bus instance for the ssh client connection
# It uses ${SSH_CLIENT//[. ]/} as a key which concatenates the IP address and
# port of the client, so should be unique for each connection. The script checks
# if a key file for the connection exists and if not it launches D-bus and
# writes a key file to $XDG_RUNTIME_DIR/ssh-dbus containing the address.
# 
# Note: This script needs to be run before docker-remote-xauth.sh because
# dbus-launch uses the DISPLAY environment variable, which gets clobbered
# by docker-remote-xauth.sh to point to 172.17.0.1, which causes dbus-launch
# to fail to authenticate. In practice we don't actually need this D-bus to
# connect to the X server, but the error message is annoying.
# This script also needs to run before docker-dbus-all.sh as that script needs
# the correct DBUS_SESSION_BUS_ADDRESS to be set.
#
# Another issue is that on some systems DBUS_SESSION_BUS_ADDRESS seems to get
# set to $XDG_RUNTIME_DIR/bus

# "randomly" (and incorrectly) set to $XDG_RUNTIME_DIR/bus when doing ssh
# even though a normal desktop session might be an abstract socket and although
# DBUS_SESSION_BUS_ADDRESS might be getting set there is no bus instance.
# I've no idea what causes that but the UNIX_SOCKET_DIR variable at the start
# checks for the presence of that directory and if it is populated. If so
# then it's likely a valid DBUS_SESSION_BUS_ADDRESS, if not then it is
# being set incorrectly and we ignore it and launch our own D-bus instance.
################################################################################

CLIENT_KEY=${SSH_CLIENT% *}
#echo "CLIENT_KEY: $CLIENT_KEY"

# If the application has been launched via ssh then launch a D-bus
# session if one doesn't already exist for the ssh session.
if [[ $CLIENT_KEY ]]; then

mkdir -p $XDG_RUNTIME_DIR/ssh-dbus

# First, reap any D-bus session bus instances that may
# belong to dead ssh sessions.

# Populate this with the established ssh connections.
# We will search it for the presence of the client keys
# in $XDG_RUNTIME_DIR/ssh-dbus, as any key files that
# exist in that directory that don't match established
# ssh connections are "dead" so any associated D-bus
# instance should be killed.
NETWORK_STATUS=$(ss -t | grep ssh)
#echo "NETWORK_STATUS:"
#echo $NETWORK_STATUS

pushd $XDG_RUNTIME_DIR/ssh-dbus/ > /dev/null
    for f in *; do
        if [ -f $f ] && [[ $f != *.pid ]]; then
            if ! [[ $NETWORK_STATUS == *"$f"* ]]; then
                PID=$(cat ${f}.pid)
                echo "Session $f is closed, killing D-bus PID=$PID"
                kill -9 $PID
                rm $f
                rm ${f}.pid
            fi
        fi
    done
popd > /dev/null


# Replace the space with a :
CLIENT_KEY=${CLIENT_KEY// /:}
#echo "CLIENT_KEY: $CLIENT_KEY"

KEY_FILE=$XDG_RUNTIME_DIR/ssh-dbus/$CLIENT_KEY
#echo "KEY_FILE: $KEY_FILE"

if [ -f $KEY_FILE ]; then
    # Read KEY_FILE to get DBUS_SESSION_BUS_ADDRESS
    DBUS_SESSION_BUS_ADDRESS=$(cat $KEY_FILE)
    DBUS_SESSION_BUS_PID=$(cat $KEY_FILE.pid)
else
    echo "Launching D-bus"
    eval $(dbus-launch)

    # Write DBUS_SESSION_BUS_ADDRESS to KEY_FILE
    echo $DBUS_SESSION_BUS_ADDRESS > $KEY_FILE
    echo $DBUS_SESSION_BUS_PID > $KEY_FILE.pid
fi
fi

#echo "DBUS_SESSION_BUS_ADDRESS:$DBUS_SESSION_BUS_ADDRESS"
#echo "DBUS_SESSION_BUS_PID: $DBUS_SESSION_BUS_PID"

