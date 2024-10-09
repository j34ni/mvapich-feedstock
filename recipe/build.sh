#!/bin/bash

set -ex

unset F77 F90

export FFLAGS="-fallow-argument-mismatch ${FFLAGS}"

export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

# Support for ch4:ucx or ch4:ofi devices
build_with_device=""
if [ "$device" == "ucx" ]; then
    echo "Build with UCX support"
    build_with_device=" --with-device=ch4:ucx --with-ucx=$PREFIX "
else
    echo "Build with OFI support"
    build_with_device=" --with-device=ch4:ofi "
fi

./configure --prefix=$PREFIX \
            $build_with_device \
            --with-hwloc-prefix=$PREFIX \
            --with-rdma=$PREFIX \
            --enable-rdma-cm \
            --enable-fortran=all \
            --enable-romio \
            --enable-nemesis-shm-collectives \
            --disable-gl \
            --disable-nvml \
            --disable-cl \
            --disable-opencl \
            --disable-dependency-tracking \
            --with-sysroot \
            --enable-static=no

make -j"${CPU_COUNT}"
make install
