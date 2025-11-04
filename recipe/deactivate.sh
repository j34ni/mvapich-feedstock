#!/bin/sh

unset CUDA_HOME

export PATH=$(echo $PATH | sed -e 's|${CONDA_PREFIX}/bin:||g' -e 's|${CONDA_PREFIX}/targets/[^/]\+/bin:||g')
export CPPFLAGS=$(echo $CPPFLAGS | sed -e 's| -I${CONDA_PREFIX}/include||g' -e 's| -I${CUDA_HOME}/include||g')
export CXXFLAGS=$(echo $CXXFLAGS | sed -e 's| -I${CONDA_PREFIX}/include||g' -e 's| -I${CUDA_HOME}/include||g')
export NVCC_LDFLAGS=$(echo $NVCC_LDFLAGS | sed -e 's| -L${CONDA_PREFIX}/lib||g' -e 's| -L${CUDA_HOME}/lib||g' -e 's| -Xlinker -rpath=${CONDA_PREFIX}/lib:||g' -e 's|:${CUDA_HOME}/lib||g')
