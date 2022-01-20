#! /bin/bash
set -e

full_path=$(readlink -f "${0}")
ROOT="$(dirname $(dirname ${full_path}))"

BUILDPATH=${ROOT}/build
INSTALLPATH=${BUILDPATH}/tmp

pushd "${ROOT}" > /dev/null

BUILDPATH="${ROOT}/build"
INSTALLPATH="${BUILDPATH}/tmp"

test -d "${BUILDPATH}" || mkdir -pv "${BUILDPATH}"
test -d "${INSTALLPATH}" || mkdir -pv "${INSTALLPATH}"

pushd "${BUILDPATH}" > /dev/null
cmake -DCMAKE_INSTALL_PREFIX="${INSTALLPATH}" \
      -DCMAKE_INSTALL_INCLUDEDIR="${INSTALLPATH}" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_EMBEDDED=OFF \
      -DBUILD_DEBUG=ON \
      -DBUILD_ASN1CC="docker" \
      -DCMAKE_INSTALL_INCLUDEDIR=include \
      ..
make VERBOSE=1 -j8
popd > /dev/null
popd > /dev/null

./scripts/gen_archive.sh
