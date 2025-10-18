#!/bin/bash

# Sets up conda activation for env vars.

mkdir -p "${PREFIX}/etc/conda/activate.d"

cat > "${PREFIX}/etc/conda/activate.d/cuda_mvapich.sh" << EOF
#!/bin/sh
PREFIX="aarch64-conda-linux-gnu"
CUDA_TARGET="sbsa-linux"
if [ "\$(uname -m)" = "x86_64" ]; then
  PREFIX="x86_64-conda-linux-gnu"
  CUDA_TARGET="x86_64-linux"
fi
export CUDA_HOME="\${CONDA_PREFIX}/targets/\${CUDA_TARGET}"
export CC="\${CONDA_PREFIX}/bin/\${PREFIX}-gcc"
export CXX="\${CONDA_PREFIX}/bin/\${PREFIX}-g++"
export FC="\${CONDA_PREFIX}/bin/\${PREFIX}-gfortran"
export CPPFLAGS="\${CPPFLAGS} -I\${CONDA_PREFIX}/include -I\${CUDA_HOME}/include"
export CXXFLAGS="\${CXXFLAGS} -I\${CONDA_PREFIX}/include -I\${CUDA_HOME}/include"
export NVCC_LDFLAGS="\${NVCC_LDFLAGS} -L\${CONDA_PREFIX}/lib -L\${CUDA_HOME}/lib -Xlinker -rpath=\${CONDA_PREFIX}/lib:\${CUDA_HOME}/lib"
export PATH="\${CONDA_PREFIX}/bin:\${CUDA_HOME}/bin:\${PATH}"
export LD_LIBRARY_PATH="\${CUDA_HOME}/lib:\${CONDA_PREFIX}/lib:\${LD_LIBRARY_PATH}"
EOF

chmod +x "${PREFIX}/etc/conda/activate.d/cuda_mvapich.sh"
