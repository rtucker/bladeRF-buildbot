#!/bin/bash

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
    make
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

    make
    popd
}


clone_repo
build_libusbx
build_bladerf

