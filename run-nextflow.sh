#!/bin/bash
#
#  Copyright 2013-2024, Seqera Labs
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#
# This script acts as a pass-through container entry point. Its main role
# is to create a user able to execute docker commands from the container
# connecting to the host docker socket at runtime.
#
# The invoker needs to pass the user ID using the variable NXF_USRMAP.
# When this variable is defined, it creates a new user in the container
# with such ID and adds it to the `docker` group, then assigns the docker
# socket file ownership to that user.
#
# Finally it switches the `nextflow` user using the `su` command and
# executes the original target command line.
#
# authors:
#  Paolo Di Tommaso
#  Emilio Palumbo
#

# Print a start message
echo "Starting entrypoint script..."

# Print the current working directory
echo "Current working directory: $(pwd)"

# List the contents of the current directory
echo "Contents of current directory:"
ls -la

# Print the contents of the /opt directory
echo "Contents of /opt directory:"
ls -la /opt

# Print environment variables
echo "Environment variables:"
env

# Print the Nextflow version
echo "Nextflow version:"
nextflow -version

# enable debugging
[[ "$NXF_DEBUG_ENTRY" ]] && set -x

# wrap cli args with single quote to avoid wildcard expansion
cli=''; for x in "$@"; do cli+="'$x' "; done

# the NXF_USRMAP hold the user ID in the host environment
if [[ "$NXF_USRMAP" ]]; then
# create a `nextflow` user with the provided ID
groupadd docker
useradd -u "$NXF_USRMAP" -G docker -s /bin/bash nextflow

# then change the docker socket ownership to `nextflow` user
# and change the $NXF_HOME ownership to `nextflow` user
chown nextflow /var/run/docker.sock
chown -R nextflow /.nextflow

# finally run the target command with `nextflow` user
su nextflow << EOF
[[ "$NXF_DEBUG_ENTRY" ]] && set -x
exec bash -c "$cli"
EOF

# otherwise just execute the command
else
exec bash -c "$cli"
fi