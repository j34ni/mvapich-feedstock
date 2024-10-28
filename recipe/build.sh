#!/bin/bash
set -e

# Replace the "old" libfabric which comes with mvapich by a more recent version
if [[ "$netmod" == "ofi" ]]; then
  rm -rf mvapich_source/modules/libfabric
  cp -r libfabric_source mvapich_source/modules/libfabric

  # Run autoreconf to regenerate the configure script and other build files
  cd mvapich_source/modules/libfabric
  autoreconf -ivf
  cd ../../..
fi

cd mvapich_source 

unset F77 F90

export FFLAGS="-fallow-argument-mismatch ${FFLAGS}"

export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")
build_for_fortran="yes"

if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 && $target_platform == osx-arm64 ]]; then
  list_config_to_patch=$(find ./ -name config.guess | sed -E 's/config.guess//')
  for config_folder in $list_config_to_patch; do
      echo "Copying config to $config_folder ..."
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

if [[ "$netmod" == "ucx" ]]; then
  echo "Build with UCX support"
  build_with_netmod=" --with-device=ch4:ucx --with-ucx=$PREFIX "
else
  echo "Build with OFI support"
  build_with_netmod=" --with-device=ch4:ofi "
fi

if [[ "$target_platform" == "osx-arm64" ]]; then
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

# Set conditional flags for bison and flex based on target
bison_flags="-y "
if [[ "$target_platform" == "osx-arm64" ]]; then
  bison_flags="-Wno-yacc"
  export CFLAGS="${CFLAGS} -Wno-error"
  export CXXFLAGS="${CXXFLAGS} -Wno-error"
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
            --enable-static=no \
            BISONFLAGS=${bison_flags}

make -j"${CPU_COUNT}" V=1
make install
