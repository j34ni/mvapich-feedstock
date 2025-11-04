#!/bin/bash

set -ex

export CONDA_BUILD_SYSROOT

export PATH="${BUILD_PREFIX}/bin:$PATH"

unset F77 F90

if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 ]]; then
  if [[ "$target_platform" == "linux-aarch64" ]]; then
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

export CUDA_HOME="${PREFIX}/targets/x86_64-linux"
if [[ "$target_platform" == "linux-aarch64" ]]; then
  export CUDA_HOME="${PREFIX}/targets/sbsa-linux"
fi

export CPPFLAGS="-I$PREFIX/include -I${CONDA_BUILD_SYSROOT}/usr/include"
export CFLAGS="-I$PREFIX/include -I${CONDA_BUILD_SYSROOT}/usr/include"
export CXXFLAGS="-I$PREFIX/include -I${CONDA_BUILD_SYSROOT}/usr/include"
export FFLAGS="-I$PREFIX/include -fallow-argument-mismatch -I${CONDA_BUILD_SYSROOT}/usr/include"
export FCFLAGS="-I$PREFIX/include -fallow-argument-mismatch -I${CONDA_BUILD_SYSROOT}/usr/include"
export LDFLAGS="-L$PREFIX/lib -L${CUDA_HOME}/lib -L${CUDA_HOME}/lib/stubs -Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib:${CUDA_HOME}/lib --sysroot=${CONDA_BUILD_SYSROOT}"

export PATH="${PREFIX}/bin:${CUDA_HOME}/bin:${CUDA_HOME}/nvvm/bin:${PATH}" 
export LIBRARY_PATH="${CUDA_HOME}/lib:$PREFIX/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib:$LD_LIBRARY_PATH"

cd gdrcopy

sed -i "s/gcc/gcc/g" config_arch
make prefix=${PREFIX} SYSROOT=${CONDA_BUILD_SYSROOT} lib lib_install CC="$CC"
ls -la ${PREFIX}/lib/libgdrapi*

cd ../shs-libfabric

autoreconf -ivf

./configure --prefix=${PREFIX} \
            --with-sysroot=${CONDA_BUILD_SYSROOT} \
            --disable-cuda-dlopen \
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
            --disable-static \
            CC="$CC" CXX="$CXX"

make -j${CPU_COUNT} src/libfabric.la CC="$CC" CXX="$CXX"
make -j${CPU_COUNT} util/fi_info util/fi_pingpong util/fi_strerror util/fi_mon_sampler CC="$CC"
make install-exec install-data CC="$CC"

cd ../mvapich

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

./configure --prefix=$PREFIX \
            --with-sysroot=${CONDA_BUILD_SYSROOT} \
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
            --with-ucx=$PREFIX \
            --disable-dependency-tracking \
            --disable-option-checking \
            --with-wrapper-dl-type=none \
            --with-dl-type=none \
            LIBS="-L${PREFIX}/lib -lfabric" \
            CC="$CC" FC="$FC"

make -j"${CPU_COUNT}" CC="$CC"
make install CC="$CC"

for CHANGE in "activate" "deactivate"
  do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
  done
