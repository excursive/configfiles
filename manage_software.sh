#!/bin/bash

# Usage:
# manage_software.sh 1 2 3
# 1 = aseprite
# 2 = install
# 3 = version (if applicable, usually a git commit sha1)

is_valid_sha1() {
  [[ "$1" =~ ^[0-9A-Fa-f]{40}$ ]]
}

get_aseprite() {
  echo ''
  echo '======== Creating directories'
  parentdir="${PWD}/aseprite"
  asebuilddir="${parentdir}/aseprite-build"
  skiabuilddir="${parentdir}/skia-build"
  asesrcdir="${parentdir}/src/aseprite"
  skiasrcdir="${parentdir}/src/skia"
  #depottoolsdir="${parentdir}/src/depot_tools"
  tempbindir="${parentdir}/tempbin"
  
  if [ -d "${parentdir}" ] || \
     ! mkdir "${parentdir}" "${asebuilddir}" "${skiabuilddir}" "${parentdir}/src" "${tempbindir}"; then
    echo 'Directories could not be created. Exiting.'
    #exit 1
  fi
  
  # in case python doesn't point to python2 binary,
  # set up a temp folder with a link to temporarily add to path
  ln -s '/usr/bin/python2' "${tempbindir}/python"
  
  echo ''
  echo '======== Checking out git repositories'
  cd "${parentdir}/src"
  #git clone --no-checkout 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'
  git clone --no-checkout 'https://skia.googlesource.com/skia.git'
  git clone --no-checkout 'https://github.com/aseprite/aseprite.git'
  
  
  echo ''
  echo '======== Checking out aseprite version 1.2.25'
  cd "${asesrcdir}"
  git checkout f44aad06db9d7a7efe9beb0038df37140ac9c2ba
  git submodule update --init --recursive
  
  # just check out a random depot_tools commit that is known to work
  cd "${depottoolsdir}"
  #git checkout b073999c6f90103a36a923e63ae8cf7a5c9c6c8c
  
  echo ''
  echo '======== Checking out commit aseprite-m81 skia was forked from'
  cd "${skiasrcdir}"
  git checkout 3e98c0e1d11516347ecc594959af2c1da4d04fc9
  
  echo ''
  echo '======== Modifying files to match aseprite-m81 skia'
  sed -i -e '1878i\
            return;' \
               'src/gpu/GrRenderTargetContext.cpp'
  sed -i -e '249c\
static inline double sk_ieee_double_divide_TODO_IS_DIVIDE_BY_ZERO_SAFE_HERE(double n, double d) {' \
               'include/private/SkFloatingPoint.h'
  sed -i -e '66c\
    # Setup the env before\n    #env_setup = "cmd /c $win_sdk\\\\bin\\\\SetEnv.cmd /x86 \&\& "' \
               'gn/toolchain/BUILD.gn'
  sed -i -e '25i\
    include_dirs = [ "../externals/freetype/include" ]' \
         -e '30i\
      "HAVE_FREETYPE",' \
               'third_party/harfbuzz/BUILD.gn'
  sed -i -e '49c\
            return std::make_tuple(p, ct, at);' \
               'src/gpu/GrProcessorUnitTest.cpp'
  sed -i -e '833c\
    return std::make_tuple(code != GrDrawOpAtlas::ErrorCode::kError, glyphsPlacedInAtlas);' \
         -e '856c\
        return std::make_tuple(true, end - begin);' \
               'src/gpu/text/GrTextBlob.cpp'
  echo '==== Done modifying skia files.'
  
  echo ''
  echo '======== Building skia'
  cd "${skiasrcdir}"
  PATH="${PATH}:${tempbindir}" python tools/git-sync-deps
  PATH="${PATH}:${tempbindir}" bin/gn gen out/Release-x64 \
    --args='is_debug=false is_official_build=true skia_use_sfntly=false skia_use_dng_sdk=false skia_use_piex=false'
  ninja -C out/Release-x64 skia modules
  
  echo ''
  echo '======== Copying built skia into aseprite/skia-build'
  cd "${skiasrcdir}"
  cp -R --parents \
    out/Release-x64/*.a \
    include \
    modules/particles/include/*.h \
    modules/skottie/include/*.h \
    modules/skresources/include/*.h \
    modules/sksg/include/*.h \
    modules/skshaper/include/*.h \
    "${skiabuilddir}"
  
  echo ''
  echo '======== Building aseprite'
  cd "${asebuilddir}"
  # enable shared libraries not in universe repo
  # disable network stuff (news and updates)
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DLAF_BACKEND=skia \
        -DSKIA_DIR="${skiabuilddir}" \
        -DSKIA_LIBRARY_DIR="${skiabuilddir}/out/Release-x64" \
        -DSKIA_LIBRARY="${skiabuilddir}/out/Release-x64/libskia.a" \
        -DUSE_SHARED_CMARK='OFF' \
        -DUSE_SHARED_CURL='ON' \
        -DUSE_SHARED_FREETYPE='ON' \
        -DUSE_SHARED_GIFLIB='ON' \
        -DUSE_SHARED_HARFBUZZ='ON' \
        -DUSE_SHARED_JPEGLIB='ON' \
        -DUSE_SHARED_LIBPNG='ON' \
        -DUSE_SHARED_PIXMAN='ON' \
        -DUSE_SHARED_TINYXML='OFF' \
        -DUSE_SHARED_ZLIB='ON' \
        -DENABLE_NEWS='OFF' \
        -DENABLE_UPDATER='OFF' \
        -G Ninja \
        "${asesrcdir}"
  ninja aseprite
}


# Process input
case "$1" in
  'aseprite')
    get_aseprite
  ;;
  'other')
    #if ! is_valid_sha1 "$3"; then
    #  echo 'Specified version is not a sha1 hash. Exiting.'
      exit 1
    #fi
  ;;
  '')
    echo 'No software name specified. Exiting.'
    exit 1
  ;;
  *)
    echo 'Invalid software name. Exiting'
    exit 1
  ;;
esac

echo '***************************'
echo '======== All done! ========'

exit 0
