#!/bin/bash

set -ex

unset F77 F90

export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

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

# Set minimal necessary flags for this build process
export CPPFLAGS="-I$PREFIX/include"
export CFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export FFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export FCFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

export LIBRARY_PATH="$PREFIX/lib"

./configure --prefix=$PREFIX \
	    --with-device=ch4:ucx,ofi \
	    --with-ucx=$PREFIX \
            --with-libfabric=$PREFIX \
            --with-libfabric-include=$PREFIX/include \
            --with-libfabric-lib=$PREFIX/lib \
            --enable-fortran=all \
            --enable-romio \
            --enable-nemesis-shm-collectives \
            --disable-dependency-tracking \
            --with-sysroot \
            --enable-static=no

make -j"${CPU_COUNT}"
make install
