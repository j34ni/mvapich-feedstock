#!/bin/bash

set -ex

unset F77 F90

export FFLAGS="-fallow-argument-mismatch ${FFLAGS}"

export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")
build_for_fortran="yes"

if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 && $target_platform == osx-arm64 ]]; then
  # use Conda-Forge's Arm64 config.guess and config.sub, see
  # https://conda-forge.org/blog/posts/2020-10-29-macos-arm64/
  list_config_to_patch=$(find ./ -name config.guess | sed -E 's/config.guess//')
  for config_folder in $list_config_to_patch; do
      echo "copying config to $config_folder ...\n"
      cp -v $BUILD_PREFIX/share/gnuconfig/config.* $config_folder
  done
  unset FC
  build_for_fortran="no"
fi

build_with_rdma=""
build_with_netmod=""
if [[ "$target_platform" == linux-* ]]; then
  echo "Build with RDMA support"
  build_with_rdma="--with-rdma=$PREFIX --enable-rdma-cm "
fi

if [ "$netmod" == "ucx" ]; then
  echo "Build with UCX support"
  build_with_netmod=" --with-device=ch4:ucx --with-ucx=$PREFIX "
else
  echo "Build with OFI support"
  build_with_netmod=" --with-device=ch4:ofi "
fi

if [ "$target_platform" == "osx-arm64" ]; then
  echo "Building for osx-arm64"
  build_with_netmod=" --with-device=ch4 "
fi

if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 ]]; then
  if [[ "$target_platform" == "osx-arm64" || "$target_platform" == "linux-aarch64" || "$target_platform" == "linux-ppc64le" ]]; then
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
            $build_with_rdma \
            --enable-fortran=${build_for_fortran} \
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
