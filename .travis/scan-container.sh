#!/bin/bash

set -x

# -----------------------------------------------------------------------------
# Use Clair

sudo apt-get --yes remove postgresql\*
wget https://raw.githubusercontent.com/singularityhub/stools/master/docker-compose.yml
docker-compose up -d clair-db
docker-compose up -d clair-scanner
sleep 3
docker exec -it clair-scanner sclair $REPO


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
