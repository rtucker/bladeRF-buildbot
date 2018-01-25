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

    # Use TCMalloc to avoid crashing during quartus_map
    # h/t: https://github.com/chriz2600/quartus-lite/
    export LD_PRELOAD=/usr/lib/libtcmalloc_minimal.so.4

    ${QUARTUS_PATH}/nios2eds/nios2_command_shell.sh ./build_bladerf.sh -r $1 -s $2

    _result=$(ls ${revision}x${size}*/${revision}x${size}.rbf | head -1)
}
