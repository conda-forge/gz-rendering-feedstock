#!/bin/sh

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Workaround for PRIu64 not being defined
# See https://github.com/conda-forge/staged-recipes/pull/18792#issuecomment-1114606992
export CXXFLAGS="-D__STDC_FORMAT_MACROS $CXXFLAGS"

rm -rf build
mkdir build
cd build

export CFLAGS="${CFLAGS} -DGLX_GLXEXT_LEGACY"
export CXXFLAGS="${CXXFLAGS} -DGLX_GLXEXT_LEGACY"

cmake ${CMAKE_ARGS} -GNinja .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
      -DFREEIMAGE_RUNS:BOOL=ON \
      -DFREEIMAGE_RUNS__TRYRUN_OUTPUT:STRING="" \
      -DFREEIMAGE_COMPILES:BOOL=ON \
      -DGZ_ENABLE_RELOCATABLE_INSTALL:BOOL=ON \
      -DUSE_OGRE2_OVERLAY:BOOL=OFF \
      -DSKIP_optix:BOOL=ON

cmake --build . --config Release
cmake --build . --config Release --target install

# PERFORMANCE tests are disabled as they could fail on test machines
# _ogre_ test disabled as GLX is required for _ogre_
# UNIT_RenderingIface_TEST disabled due to https://github.com/gazebosim/gz-rendering/issues/1072
# _metal test disabled as metal tests are not running in CI
if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    ctest --output-on-failure -C Release -E "PERFORMANCE|_ogre_|UNIT_RenderingIface_TEST|_metal"
fi

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done
