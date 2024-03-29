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
if [ "${1}" == "docker" ]; then
    test -x $(which docker)   || { echo -ne "\nERROR docker not available, cannot continue\n\n";   exit 1; }
else
    test -x ${MONO}   || { echo -ne "\nERROR ${MONO} not available, cannot continue\n\n";   exit 1; }
fi
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

docker_run_asn1()
{
    # Get docker image
    docker pull ttsiodras/asn1scc@sha256:f0958e1b54ea43d1836d0f5b59a1457281a78d57cb1d2d6b2188b64d80082260

    ASN1_FILES="$(get_asn1_files)"

    # basic sanity check, avoid forbidden words
    for f in ${ASN1_FILES}; do
    "${ROOT}"/scripts/find_illegal_asn1_field_names.py "${f}" || echo "${f} FAILED"
    done

    # Nuke all files in generated/
    rm -rf ${GENPATH}/*

    docker run --user $(id -u ${USER}):$(id -g ${USER}) -v ${GENPATH}:/target -v ${ROOT}:/src -v ${ROOT}/scripts:/scripts ttsiodras/asn1scc bash -c "/scripts/run_in_docker.sh"

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
	command ${MONO} "${ASN1CC}" \
		--rename-policy 3 \
		-c -uPER -o "${GENPATH}" ${ASN1_FILES} && echo "Files Generated OK"
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
	start=$(cat -n "${hf}" | grep -1 -E "extern(\ )*\"C\"(\ )*\{" | head -n1 | awk '{print $1}')
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

    # Find all enums defined, then scan down to see if there are
    # #defines for these (that ensures a stable namespace). These needs
    # to be prefixed swith "${NAMESPACE}::"
    for file in $(find . -maxdepth 1 -name "*.h")
    do
	# Get linenumber of "please use" and
	for linenum in $(grep -n "please use the following macros" ${file}|awk '{print $1}'|cut -d ':' -f1);
	do
	    # find closing line and inject namespace in token
	    end=$(cat -n ${file} | tail -n+${linenum} | awk '{print NF " " $1}'|grep -m 1 ^1\ |awk '{print $2}')
	    for ln in $(${SEQ} ${linenum} ${end}); do
		active_line=$(tail -n+${ln} ${file}|head -n1)
		sed -i "${ln}s/#define \(.*\) \(.*\)/#define ns\1 ${NAMESPACE}::\2/" ${file}
	    done
	done
    done
    # Find all defined constants in hpp, which may (or may not) be
    # exposed to to others which in turn may lead to define-collisions
    # Generate a list of all symbols defined:
    # for sym in $(grep "^\#define" -- *.h|cut -d '(' -f 1 | awk '{print $2}');
    for file in $(find . -maxdepth 1 -name "*.h")
    do
	# Note: if symbol is prefixed with ${NAMSESPACE}::", ignore line.
    	grep "^\#define" "${file}" | grep -v "${NAMESPACE}::" | cut -d '(' -f 1 | awk '{print $2}'| while IFS= read -r sym
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

    # Have to include standard C header to avoid error with fast_int
    sed -i 's/cstdint/stdint.h/'  include/"${NAMESPACE}"/asn1crt.hpp
    sed -i 's/cinttypes/inttypes.h/' include/"${NAMESPACE}"/asn1crt.hpp

    popd > /dev/null
}

echo "Using ${0} to hand parsing of ASN.1 files over to asn1scc"
if [ "${1}" == "docker" ]; then
    echo "Using asn1scc from docker image"
    docker_run_asn1
else
    echo "Using locally installed asn1scc"
    run_asn1 "${1}"
fi
echo "Using ${0} to modify generated code"
process_generated

popd > /dev/null # ROOT
