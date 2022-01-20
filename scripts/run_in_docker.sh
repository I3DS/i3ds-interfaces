#!/bin/bash

# This script is meant to be run in a docker container with 
# the root i3ds-interfaces folder mounted as /src and
# the output folder mounted as /target


get_asn1_files()
{
    for file in $(find /src -maxdepth 2 -mindepth 1 -name "asn1.list");
    do
        subsystem=$(dirname "${file}")
        asnfiles=$(/bin/bash "${file}")
        for af in ${asnfiles}; do
            echo "${subsystem}/${af}"
        done
    done
}

ASN1_FILES="$(get_asn1_files)"

/usr/local/share/asn1scc/asn1scc --rename-policy 3 -c -uPER -o /target ${ASN1_FILES}
