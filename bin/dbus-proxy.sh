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
# This script is a simple proxy between a Unix domain socket with a filesystem
# path namespace and an abstract D-bus socket. It can be used when the
# socket specified in DBUS_SESSION_BUS_ADDRESS is of type unix:abstract
################################################################################

# Remove any /run/user/1000/bus socket that may be hanging around.
rm $XDG_RUNTIME_DIR/bus

# Run a proxy that listens on /run/user/1000/bus (or whatever the uid of the
# current user is) and proxies it to the abstract socket specified in
# DBUS_SESSION_BUS_ADDRESS.
# The RegEx looks for any number of non = characters ([^=]*) followed by = then
# matches and saves as many non-commas as it can find ( \([^,]\+\) ) followed by
# a comma and the rest of the line (,.*). This means it will replace everything
# up to and including the first = and after the first comma with whatever
# non-comma characters it finds after the first = on the line.
socat UNIX-LISTEN:$XDG_RUNTIME_DIR/bus,fork ABSTRACT-CONNECT:$(echo $DBUS_SESSION_BUS_ADDRESS | sed -e 's/[^=]*=\([^,]\+\),.*/\1/')
