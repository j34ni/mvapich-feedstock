#!/bin/bash

set -ex

export CONDA_BUILD_SYSROOT

export PATH="${BUILD_PREFIX}/bin:$PATH"

unset F77 F90

export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

if [[ "$target_platform" == "linux-aarch64" ]]; then
  export CROSS_F77_SIZEOF_INTEGER=4
  export CROSS_F77_SIZEOF_REAL=4
  export CROSS_F77_SIZEOF_DOUBLE_PRECISION=8
  export CROSS_F77_SIZEOF_LOGICAL=4
  export CROSS_F77_TRUE_VALUE=1
  export CROSS_F77_FALSE_VALUE=0
  export CROSS_F90_ADDRESS_KIND=8
  export CROSS_F90_OFFSET_KIND=8
  export CROSS_F90_INTEGER_KIND=4
  export CROSS_F90_REAL_MODEL=" 6 , 37"
  export CROSS_F90_DOUBLE_MODEL=" 15 , 307"
fi

export CPPFLAGS="-I$PREFIX/include"
export CFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export FFLAGS="-I$PREFIX/include"
export FCFLAGS="-I$PREFIX/include"

# Conditionally add -fallow-argument-mismatch for gfortran >=10
if [[ "$(uname)" == "Linux" ]] || [[ "$(uname)" == "Darwin" ]]; then
  GFORTRAN_VERSION=$("${FC}" -dumpversion | cut -d. -f1)
  if [[ "${GFORTRAN_VERSION}" -ge 10 ]]; then
    export FFLAGS="${FFLAGS} -fallow-argument-mismatch"
    export FCFLAGS="${FCFLAGS} -fallow-argument-mismatch"
  fi
fi

export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib"

cd shs-libfabric

autoreconf -ivf

./configure --prefix=${PREFIX} \
            --with-sysroot=${CONDA_BUILD_SYSROOT} \
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

unset PKG_CONFIG_PATH

./configure --prefix=$PREFIX \
            --with-sysroot=${CONDA_BUILD_SYSROOT} \
            --enable-fortran=all \
            --enable-nemesis-shm-collectives \
            --enable-romio \
            --enable-static=no \
            --with-device=ch4:ucx,ofi \
            --with-libfabric=$PREFIX \
            --with-libfabric-include=$PREFIX/include \
            --with-libfabric-lib=$PREFIX/lib \
            --with-ucx=$PREFIX \
            --disable-dependency-tracking \
            --disable-option-checking \
            --with-wrapper-dl-type=none \
            --with-dl-type=none

make -j"${CPU_COUNT}"

make install
