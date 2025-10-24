#!/bin/sh
if [ "$(uname -m)" = "x86_64" ]; then
  CUDA_TARGET="x86_64-linux"
  COMPILER_PREFIX="x86_64-conda-linux-gnu"
else
  CUDA_TARGET="sbsa-linux"
  COMPILER_PREFIX="aarch64-conda-linux-gnu"
fi

export CUDA_HOME="${CONDA_PREFIX}/targets/${CUDA_TARGET}"
export PATH="${CONDA_PREFIX}/bin:${CUDA_HOME}/bin:${PATH}"
export CPPFLAGS="${CPPFLAGS} -I${CONDA_PREFIX}/include -I${CUDA_HOME}/include"
export CXXFLAGS="${CXXFLAGS} -I${CONDA_PREFIX}/include -I${CUDA_HOME}/include"
export NVCC_LDFLAGS="${NVCC_LDFLAGS} -L${CONDA_PREFIX}/lib -L${CUDA_HOME}/lib -Xlinker -rpath=${CONDA_PREFIX}/lib:${CUDA_HOME}/lib"

if [[ ${CONDA_BUILD} == "1" ]]; then
  export CC="${CONDA_PREFIX}/bin/${COMPILER_PREFIX}-gcc"
  export CXX="${CONDA_PREFIX}/bin/${COMPILER_PREFIX}-g++"
  export FC="${CONDA_PREFIX}/bin/${COMPILER_PREFIX}-gfortran"
fi
