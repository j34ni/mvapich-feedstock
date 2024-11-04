#!/bin/bash

set -ex

unset F77 F90

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

# Set netmod configuration
build_with_netmod=""
if [ "$netmod" == "ucx" ]; then
  echo "Build with UCX support"
  build_with_netmod=" --with-device=ch4:ucx --with-ucx=$PREFIX "
else
  echo "Build with OFI support"
  build_with_netmod=" --with-device=ch4:ofi "
fi

# Avoid recording flags in compilers, adapted from MPICH
# Save the current flags
export SAVED_CPPFLAGS=$CPPFLAGS
unset CPPFLAGS
export SAVED_CFLAGS=$CFLAGS
unset CFLAGS
export SAVED_CXXFLAGS=$CXXFLAGS
unset CXXFLAGS
export SAVED_LDFLAGS=$LDFLAGS
unset LDFLAGS
export SAVED_FFLAGS=$FFLAGS
unset FFLAGS
export SAVED_FCFLAGS=$FCFLAGS
unset FCFLAGS

# Set minimal necessary flags for this build process
export CPPFLAGS="-I$PREFIX/include"
export CFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export FFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export FCFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

export LIBRARY_PATH="$PREFIX/lib"

./configure --prefix=$PREFIX \
            $build_with_netmod \
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

# Restore the saved flags after configuration
export CPPFLAGS=$SAVED_CPPFLAGS
export CFLAGS=$SAVED_CFLAGS
export CXXFLAGS=$SAVED_CXXFLAGS
export LDFLAGS=$SAVED_LDFLAGS
export FFLAGS=$SAVED_FFLAGS
export FCFLAGS=$SAVED_FCFLAGS
