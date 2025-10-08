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

export CPPFLAGS="-I$PREFIX/include"
export CFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export FFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export FCFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib"

export LIBRARY_PATH="$PREFIX/lib"

cd shs-libfabric

autoreconf -ivf

./configure --prefix=${PREFIX} \
            --enable-cxi \
            --with-cassini-headers=${PREFIX} \
            --with-cxi-uapi-headers=${PREFIX} \
            --with-curl=${PREFIX} \
            --with-json-c=${PREFIX} \
            --with-libnl=${PREFIX} \
            --docdir=$PWD/noinst/doc \
            --mandir=$PWD/noinst/man \
            --disable-lpp \
            --disable-psm3 \
            --disable-opx \
            --disable-efa \
            --disable-static

make -j${CPU_COUNT} src/libfabric.la
make -j${CPU_COUNT} util/fi_info util/fi_pingpong util/fi_strerror util/fi_mon_sampler

make install-exec install-data

cd ../mvapich

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LIBS="-lfabric $LIBS"

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
