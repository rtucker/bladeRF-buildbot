#!/bin/bash

function get_build_id() {
    if [ -z "$1" ]; then
        echo "get_commit_id: missing directory"
        exit 1
    fi

    if [ -z "$2" ]; then
        _rev=HEAD
    else
        _rev=$2
    fi

    pushd $1
        _revinfo=$(git rev-list ${_rev} -n 1 --timestamp)
        _datestamp=$(cut -d' ' -f1 <<< "$_revinfo")
        _datestr=$(date --date=@${_datestamp} +%Y%m%d%H%M%S)
        _hash=$(cut -d' ' -f2 <<< "$_revinfo")
        _hashstr=${_hash::7}

        _result=${_datestr}-git${_hashstr}
    popd
}

function clone_repo() {
    git clone /srv/bladerf/bladeRF/
    mkdir -p bladeRF/host/build/
}


function build_libusbx() {
    echo "******************************************************"
    echo "* Building: LibUSB"
    echo "******************************************************"
    pushd /tmp/libusbx-1.0.18
    ./configure --host=i686-w64-mingw32 --prefix=/usr/i686-w64-mingw32
    make -j3
    make install
    popd

    mkdir -p /MinGW64/dll/
    mkdir -p /MinGW64/static/
    ln -s /usr/i686-w64-mingw32/bin/libusb-1.0.dll /MinGW64/dll/libusb-1.0.dll
    ln -s /usr/i686-w64-mingw32/lib/libusb-1.0.dll.a /MinGW64/dll/libusb-1.0.dll.a
    ln -s /usr/i686-w64-mingw32/lib/libusb-1.0.a /MinGW64/static/libusb-1.0.a
    ln -s /usr/i686-w64-mingw32/include /include
    LIBUSB_PATH=/
}

function build_pthread() {
    exit 0
    mkdir pthread/
    pushd pthread/
    tar -zxvf /bladerf/pthreads-w32-2-9-1-release.tar.gz
    pushd pthreads-w32-2-9-1-release
    make CROSS=i686-w64-mingw32- clean GC-inlined
    mkdir ../dll/
    cp *.dll ../dll/
    cp *.a ../dll/
    popd
    pushd dll
    export LIBPTHREADSWIN32_PATH=`pwd`
    popd
    popd
}

function build_bladerf() {
    echo "******************************************************"
    echo "* Building: bladeRF"
    echo "******************************************************"
 
    pushd bladeRF/host/build/
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=/bladerf/i686-w64-mingw32.toolchain \
        -DLIBUSB_PATH=${LIBUSB_PATH} \
        -DLIBPTHREADSWIN32_PATH=${LIBPTHREADSWIN32_PATH} \
    ..

    make -j3
    popd
}

function package_build() {
    get_build_id /bladerf/bladeRF
    DIR=bladeRF-i686-w64-mingw32-${_result}
    pushd /bladerf/bladeRF/host/build
    mkdir ${DIR}
    cp output/* ${DIR}
    cp /usr/i686-w64-mingw32/lib/libwinpthread-1.dll ${DIR}
    cp /usr/lib/gcc/i686-w64-mingw32/4.8/libgcc_s_sjlj-1.dll ${DIR}
    cp ../../CONTRIBUTORS ${DIR}/CONTRIBUTORS.bladeRF
    cp ../../COPYING ${DIR}/COPYING.bladeRF
    cp ../../README.md ${DIR}/README.bladeRF
    cp /pthreads/Pre-built.2/CONTRIBUTORS ${DIR}/CONTRIBUTORS.pthreads-win32
    cp /pthreads/Pre-built.2/COPYING ${DIR}/COPYING.pthreads-win32
    cp /pthreads/Pre-built.2/README ${DIR}/README.pthreads-win32
    cp /tmp/libusbx-1.0.18/AUTHORS ${DIR}/CONTRIBUTORS.libusbx
    cp /tmp/libusbx-1.0.18/COPYING ${DIR}/COPYING.libusbx
    cp /tmp/libusbx-1.0.18/README ${DIR}/README.libusbx
    cp /usr/share/doc/mingw-w64-i686-dev/copyright ${DIR}/COPYING.mingw-w64-i686-dev
    cp /usr/share/doc/gcc-mingw-w64-i686/copyright ${DIR}/COPYING.gcc-mingw-w64-i686
cat > ${DIR}/README <<EOF
This is an automated Windows build of the bladeRF host components,
including libbladeRF and the bladeRF-cli utility.  It was built using
Mingw64 inside of a Docker container on a Linux system.

There should be a SIGNED.md file in this directory containing a valid
Keybase signature by rtucker.  If not, regard it with suspicion.

For DLL copyright information, see:
libbladeRF.dll          COPYING.bladeRF
libgcc_s_sjlj-1.dll     COPYING.gcc-mingw-w64-i686
libusb-1.0.dll          COPYING.libusbx
libwinpthread-1.dll     COPYING.mingw-w64-i686-dev
pthreadVC2.dll          COPYING.pthreads-win32        

Build system information:
Date:    $(date -u)
Host:    $(hostname -f)
Distro:  $(lsb_release -ds)
Kernel:  $(cat /proc/version)
Uptime:  $(uptime)

Toolchain versions:
$(dpkg-query --show gcc-mingw-w64-i686 g++-mingw-w64-i686 mingw-w64-tools cmake git)

Questions/comments may be directed to:
Ryan Tucker <bladerf@ryantucker.us>
IRC: HoopyCat (#bladerf on irc.freenode.net)

The build script is part of the bladeRF-buildbot project:
https://github.com/rtucker/bladeRF-buildbot

Powered by Linode high performance SSD servers:
https://www.linode.com/?r=f4079e5bd594cdb5820aaec4a8eaca7b533dd6d0
EOF
    zip -r ${DIR}.zip ${DIR}
    cp ${DIR}.zip /srv/bladerf/
    popd
}


clone_repo
build_libusbx
build_bladerf
package_build

