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
# This script sets some additional environment configuration for docker run
# based on the version of pulseaudio being run by the host as described in
# section 4.4.1 of the book.
# 
# For pulseaudio versions 7 to 9 there is a bug whereby shm files get "cleaned
# up" incorrectly in containers, so force those versions to disable shared
# memory. Pulseaudio 10 enables memfd by default, which apparently fixes this.
# See https://bugs.freedesktop.org/show_bug.cgi?id=92141
################################################################################

PULSE_VERSION=$(pulseaudio --version | sed 's/[^0-9.]*\([0-9]*\).*/\1/')
if ([[ $PULSE_VERSION -gt 6 ]] && [[ $PULSE_VERSION -lt 10 ]]); then
    PULSE_FLAGS="-e PULSE_CLIENTCONFIG=/etc/pulse/client-noshm.conf"
fi

# Populate the PULSEAUDIO_FLAGS variable as a short cut instead of
# having to set the environment and volume flags individually.
PULSEAUDIO_FLAGS="-e PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native "
PULSEAUDIO_FLAGS+="-v $XDG_RUNTIME_DIR/pulse:$XDG_RUNTIME_DIR/pulse:ro "
PULSEAUDIO_FLAGS+="-v $HOME/.config/pulse/cookie:$HOME/.config/pulse/cookie:ro "
PULSEAUDIO_FLAGS+="$PULSE_FLAGS "
