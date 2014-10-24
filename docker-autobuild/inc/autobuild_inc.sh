# qpushd, qpopd: quiet alternatives to pushd, popd
function qpushd() {
    pushd $@ > /dev/null
}

function qpopd() {
    popd $@ > /dev/null
}

# update_master_repo: Updates our copy of the master git repo
# Args: path_to_repo_dir
function update_master_repo() {
    if [ -z "$1" ]; then
        echo "update_master_repo: missing path to repository"
        exit 1
    fi

    if [ -d "$1" ]; then
        qpushd $1
            git fetch --all
            git checkout origin/master
        qpopd
    else
        git clone https://github.com/Nuand/bladeRF.git $1
    fi
}

# get_commit_id: Echos the HEAD commit for the repo
# Args: repo_dir [revision]
function get_commit_id() {
    if [ -z "$1" ]; then
        echo "get_commit_id: missing directory"
        exit 1
    fi

    if [ -z "$2" ]; then
        _rev=${REVISION}
    else
        _rev=$2
    fi

    qpushd $1
        _result=$(git rev-list ${_rev} -n 1)
    qpopd
}

# clone_build_dir: Clones a build dir from the master
# Args: master_dir revbuilds_dir target_subdir revid
function clone_build_dir() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "clone_build_dir: missing args"
        exit 1
    fi

    _master_dir=$1
    _revbuilds_dir=$2
    _target_subdir=$3
    _revid=$4

    qpushd ${_revbuilds_dir}
        git clone ${_master_dir} ${_target_subdir}
        qpushd ${_target_subdir}
            git checkout ${_revid}
        qpopd
    qpopd
}

# prep_build: Prepares a build subdirectory within the source tree.
# args: [buildtype [gitrevision [cmake arguments ...]]]
function prep_build() {
    if [ -z "$1" ]; then
        _build_type="Release"
    else
        _build_type="$1"
        shift
    fi

    if [ -z "$1" ]; then
        _git_revision="unknown"
    else
        _git_revision="$1"
        shift
    fi

    # Hack CMakeLists as required
    #for dir in host fx3_firmware host/libraries/libbladeRF
    #do
    #    qpushd $dir
    #        _CMAKE_CLD=`pwd`           # remember where we are...
    #        sed --in-place=.bak --expression="s:\${CMAKE_CURRENT_LIST_DIR}:${_CMAKE_CLD}:g" \
    #                            --expression="s:cmake_minimum_required(VERSION 2.8.3):cmake_minimum_required(VERSION 2.8):g" \
    #                            --expression="s:include(GNUInstallDirs):\#include(GNUInstallDirs):g" \
    #                            --expression="s:cmake_minimum_required(VERSION 2.8.5):cmake_minimum_required(VERSION 2.8):g" \
    #                            CMakeLists.txt
    #    qpopd
    #done

    # We're running the Lunix here
    qpushd fx3_firmware
        # XXX: is the sed still necessary?
        sed 's/HOST_IS_WINDOWS := y/HOST_IS_WINDOWS := n/' make/toolchain.mk.sample > make/toolchain.mk
    qpopd

    # Create the build dir and run cmake
    mkdir build
    qpushd build
        cmake -DCMAKE_INSTALL_LIBDIR=lib \
              -DGIT_EXECUTABLE=/usr/bin/git \
              -DGIT_FOUND=True \
              -DCMAKE_BUILD_TYPE=${_build_type} \
              -DVERSION_INFO_OVERRIDE:STRING=git-${_git_revision}-buildomatic \
              -DBUILD_DOCUMENTATION=YES \
              -DENABLE_FX3_BUILD=ON $* \
              ../
    qpopd
}

# build_bladerf_fpga: Builds an FPGA image
# Args: revision size
# Returns the path of the output artifact, or nothing if it failed
function build_bladerf_fpga() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "build_bladerf_fpga: missing args"
        exit 1
    fi

    _revision=$1
    _size=$2

    ${QUARTUS_PATH}/nios2eds/nios2_command_shell.sh ./build_bladerf.sh -r $revision -s $size

    _result=$(ls ${revision}x${size}*/${revision}x${size}.rbf | head -1)
}

# build_bladerf_firmware: builds firmware for the fx3
# Optional arg: image_type, which can be Debug or something else
function build_bladerf_firmware() {
    qpushd build
        if [ "Debug" = "$1" ]; then
            DEBUG=yes make fx3_firmware
        else
            make fx3_firmware
        fi

        if [ -f "fx3_firmware/build/bladeRF.img" ]
        then
            _result=build/fx3_firmware/build/bladeRF.img
        else
            _result=""
        fi
    qpopd
}

# build_bladerf_doxygen: builds a doxygen tree for libbladeRF
function build_bladerf_doxygen()
{
    qpushd build
        make libbladeRF-doxygen
        if [ -d "host/libraries/libbladeRF/doc/doxygen/html" ]
        then
            _result=build/host/libraries/libbladeRF/doc/doxygen/html
        else
            _result=""
        fi
    qpopd
}

# run_bladerf_clangscan: runs clang's scan-build
function run_bladerf_clangscan() {
    mkdir clang_scan
    qpushd clang_scan
        cmake -DCMAKE_C_COMPILER=/usr/share/clang/scan-build/ccc-analyzer \
              ../
        /usr/share/clang/scan-build/scan-build -analyze-headers -maxloop 100 -stats -o ./report make
        if [ -d "./report" ]
        then
            _result="clang_scan/report"
        else
            _result=""
        fi
    qpopd
}

# build_bladerf_coverity: builds a coverity tarball
function build_coverity_tarball()
{
    _oldpath=$PATH
    PATH=$PATH:$COVERITY_PATH
    cov-configure --comptype gcc --compiler /opt/cypress/fx3_sdk/arm-2011.03/bin/arm-none-eabi-gcc

    qpushd build
        make clean
        rm -rf cov-int/
        cov-build --dir cov-int/ make

        tar -czvf bladeRF_coverity.tgz cov-int/

        if [ -f "bladeRF_coverity.tgz" ]
        then
            _result=build/bladeRF_coverity.tgz
        else
            _result=""
        fi
    qpopd
}

# consider_latest_symlink: updates the "latest" symlink to point at this
# revision, if certain conditions are met
# Args: builds_root revid
function consider_latest_symlink()
{
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "consider_latest_symlink: missing args"
        exit 1
    fi

    _builds_root=$1
    _revid=$2

    _artifacts_dir=${_builds_root}/${_revid}/artifacts

    qpushd $_artifacts_dir
        if [ -f "hostedx40.rbf" ] && [ -f "hostedx115.rbf" ] && [ -f "firmware.img" ] && [ -d "libbladeRF_doxygen" ]
        then
            echo "Pointing 'latest' at build ${_revid}"
            qpushd $_builds_root
                [ -h "latest" ] && rm -f latest
                ln -s ${_revid} latest
            qpopd
        else
            echo "Did NOT update 'latest' due to missing artifacts on ${_revid}!"
        fi
    qpopd
}
