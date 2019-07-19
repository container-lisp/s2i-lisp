#!/bin/bash

set -x

RLGL_POLICY=https://github.com/atgreen/test-policy.git

# -----------------------------------------------------------------------------
# Download and configure the rlgl client

wget -qO - https://rl.gl/cli/rlgl-linux-amd64.tgz | tar xvfz -
./rlgl/rlgl login http://rl.gl

ID=$(./rlgl/rlgl start)

# -----------------------------------------------------------------------------
# Use Clair

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
./rlgl/rlgl e --id=$ID --policy=$RLGL_POLICY clair-report.json

# Tests
for C in containerlisp/lisp-10-centos7 atgreen/moxielogic-builder-f25; do
    docker pull $C
    ./clair-scanner --ip="$DOCKER_GATEWAY" $C
    ./rlgl/rlgl e --id=$ID --policy=$RLGL_POLICY clair-report.json
done

# -----------------------------------------------------------------------------
# Use the Anchore's inline scanner.

curl -s https://ci-tools.anchore.io/inline_scan-v0.3.3 | bash -s -- -p -r $REPO


# -----------------------------------------------------------------------------
# Use Aqua Security's microscanner...

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

docker build . -f Dockerfile.scan
