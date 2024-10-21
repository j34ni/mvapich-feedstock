#!/bin/bash

set -ex

unset F77 F90

export FFLAGS="-fallow-argument-mismatch ${FFLAGS}"

export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

build_with_rdma=""
if [[ "$target_platform" == linux-* ]]; then
  echo "Build with RDMA support"
  build_with_rdma="--with-rdma=$PREFIX --enable-rdma-cm "
fi

if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 ]]; then
  if [[ "$target_platform" == "linux-aarch64" || "$target_platform" == "linux-ppc64le" ]]; then
    export CROSS_F77_SIZEOF_INTEGER=4
    export CROSS_F77_SIZEOF_REAL=4
    export CROSS_F77_SIZEOF_DOUBLE_PRECISION=8
    export CROSS_F77_TRUE_VALUE=1
    export CROSS_F77_FALSE_VALUE=0
    export CROSS_F90_ADDRESS_KIND=8
    export CROSS_F90_OFFSET_KIND=8
    export CROSS_F90_INTEGER_KIND=4
    export CROSS_F90_REAL_MODEL=" 6 , 37"
    export CROSS_F90_DOUBLE_MODEL=" 15 , 307"
  fi
fi

./configure --prefix=$PREFIX \
            --with-device=ch4:ofi \
            --with-hwloc-prefix=$PREFIX \
            $build_with_rdma \
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
