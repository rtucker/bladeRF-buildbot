#!/usr/bin/env bash

function usage() {
    echo "usage: $0 <build id> <commit id> <fpga revision> <fpga size>"
    exit 0
}

[ -z "${WORKDIR}" ]     && echo "WORKDIR var not set"   && exit 1
[ -z "${BINDIR}" ]      && echo "BINDIR var not set"    && exit 1

[ -z "$4" ] && usage

BUILD_ID=$1
COMMIT_ID=$2
FPGA_REV=$3
FPGA_SIZE=$4

# Read in our library of useful functions
. ${BINDIR}/autobuild_inc.sh

# Update repo and get the latest revision.
# Or, if there's a revision on the command line, use that.
update_master_repo ${WORKDIR}/bladeRF
get_commit_id ${WORKDIR}/bladeRF ${COMMIT_ID}
REVID=$_result
[ -z "$REVID" ] && echo "Couldn't get latest revision ID" && exit 1

# Make a build dir, if it doesn't exist...
mkdir -p ${WORKDIR}/builds/
REVBUILDS_DIR=${WORKDIR}/builds/${BUILD_ID}/${REVID}
ARTIFACTS_DIR=${WORKDIR}/builds/${BUILD_ID}/${REVID}/artifacts
[ -d "${REVBUILDS_DIR}" ] && echo "Already built ${BUILD_ID}/${REVID}" && exit 0
mkdir -p ${REVBUILDS_DIR}
mkdir -p ${ARTIFACTS_DIR}

cd ${REVBUILDS_DIR}

# Redirect stdout and stderr to a named pipe running tee, so that the
# output from this build session is logged.
exec > >(tee ${REVBUILDS_DIR}/buildlog.txt)
exec 2>&1

echo "autobuild.sh starting"
echo "Script date:  $(stat --format=%y ${BINDIR}/autobuild.sh)"
echo "Library date: $(stat --format=%y ${BINDIR}/autobuild_inc.sh)"
echo "Build ID:     ${BUILD_ID}"
echo "Commit ID:    ${COMMIT_ID}"
echo "Revision ID:  ${REVID}"
echo "Builds root:  ${REVBUILDS_DIR}"
echo "FPGA Project: ${FPGA_REV}"
echo "FPGA Size:    ${FPGA_SIZE}"
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

echo "**********"
echo "Building: $REVID $FPGA_REV $FPGA_SIZE"
echo "**********"

clone_build_dir ${WORKDIR}/bladeRF ${REVBUILDS_DIR} ${FPGA_REV}x${FPGA_SIZE} ${REVID}
cd ${REVBUILDS_DIR}/${FPGA_REV}x${FPGA_SIZE}/hdl/quartus
build_bladerf_fpga ${FPGA_REV} ${FPGA_SIZE}

if [ -z "$_result" ] || [ ! -f "$_result" ]
then
    echo "xxxxxxxxxx"
    echo "FAILED: $REVID $FPGA_REV $FPGA_SIZE"
    echo "xxxxxxxxxx"
    echo "_result was ${_result}"

    touch ${ARTIFACTS_DIR}/${FPGA_REV}x${FPGA_SIZE}.FAILED
else
    cp $_result ${ARTIFACTS_DIR}/
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
