#!/bin/bash

set -x

wget https://get.aquasec.com/microscanner
chmod +x microscanner

docker build . -f - <<EOF
FROM $REPO:latest
USER 0
ADD microscanner /
RUN /microscanner $AQUACODE -c
EOF

