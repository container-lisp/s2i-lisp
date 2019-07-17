#!/bin/bash

set -x

# -----------------------------------------------------------------------------
# Use Clair

sudo apt-get --yes remove postgresql\*
docker run -d --name db arminc/clair-db
sleep 15 # wait for db to come up
docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan
sleep 1
DOCKER_GATEWAY=$(docker network inspect bridge --format "{{range .IPAM.Config}}{{.Gateway}}{{end}}")
wget -qO clair-scanner https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64 && chmod +x clair-scanner
./clair-scanner --ip="$DOCKER_GATEWAY" $REPO

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
