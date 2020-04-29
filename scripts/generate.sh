#!/bin/bash
set -e
full_path=$(readlink -f "${0}")
ROOT="$(dirname $(dirname ${full_path}))"
GENPATH=${ROOT}/generated
NAMESPACE="i3ds_asn1"
test -d "${GENPATH}" || mkdir -p "${GENPATH}"
pushd "${ROOT}" > /dev/null


# Test for required binaries (better to fail early)
RENAME=/usr/bin/rename
MONO=/usr/bin/mono
SEQ=/usr/bin/seq
BC=/usr/bin/bc
test -x ${RENAME} || { echo -ne "\nERROR ${RENAME} not available, cannot continue\n\n"; exit 1; }
test -x ${MONO}   || { echo -ne "\nERROR ${MONO} not available, cannot continue\n\n";   exit 1; }
test -x ${SEW}    || { echo -ne "\nERROR ${SEQ} not available, cannot continue\n\n";    exit 1; }
test -x ${BC}     || { echo -ne "\nERROR ${BC} not available, cannot continue\n\n";     exit 1; }

get_asn1_files()
{
    for file in $(find . -maxdepth 2 -mindepth 1 -name "asn1.list");
    do
	subsystem=$(dirname "${file}")
	asnfiles=$(/bin/bash "${file}")
	for af in ${asnfiles}; do
	    echo "${subsystem}/${af}"
	done
    done
}

run_asn1 ()
{
    # ---------------------------------------------------------------------
    # Look for ASN.1 compiler, if not available, there's no point in
    # continuing..
    if [ -z "${ASN1CC}" ]; then
	# Did we get is as a parameter?
	if [ ! -z "${1}" ]; then
	    test -x "${1}" && ASN1CC=$1
	    echo "Got ASN.1 as arugment - ${ASN1CC}"
	else
	    ASN1CC=$(find "${HOME}" -executable -name asn1.exe -print -quit)
	    echo "Got ASN.1 from find - ${ASN1CC}"
	fi
    fi
    test -x "${ASN1CC}" || { echo "Cannot find executable for ASN.1 compiler, aborting."; exit 1; }

    # ---------------------------------------------------------------------
    # Find all relevant ASN.1 definitions
    ASN1_FILES="$(get_asn1_files)"

    # ---------------------------------------------------------------------
    # basic sanity check, avoid forbidden words
    for f in ${ASN1_FILES}; do
	"${ROOT}"/scripts/find_illegal_asn1_field_names.py "${f}" || echo "${f} FAILED"
    done

    # Nuke all files in generated/
    rm -rf ${GENPATH}/*

    # ---------------------------------------------------------------------
    if [ -x "${ASN1CC}" ]; then
	# https://github.com/koalaman/shellcheck/wiki/SC2086 does not
	# like this, however, if placed in "", asn1.exe fails to find
	# the files.
	command ${MONO} "${ASN1CC}" -c -uPER -o "${GENPATH}" ${ASN1_FILES} && echo "Files Generated OK"
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
    # Somewhat clumsy way of finding the name of all h-files generated
    # from our asn.1 definitions:
    for asn in $(get_asn1_files); do
	ownfiles="${ownfiles} $(basename ${asn%.asn}.h)"
    done

    pushd "${GENPATH}" > /dev/null
    H_FILES=$(ls -- *.h)
    C_FILES=$(ls -- *.c)

    # For each file, match on our h-files and change to proper
    # includepath and rename to hpp
    for f in *.[ch]; do
    	for hf in ${H_FILES}; do
    	    if grep -q "\"${hf}\"" "${f}"; then
    		sed -i "s/#include\ \"${hf}\"/#include\ <${NAMESPACE}\/${hf}pp>/g" "${f}"
    	    fi
    	done
    done

    # Wrap each code in each C-file in proper namespace
    for f in ${C_FILES}; do
    	start=$(cat -n "${f}" |grep \#include|tail -n1|awk '{print $1}')
    	start=$((start+1))
    	sed -i "${start}inamespace ${NAMESPACE} {" "${f}"

    	end=$(cat -n "${f}" | tail -n1 | awk '{print $1}')
    	sed -i "${end}i} // namespace ${NAMESPACE}" "${f}"
    done


    for hf in ${H_FILES}; do
    	# we are moving this to cpp, so we don't need the ifdef __cplusplus-thing
	# The pattern is consistent, 3 lines
	# #ifdef  __cplusplus
	# extern "C" {
	# #endif

	# Note, asn1crt.hpp is doing extra stuff in this block, so we
	# need to inject namespace at a slightly different place
	if [[ ${hf} == "asn1crt.h" ]]; then
	    #endif	/* __cplusplus */
	    start=$(cat -n "${hf}" | grep -E "\#endif.*__cplusplus" | head -n1 | awk '{print $1}')
	    start=$((start+1))
	else
	    start=$(cat -n "${hf}" | grep -1 -E "extern(\ )*\"C\"(\ )*\{" | head -n1 | awk '{print $1}')
	fi
	sed -i "${start}inamespace ${NAMESPACE} {" "${hf}"
	# if we are in our own generated files, we drop __cplusplus stuff
	if [[ ${ownfiles} == *${hf}* ]]; then
	    start=$((start+1))
	    for _ in $(${SEQ} 3); do
		sed -i "${start}d" "${hf}"
	    done

	    # ok, need to find the closing __cplusplus and enclosing
	    # endif, these have an extra newline on occasion
	    # FIXME
	    closing_start=$(cat -n "${hf}" | grep -E "#ifdef(\ )*__cplusplus" | tail -n1| awk '{print $1}')
	    end=$(cat -n "${hf}" | grep -1 -E "\#endif" | tail -n1 | awk '{print $1}')
	    closing_end=$(cat -n "${hf}" | sed -n "${closing_start},${end}p" | grep "\#endif" | head -n1 | awk '{print $1}')
	    to_drop=$(echo "${closing_end} - ${closing_start} + 1" | ${BC})
	    for _ in $(${SEQ} "${to_drop}"); do
		sed -i "${closing_start}d" "${hf}"
	    done
	fi

	# inset enclosing } for namespace, this should be just before
	# the last #endif (headerguard)
	end=$(cat -n "${hf}" | grep -1 -E "\#endif" | tail -n1 | awk '{print $1}')
	sed -i "${end}i} // namespace ${NAMESPACE}" "${hf}"
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

    ${RENAME} "s/h$/hpp/" -- *.h
    ${RENAME} "s/c$/cpp/" -- *.c

    mkdir -p include/"${NAMESPACE}"
    mkdir -p src/
    mv -- *.hpp include/"${NAMESPACE}"/.
    mv -- *.cpp src/

    popd > /dev/null
}

run_asn1 "${1}"
process_generated

popd > /dev/null # ROOT
