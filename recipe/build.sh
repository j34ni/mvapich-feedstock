#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

set -ex

unset F77 F90

export FFLAGS="-fallow-argument-mismatch ${FFLAGS}"

echo "CC_FOR_BUILD "$CC_FOR_BUILD
echo "CXX_FOR_BUILD " $CXX_FOR_BUILD

export CC=$CC_FOR_BUILD
export CXX=$CXX_FOR_BUILD

build_with_rdma=""
build_with_netmod=""
if [[ "$target_platform" == linux-* ]]; then
  echo "Build with RDMA support"
  build_with_rdma="--with-rdma=$PREFIX --enable-rdma-cm "
  if [ "$netmod" == "ucx" ]; then
    echo "Build with UCX support"
    build_with_netmod=" --with-device=ch4:ucx --with-ucx=$PREFIX "
  else
    echo "Build with OFI support"
    build_with_netmod=" --with-device=ch4:ofi "
  fi
  echo "Building for osx-arm64"
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
            --host="${HOST}" \
            --build="${BUILD}" \
            $build_with_netmod \
            --with-hwloc-prefix=$PREFIX \
            --with-rdma=$PREFIX \
            --enable-rdma-cm \
            --enable-fortran=no \
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

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
  make check
fi

make install
