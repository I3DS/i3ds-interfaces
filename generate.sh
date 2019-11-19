#! /bin/bash
set -e

full_path=$(realpath "${0}")
ROOT=$(dirname "${full_path}")
pushd "${ROOT}" > /dev/null

GENPATH=${ROOT}/generated
BUILDPATH=${ROOT}/build
INSTALLPATH=${BUILDPATH}/tmp
NAMESPACE="i3ds_asn1"

cleanup ()
{
    # ---------------------------------------------------------------------
    # Make sure we get a clena build each time
    test -d "${GENPATH}" && rm -rf "${GENPATH}"
    mkdir -p "${GENPATH}"

    test -d "${BUILDPATH}" && rm -rf "${BUILDPATH}"
    mkdir -p "${BUILDPATH}"
}

run_asn1 ()
{
    # ---------------------------------------------------------------------
    # Find all relevant ASN.1 definitions
    ASN1_FILES=""
    while IFS= read -r -d '' file
    do
	subsystem=$(dirname "${file}")
	asnfiles=$(/bin/bash "${file}")
	for af in ${asnfiles}; do
	    ASN1_FILES="${ASN1_FILES} ${subsystem}/${af}"
	done
    done < <(find . -maxdepth 2 -mindepth 1 -name "asn1.list" -print0)

    # ---------------------------------------------------------------------
    # basic sanity check, avoid forbidden words
    for f in ${ASN1_FILES}; do
	"${ROOT}"/find_illegal_asn1_field_names.py "${f}" || echo "${f} FAILED"
    done

    # ---------------------------------------------------------------------
    if [ -z "$ASN1CC" ]; then
	ASN1CC=$(find "${HOME}" -executable -name asn1.exe -print -quit)
    fi

    if [ -x "${ASN1CC}" ]; then
	# https://github.com/koalaman/shellcheck/wiki/SC2086 does not
	# like this, however, if placed in "", asn1.exe fails to find
	# the files.
	command mono "${ASN1CC}" -c -uPER -o "${GENPATH}" ${ASN1_FILES}
    fi
}

replace_sym ()
{
    sym=$1
    if [ "${sym}" == "true" ] || \
    	   [ "${sym}" == "TRUE" ] || \
    	   [ "${sym}" == "false" ] || \
    	   [ "${sym}" == "FALSE" ] || \
    	   [ "${sym}" == "NULL" ]; then
    	echo "Not replacing ${sym}"
	return
    fi
    echo "${sym} -> ${NAMESPACE}_${sym}"
    sed -i "s/${sym}/${NAMESPACE}_${sym}/g" -- *
}

process_generated ()
{
    pushd "${GENPATH}" > /dev/null
    H_FILES=$(ls -- *.h)
    for f in *.[ch]; do
	# For each file, match on our h-files and change to proper
	# includepath and rename to hpp
	for hf in ${H_FILES}; do
	    if grep -q "\"${hf}\"" "${f}"; then
		sed -i "s/#include\ \"${hf}\"/#include\ <${NAMESPACE}\/${hf}pp>/g" "${f}"
	    fi
	done
	# include namespace tag, but only after the #includes
	# Get last line with inclue (1-indexed)
	num=$(cat -n "${f}" |grep \#include|tail -n1|awk '{print $1}')
	num=$((num+1))
	sed -i "${num}inamespace ${NAMESPACE} {" "${f}"
    done


    # Place closing namespace in different places in c and h
    while IFS= read -r -d '' file
    do
	end=$(cat -n "${file}" | tail -n1 | awk '{print $1}')
	sed -i "${end}i} // namespace ${NAMESPACE}" "${file}"
    done < <(find . -maxdepth 1 -name "*.c" -print0)

    while IFS= read -r -d '' file
    do
	end=$(cat -n "${file}" | grep \#endif | tail -n1|awk '{print $1}')
        sed -i "${end}i} // namespace ${NAMESPACE}" "${file}"
    done < <(find . -maxdepth 1 -name "*.h" -print0)

    # Find all defined constants in hpp, which may (or may not) be
    # exposed to to others which in turn may lead to define-collisions
    # Generate a list of all symbols defined:
    # for sym in $(grep "^\#define" -- *.h|cut -d '(' -f 1 | awk '{print $2}');
    while IFS= read -r -d '' file
    do
    	grep "^\#define" "${file}" | cut -d '(' -f 1 | awk '{print $2}'| while IFS= read -r sym
    	do
    	    replace_sym "${sym}"
    	done
    done < <(find . -maxdepth 1 -name "*.h" -print0)

    rename "s/h$/hpp/" -- *.h
    rename "s/c$/cpp/" -- *.c

    mkdir -p include/"${NAMESPACE}"
    mkdir -p src/
    mv -- *.hpp include/"${NAMESPACE}"/.
    mv -- *.cpp src/

    popd > /dev/null
}

run_cmake ()
{
    pushd "${BUILDPATH}" > /dev/null
    mkdir -p tmp
    cmake -DCMAKE_INSTALL_PREFIX="${INSTALLPATH}" \
	  -DCMAKE_INSTALL_INCLUDEDIR="${INSTALLPATH}" \
	  -DCMAKE_INSTALL_LIBDIR=lib \
	  -DBUILD_EMBEDDED=OFF \
	  -DBUILD_DEBUG=ON \
	  -DCMAKE_INSTALL_INCLUDEDIR=include \
	  ..
    make VERBOSE=1 -j8
    popd > /dev/null
}

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

# ---------------------------------------------------------------------
echo "0. Cleanup"
cleanup

# ---------------------------------------------------------------------
echo "1. Generate files from ASN.1 definitions."
run_asn1

# ---------------------------------------------------------------------
echo "2. ASN.1 Compilation done, processing for library compilation."
process_generated

# ---------------------------------------------------------------------
echo "3. Processing done, kicking cmake to create .so."
run_cmake

# ---------------------------------------------------------------------
echo "4. Compile done, creating install-bundle."
create_bundle "$(gen_archive_name)"

popd > /dev/null # ROOT
