#!/bin/bash

# Find up-to-date SBCL version for x86-64 linux on sbcl.org and update
# Dockerfiles if necessary. It will check for the existence of the new
# remote file and add a git commit. Run the script from the path it
# resides in, or change FILES appropriately.

die() {
    echo "$@"
    exit 1
}

FILES=( ../1.0/Dockerfile ../1.0/Dockerfile.rhel7 )

which wget &>/dev/null || die "This script requires wget."

V_NEW=$(wget -q -O - "http://sbcl.org/platform-table.html" | \
            grep "tar.bz2?download" | head -1 | \
            perl -n -e 'm/sbcl-(\d+\.\d+\.\d+)-source.tar.bz2/; print "$1"' )
[ -n "$V_NEW" ] || die "Could not find new sbcl version on sbcl.org."

CHANGED=n

update_file() {
    local file="$1"
    local v_old=$(grep SBCL_VERSION= "$file" | \
                      perl -n -e 'm/=(\d+\.\d+\.\d+)/; print "$1"')
    [ -n "$v_old" ] || die "Could not find old sbcl version in $file!"

    if [ "$v_old" == "$V_NEW" ]; then
        echo "SBCL as specified in $file is already up-to-date."
        return 0
    fi
    CHANGED=y

    echo "Updating SBCL_VERSION in $file from $v_old to $V_NEW"
    sed -i -e "s/SBCL_VERSION=$v_old/SBCL_VERSION=$V_NEW/g" "$file" || \
        die "Error replacing version strings, please check manually!"

    DL_LINK=$(grep --only-matching "https://.*/sbcl-.*.tar.bz2" "$file" | \
           sed -e "s/\${SBCL_VERSION}/$V_NEW/g")
    echo "Checking for remote file existence at $DL_LINK..."
    wget -nv --method HEAD "$DL_LINK" || die "Failed to confirm remote file existence."
}

for f in "${FILES[@]}"; do
    echo "Updating file $f"
    update_file "$f"
done

if [ $CHANGED == y ]; then
    echo "Adding git commit"
    git add "${FILES[@]}" && git commit -m "Update SBCL to $V_NEW"
else
    echo "All files already up-to-date."
fi
