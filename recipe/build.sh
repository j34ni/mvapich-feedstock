#!/bin/bash

set -ex

unset F77 F90

export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export FC=$(basename "$FC")

export CUDA_HOME="${PREFIX}/targets/x86_64-linux"
if [[ "$target_platform" == "linux-aarch64" ]]; then
  export CUDA_HOME="${PREFIX}/targets/sbsa-linux"
fi

export CPPFLAGS="-I$PREFIX/include"
export CFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export FFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export FCFLAGS="-I$PREFIX/include -fallow-argument-mismatch"
export LDFLAGS="-L$PREFIX/lib -L${CUDA_HOME}/lib -L${CUDA_HOME}/lib/stubs -Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib:${CUDA_HOME}/lib"

export PATH="${PREFIX}/bin:${CUDA_HOME}/bin:${CUDA_HOME}/nvvm/bin:${PATH}" 
export LIBRARY_PATH="${CUDA_HOME}/lib:$PREFIX/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib:$LD_LIBRARY_PATH"

cd gdrcopy

sed -i "s/gcc/${CC}/g" config_arch
make prefix=${PREFIX} lib lib_install
ls -la ${PREFIX}/lib/libgdrapi*

cd ../shs-libfabric

autoreconf -ivf

./configure --prefix=${PREFIX} \
            --enable-cuda-dlopen \
            --enable-cxi \
	    --enable-gdrcopy-dlopen \
            --with-cassini-headers=${PREFIX} \
            --with-cuda=${CUDA_HOME} \
            --with-cxi-uapi-headers=${PREFIX} \
            --with-curl=${PREFIX} \
	    --with-gdrcopy=${PREFIX} \
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
            --enable-fortran=all \
            --enable-nemesis-shm-collectives \
            --enable-romio \
            --enable-static=no \
            --with-cuda=${CUDA_HOME} \
            --with-cuda-sm=90 \
            --with-device=ch4:ucx,ofi \
            --with-libfabric=$PREFIX \
            --with-libfabric-include=$PREFIX/include \
            --with-libfabric-lib=$PREFIX/lib \
            --with-sysroot \
            --with-ucx=$PREFIX \
            --disable-dependency-tracking \
            --disable-option-checking \
            --with-wrapper-dl-type=none \
            --with-dl-type=none

make -j"${CPU_COUNT}"

make install
