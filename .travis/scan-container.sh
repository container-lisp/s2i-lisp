#!/bin/bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

# enable !! command completion
set -o history -o histexpand

RLGL_POLICY=https://github.com/atgreen/test-policy.git

# -----------------------------------------------------------------------------
# Configure rlgl

# Download and extract the client
wget -qO - http://rl.gl/cli/rlgl-linux-amd64.tgz | \
    tar --strip-components=2 -xvzf - ./rlgl/rlgl
exit_on_error $? !!

# Log into the server
./rlgl login http://rl.gl
exit_on_error $? !!

# Generate a player ID for use during report evaluation
ID=$(./rlgl start)
exit_on_error $? !!

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
exit_on_error $? !!

./clair-scanner --ip="$DOCKER_GATEWAY" -r clair-report.json $REPO
exit_on_error $? !!

./rlgl e --id=$ID --policy=$RLGL_POLICY clair-report.json
exit_on_error $? !!

# -----------------------------------------------------------------------------
# Use the Anchore's inline scanner.

curl -s https://ci-tools.anchore.io/inline_scan-v0.4.1 | bash -s -- -p -r $REPO
if test -f anchore-reports/${REPO}*-vuln.json; then
    ./rlgl e --id=$ID --policy=$RLGL_POLICY anchore-reports/${REPO}*-vuln.json
    exit_on_error $? !!
fi

# Test to see output of bad container...
curl -s https://ci-tools.anchore.io/inline_scan-v0.4.1 | bash -s -- -p -r containerlisp/lisp-10-centos7
if test -f anchore-reports/lisp-10-centos7_latest-vuln.json; then
    ./rlgl e --id=$ID --policy=$RLGL_POLICY anchore-reports/lisp-10-centos7_latest-vuln.json
    exit_on_error $? !!
fi

# -----------------------------------------------------------------------------
# Use Aqua Security's microscanner...

if ! test -f microscanner; then
  wget https://get.aquasec.com/microscanner
  exit_on_error $? !!
  chmod +x microscanner
fi  

cat > Dockerfile.scan <<EOF
FROM $REPO
USER 0
ADD microscanner /
RUN /microscanner $AQUACODE -c
EOF

docker build . -f Dockerfile.scan
exit_on_error $? !!

# Run rlgl here once Aqua has fixed their ubi8 scanner

# -----------------------------------------------------------------------------

# Summarize scans

./rlgl log --id=$ID
exit_on_error $? !!
