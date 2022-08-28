#!/bin/bash

# Update the LISP_BASE_BUILD_DATE environment variable in order to
# trigger a rebuild of the image.  Trigger this when there are CVE
# errata from the base OS image to be applied.

die() {
    echo "$@"
    exit 1
}

which grype &>/dev/null || die "This script requires grype."

VULNS=$(grype -q -o table --only-fixed quay.io/containerlisp/lisp-10-ubi8:latest | awk '{printf("%25s\t%s\n", $1, $5)}')

LISP_BASE_BUILD_DATE=$(date)
sed -i "s/LISP_BASE_BUILD_DATE=.*/LISP_BASE_BUILD_DATE=$LISP_BASE_BUILD_DATE/g" ../1.0/Dockerfile

echo "Adding git commit"
git add ../1.0/Dockerfile && git commit -m "Fix vulnerabilities in the base image.

$VULNS"




