#!/bin/bash
set -x
# -----------------------------------------------------------------------------
# Copyright 2019  Anthony Green
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License. You may
# obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License.
#
# -----------------------------------------------------------------------------
# Scan our image, $REPO:latest, with multiple container scanners,
# checking for known vulnerabilities.  Use Red Light Green Light to
# evaluate the scan results against the policy specified in git at
# $RLGL_POLICY.  See https://github.com/atgreen/red-light-green-light
# for details.
# -----------------------------------------------------------------------------

# Experiment by scanning an old container image...
REPO=containerlisp/lisp-10-ubi8:20190711.62
docker pull containerlisp/lisp-10-ubi8:20190711.62

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Configure the rlgl cli.

# Download and extract the client
wget -qO - https://rl.gl/cli/rlgl-linux-amd64.tgz | \
    tar --strip-components=2 -xvzf - ./rlgl/rlgl

# Log into the server
./rlgl login https://rl.gl

# Generate a player ID for use during report evaluation
ID=$(./rlgl start)

# -----------------------------------------------------------------------------
# Use the Clair scanner...
# -----------------------------------------------------------------------------

# travis-ci comes with postgresql on, which clashes with the postgresql we're
# about to fire up.
sudo apt-get --yes remove postgresql\* > /dev/null 2>&1
docker run -d --name db arminc/clair-db
sleep 15 # wait for db to come up
docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan
sleep 1
DOCKER_GATEWAY=$(docker network inspect bridge --format "{{range .IPAM.Config}}{{.Gateway}}{{end}}")

wget -qO clair-scanner https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64 && chmod +x clair-scanner

./clair-scanner --ip="$DOCKER_GATEWAY" -r clair-report.json $REPO
./rlgl e --id=$ID --policy=$RLGL_POLICY clair-report.json

# -----------------------------------------------------------------------------
# Use Anchore's inline scanner...
# -----------------------------------------------------------------------------

curl -s https://ci-tools.anchore.io/inline_scan-v0.4.1 | bash -s -- -t 3300 -r $REPO
ls -lRt
if test -f anchore-reports/*-vuln.json; then 
    ./rlgl e --id=$ID --policy=$RLGL_POLICY anchore-reports/*-vuln.json
fi

# -----------------------------------------------------------------------------
# Use Aqua Security's microscanner...
# -----------------------------------------------------------------------------

if [[ -z "${AQUACODE}" ]]; then
    echo "Skipping AquaSecurity Scan.  Missing AQUACODE environment variable."
else    
    if ! test -f microscanner; then
	wget https://get.aquasec.com/microscanner
	chmod +x microscanner
    fi  

    cat > Dockerfile.scan <<EOF
FROM $REPO
USER 0
ADD microscanner /
RUN /microscanner $AQUACODE -c
EOF

    # FIXME: this fails because Aqua can't handle ubi8 images yet
    docker build . -f Dockerfile.scan || true

    # TODO: Run rlgl here once Aqua has fixed their ubi8 scanner
fi

# -----------------------------------------------------------------------------
# Summarize scans
# -----------------------------------------------------------------------------

./rlgl log --id=$ID

echo All scans pass.
