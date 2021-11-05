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

# Check is pasuspender (and therefore pulseaudio) is present, if so then
# prefix with pasuspender to suspend pulseaudio for the duration of the test.
if test -f /usr/bin/pasuspender; then
    DOCKER_COMMAND="pasuspender -- "$DOCKER_COMMAND
fi

# Populate the JACK_FLAGS and JACKD_FLAGS variable as a short cut instead
# of having to set the environment and volume flags individually.
JACK_FLAGS="--ulimit rtprio=99 "
JACK_FLAGS+="--ulimit memlock=-1 "
JACK_FLAGS+="--ipc=host "

# For jackd we pass /dev/snd and add audio group to give access to ALSA
JACKD_FLAGS=$JACK_FLAGS
JACKD_FLAGS+="--device=/dev/snd "
JACKD_FLAGS+="--group-add $(cut -d: -f3 < <(getent group audio)) "


