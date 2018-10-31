#!/usr/bin/env bash

mkdir -p /tmp/inst

if [ -z "${VERIFY_DOWNLOAD}" ]; then
    # don't bother verifying
    echo "*** Begin download of ${QUARTUS_VERSION}..."
        curl "${QUARTUS_DOWNLOAD}" | tar -C /tmp/inst -xf -
else
    # save and verify
    echo "*** Begin download of ${QUARTUS_VERSION} (will verify md5sum)..."
        mkdir -p /tmp/dl
        curl -o /tmp/dl/quartus.tar "${QUARTUS_DOWNLOAD}"
    echo "*** Begin verify..."
        echo "${QUARTUS_MD5} /tmp/dl/quartus.tar" | md5sum -c -
    echo "*** Begin untar..."
        tar -C /tmp/inst -xf /tmp/dl/quartus.tar
        rm -rf /tmp/dl
fi

echo "*** Begin setup..."
    pushd /tmp/inst
    /root/setup ${QUARTUS_VERSION} ${QUARTUS_PATH}
    popd

echo "*** Begin clean..."
    rm -rf /tmp/inst \
       ${QUARTUS_PATH}/quartus/linux64/libboost_system.so \
       ${QUARTUS_PATH}/quartus/linux64/libccl_curl_drl.so \
       ${QUARTUS_PATH}/quartus/linux64/libstdc++.so.6

echo "*** Done!"
