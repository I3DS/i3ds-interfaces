#!/bin/bash
set -e
full_path=$(readlink -f "${0}")
ROOT="$(dirname $(dirname ${full_path}))"
GENPATH=${ROOT}/generated
NAMESPACE="i3ds_asn1"
test -d "${GENPATH}" || mkdir -p "${GENPATH}"
pushd "${ROOT}" > /dev/null

run_asn1 ()
{
    # ---------------------------------------------------------------------
    # Look for ASN.1 compiler, if not available, there's no point in
    # continuing..
    if [ -z "${ASN1CC}" ]; then
	# Did we get is as a parameter?
	if [ ! -z $1 ]; then
	    test -x $1 && ASN1CC=$1
	    echo "Got ASN.1 as arugment - ${ASN1CC}"
	else
	    ASN1CC=$(find "${HOME}" -executable -name asn1.exe -print -quit)
	    echo "Got ASN.1 from find - ${ASN1CC}"
	fi
    fi
    test -x "${ASN1CC}" || { echo "Cannot find executable for ASN.1 compiler, aborting."; exit 1; }

    # ---------------------------------------------------------------------
    # Find all relevant ASN.1 definitions
    ASN1_FILES=""
    for file in $(find . -maxdepth 2 -mindepth 1 -name "asn1.list");
    do
	subsystem=$(dirname "${file}")
	asnfiles=$(/bin/bash "${file}")
	for af in ${asnfiles}; do
	    ASN1_FILES="${ASN1_FILES} ${subsystem}/${af}"
	done
    done

    # ---------------------------------------------------------------------
    # basic sanity check, avoid forbidden words
    for f in ${ASN1_FILES}; do
	"${ROOT}"/scripts/find_illegal_asn1_field_names.py "${f}" || echo "${f} FAILED"
    done

    # ---------------------------------------------------------------------
    if [ -x "${ASN1CC}" ]; then
	# https://github.com/koalaman/shellcheck/wiki/SC2086 does not
	# like this, however, if placed in "", asn1.exe fails to find
	# the files.
	command mono "${ASN1CC}" -c -uPER -o "${GENPATH}" ${ASN1_FILES} && echo "Files Generated OK"
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
    for file in $(find . -maxdepth 1 -name "*.c");
    do
	end=$(cat -n "${file}" | tail -n1 | awk '{print $1}')
	sed -i "${end}i} // namespace ${NAMESPACE}" "${file}"
    done

    for file in $(find . -maxdepth 1 -name "*.h");
    do
	end=$(cat -n "${file}" | grep \#endif | tail -n1|awk '{print $1}')
        sed -i "${end}i} // namespace ${NAMESPACE}" "${file}"
    done

    # Find all defined constants in hpp, which may (or may not) be
    # exposed to to others which in turn may lead to define-collisions
    # Generate a list of all symbols defined:
    # for sym in $(grep "^\#define" -- *.h|cut -d '(' -f 1 | awk '{print $2}');
    for file in $(find . -maxdepth 1 -name "*.h")
    do
    	grep "^\#define" "${file}" | cut -d '(' -f 1 | awk '{print $2}'| while IFS= read -r sym
    	do
    	    replace_sym "${sym}"
    	done
    done

    rename "s/h$/hpp/" -- *.h
    rename "s/c$/cpp/" -- *.c

    mkdir -p include/"${NAMESPACE}"
    mkdir -p src/
    mv -- *.hpp include/"${NAMESPACE}"/.
    mv -- *.cpp src/

    popd > /dev/null
}

run_asn1 $1
process_generated

popd > /dev/null # ROOT
