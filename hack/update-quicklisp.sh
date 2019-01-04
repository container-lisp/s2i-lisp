#!/bin/bash

# Update URL to point to the up-to-date quicklisp dist in the
# install.lisp file and commit the changes to the repository. This
# script checks the quicklisp website to fetch the latest quicklisp
# dist URL.

INSTALL=../1.0/root/opt/app-root/install.lisp
QL="http://beta.quicklisp.org/dist/quicklisp.txt"

die() {
    echo "$@"
    exit 1
}

which wget &>/dev/null || die "This script requires wget."

[ -f "$INSTALL" ] || die "File $INSTALL does not exist."

URL_OLD=$(grep "defvar \*dist-url\*" "$INSTALL" | \
            perl -n -e 'm!(https?://.*/distinfo.txt)!; print "$1"')
[ -n "$URL_OLD" ] || die "Could not determine current ql-dist version in ${INSTALL}!"

URL_NEW=$(wget -O - -q "$QL" | grep ^canonical-distinfo-url: | awk '{print $2}')
[ -n "$URL_NEW" ] || die "Could not determine up-to-date quicklisp dist from ${QL}!"

VERSION=$(echo "$URL_NEW" | perl -ne 'm/(\d{4}-\d{2}-\d{2})/; print "$1"')
[ -n "$VERSION" ] || die "Could not determine version string from URL ${URL_NEW}!"

if [ "$URL_OLD" == "$URL_NEW" ]; then
    echo "Quicklisp dist is up-to-date ($URL_NEW)."
    exit 0
fi

echo "Replacing $URL_OLD with $URL_NEW in $INSTALL..."
sed -i -e "s!${URL_OLD}!${URL_NEW}!" "$INSTALL" || \
    die "Error updating quicklisp dist URL."

git add "$INSTALL" && git commit -m "Bump quicklisp dist version to $VERSION"
