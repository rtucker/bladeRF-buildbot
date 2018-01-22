#!/bin/bash

[ -z "$WORKDIR" ] && WORKDIR=/srv/bladerf

# Read in our library of useful functions
. ${BINDIR}/autobuild_inc.sh

# Update repo and get the latest revision.
# Or, if there's a revision on the command line, use that.
update_master_repo ${WORKDIR}/bladeRF
get_commit_id ${WORKDIR}/bladeRF $1
REVID=$_result
[ -z "$REVID" ] && echo "Couldn't get latest revision ID" && exit 1

# Make a build dir, if it doesn't exist...
mkdir -p ${WORKDIR}/builds/
REVBUILDS_DIR=${WORKDIR}/builds/${REVID}
[ -d "${REVBUILDS_DIR}" ] && echo "Already built rev $REVID" && exit 0
mkdir -p ${REVBUILDS_DIR}
cd ${REVBUILDS_DIR}
mkdir artifacts

# Redirect stdout and stderr to a named pipe running tee, so that the
# output from this build session is logged.
exec > >(tee ${REVBUILDS_DIR}/buildlog.txt)
exec 2>&1

echo "autobuild.sh starting"
echo "Script date:  $(stat --format=%y ${BINDIR}/autobuild.sh)"
echo "Library date: $(stat --format=%y ${BINDIR}/autobuild_inc.sh)"
echo "Reference:    ${REVISION}"
echo "Revision ID:  ${REVID}"
echo "Builds root:  ${REVBUILDS_DIR}"
echo "Time:         $(date)"
echo "Build host:   $(hostname)"
echo "Kernel:       $(cat /proc/version)"
echo "Distribution: $(lsb_release -ds)"
echo "Uptime:       $(uptime)"
echo ""
echo "Quartus Version:"
${QUARTUS_PATH}/nios2eds/nios2_command_shell.sh ${QUARTUS_PATH}/quartus/bin/quartus_sh --version
echo ""
echo "Disk summary:"
df -h .
echo ""
echo "Memory summary:"
free -m
echo ""

# Iterate through all possibilities and build FPGAs
for revision in hosted atsc_tx #qpsk_tx fsk_bridge headless
do
    for size in 40 115
    do
        echo "**********"
        echo "Building: $REVID $revision $size"
        echo "**********"

        clone_build_dir ${WORKDIR}/bladeRF ${REVBUILDS_DIR} ${revision}x${size} ${REVID}
        cd ${REVBUILDS_DIR}/${revision}x${size}/hdl/quartus
        build_bladerf_fpga ${revision} ${size}

        if [ -z "$_result" ] || [ ! -f "$_result" ]
        then
            echo "Build failed ($revision $size), oh no.  x_x"
            echo "_result was ${_result}"
            touch ${WORKDIR}/builds/${REVID}/artifacts/${revision}x${size}.FAILED
        else
            cp $_result ${WORKDIR}/builds/${REVID}/artifacts/
        fi
    done
done

# Build two firmware images: one with debug, one without
for debug_image in true false
do
    if [ "$debug_image" == "true" ]
    then
        image_type="Debug"
        build_dir="firmware_debug"
    else
        image_type="Release"
        build_dir="firmware"
    fi

    echo "**********"
    echo "Building: $REVID $image_type"
    echo "**********"

    clone_build_dir ${WORKDIR}/bladeRF ${REVBUILDS_DIR} ${build_dir} ${REVID}

    cd ${REVBUILDS_DIR}/${build_dir}
    prep_build ${image_type} ${REVID::7}
    build_bladerf_firmware ${image_type}

    if [ -z "$_result" ] || [ ! -f "$_result" ]
    then
        echo "Build failed ($image_type), oh no!!"
        echo "_result was ${_result}"
        touch ${WORKDIR}/builds/${REVID}/artifacts/${build_dir}.FAILED
    else
        cp $_result ${WORKDIR}/builds/${REVID}/artifacts/${build_dir}.img
    fi
done

# Build documentation
if true
then
    echo "**********"
    echo "Building: ${REVID} doxygen for libbladeRF"
    echo "**********"

    build_dir="libbladeRF_doxygen"

    clone_build_dir ${WORKDIR}/bladeRF ${REVBUILDS_DIR} ${build_dir} ${REVID}

    cd ${REVBUILDS_DIR}/${build_dir}
    prep_build Release ${REVID::7}
    build_bladerf_doxygen

    if [ -z "$_result" ] || [ ! -d "$_result" ]
    then
        echo "Build failed (doxygen), oh no!!"
        echo "_result was ${_result}"
        touch ${WORKDIR}/builds/${REVID}/artifacts/${build_dir}.FAILED
    else
        mv $_result ${REVBUILDS_DIR}/artifacts/${build_dir}
    fi
fi

# Run clang static analysis
if true
then
    echo "**********"
    echo "Running: ${REVID} scan-build for host"
    echo "**********"

    build_dir="host_clangscan"

    clone_build_dir ${WORKDIR}/bladeRF ${REVBUILDS_DIR} ${build_dir} ${REVID}

    cd ${REVBUILDS_DIR}/${build_dir}
    prep_build Release ${REVID::7}
    cd host
    run_bladerf_clangscan

    if [ -z "$_result" ] || [ ! -d "$_result" ]
    then
        echo "Build failed (host_clangscan), oh no!!"
        echo "_result was ${_result}"
        touch ${WORKDIR}/builds/${REVID}/artifacts/${build_dir}.FAILED
    else
        mv $_result ${REVBUILDS_DIR}/artifacts/${build_dir}
    fi
fi

# Build Coverity tarball
if [ -n "${COVERITY_PATH}" ]
then
    echo "**********"
    echo "Building: ${REVID} coverity"
    echo "**********"

    build_dir="coverity"

    clone_build_dir ${WORKDIR}/bladeRF ${REVBUILDS_DIR} ${build_dir} ${REVID}

    cd ${REVBUILDS_DIR}/${build_dir}
    prep_build Release ${REVID::7} -DBUILD_DOCUMENTATION=OFF
    build_coverity_tarball

    if [ -z "$_result" ] || [ ! -f "$_result" ]
    then
        echo "Build failed (coverity), oh no!!"
        echo "_result was ${_result}"
        touch ${WORKDIR}/builds/${REVID}/artifacts/${build_dir}.FAILED
    else
        cp $_result ${REVBUILDS_DIR}/artifacts/${build_dir}
    fi
fi

# Point a 'latest' symlink into the right place, if we meet the requirements
if [ -z "$1" ]
then
    consider_latest_symlink ${WORKDIR}/builds/ ${REVID}
else
    echo "Forced build -- did not update latest/ symlink"
fi

echo "autobuild.sh complete"
echo "Time:         $(date)"
echo "Uptime:       $(uptime)"
echo ""
echo "Disk summary:"
df -h .
echo ""
echo "Memory summary:"
free -m
echo ""
echo "EOM"
