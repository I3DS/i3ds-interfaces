#!/bin/bash
set -e

full_path=$(readlink -f "${0}")
ROOT="$(dirname $(dirname ${full_path}))"
BUILDPATH=${ROOT}/build
INSTALLPATH=${BUILDPATH}/tmp
NAMESPACE="i3ds_asn1"

pushd "${ROOT}" > /dev/null

create_bundle ()
{
    tarname="${1}"
    base_tar=$(basename "${tarname}")

    pushd "${BUILDPATH}" > /dev/null
    make install > /dev/null
    pushd "${INSTALLPATH}" > /dev/null
    tar cf "${tarname}" . --owner=root --group=root &>/dev/null
    echo "   ${base_tar} created"
    popd > /dev/null #install
    popd > /dev/null
}

gen_archive_name()
{
    dirty=$(test -z "$(git status -s|grep ^\ M)" || echo "-dirty")
    hash="$(git log --pretty=oneline -n1|awk '{$hash=substr($1, 0, 12); print $1}')"
    name="${NAMESPACE}-$(date "+%Y-%m")-${hash}${dirty}.tar"
    echo "${ROOT}/${name}"
}

create_bundle "$(gen_archive_name)"

popd > /dev/null
