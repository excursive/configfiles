#!/bin/bash

# make bash stricter about errors
set -e -o pipefail

is_valid_sha1() {
  [[ "$1" =~ ^[0-9A-Fa-f]{40}$ ]]
}

sha256r() {
  if [ -n "$1" ]; then
    output="$(sha256r)"
    if [ -e "$1" ]; then
      printf 'Error: Output file already exists\n'
      exit 1
    fi
    printf '%s' "$output" > "$1"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty sha256sum
  fi
}

# arguments:
# 1 = sha1 hash of git repo to checkout
# 2 = if 2 = 'fetch_updates' then fetch remote changes, otherwise ignored
clean_and_update_repo() {
  printf '\n======== Cleaning git repo and checking out specified commit\n'
  if ! is_valid_sha1 "$1"; then
    printf '\n==== Error: commit is not a valid sha1 hash\n'
    exit 1
  fi
  git clean -d -f -f -x
  if [ "$2" = 'fetch_updates' ]; then
    git fetch --recurse-submodules=on-demand
    if [ "$?" != 0 ]; then
      printf '\n==== Warning: Could not fetch updates\n'
    fi
  fi
  git checkout --recurse-submodules "$1"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not checkout specified commit\n'
    exit 1
  fi
  git submodule deinit --force --all
  git reset --hard --recurse-submodules "$1"
  git clean -d -f -f -x
  git checkout --recurse-submodules "$1"
  git submodule update --init --force --checkout --recursive --
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not checkout submodules\n'
    exit 1
  fi
}

manage_aseprite() {
  printf '\n======== Creating directories\n'
  asepritedir="${2}/aseprite"
  
  aseinstalldir="${asepritedir}/aseprite-1_2_25"
  skiainstalldir="${asepritedir}/skia-aseprite-m81"
  
  builddir="${asepritedir}/build"
  asebuilddir="${builddir}/aseprite"
  skiabuilddir="${builddir}/skia"
  
  srcdir="${asepritedir}/src"
  asesrcdir="${srcdir}/aseprite"
  skiasrcdir="${srcdir}/skia"
  #depottoolsdir="${srcdir}/depot_tools"
  
  tempbindir="${asepritedir}/tempbin"
  
  if [ "$1" = 'update' ]; then
    printf '\nError: Implementation of update is unfinished...\n'
    exit 1
    if [ ! -d "${asepritedir}" ] \
       || [ ! -d "${skiainstalldir}" ] \
       || [ ! -d "${srcdir}" ] \
       || [ ! -f "${asepritedir}/skia-aseprite-m81-sha256sums.txt" ]; then
      printf '\nError: Missing files from original installation\n'
      exit 1
    fi
    # TODO: need a better way to check if skia installation matches checksums
    if ! cd "${skiainstalldir}" \
       || ! sha256sum -c --quiet "${asepritedir}/skia-aseprite-m81-sha256sums.txt"; then
      printf '\nError: Skia installation does not match checksums\n'
      exit 1
    fi
    if ! mkdir "${aseinstalldir}" \
               "${builddir}" "${asebuilddir}" "${skiabuilddir}" \
               "${tempbindir}"; then
      printf '\nError: Could not create build directories\n'
      exit 1
    fi
  else
    if [ -e "${asepritedir}" ] \
       || ! mkdir "${asepritedir}" "${aseinstalldir}" "${skiainstalldir}" \
                                   "${builddir}" "${asebuilddir}" "${skiabuilddir}" \
                                   "${srcdir}" \
                                   "${tempbindir}"; then
      printf '\nError: Directories could not be created\n'
      exit 1
    fi
  fi
  
  # in case python doesn't point to python2 binary,
  # set up a temp folder with a link to temporarily add to path
  ln -s '/usr/bin/python2' "${tempbindir}/python"
  
  if [ "$1" = 'install' ]; then
    printf '\n======== Checking out git repositories\n'
    cd "${srcdir}"
    #git clone --no-checkout 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'
    git clone --no-checkout 'https://skia.googlesource.com/skia.git'
    git clone --no-checkout 'https://github.com/aseprite/aseprite.git'
  fi
  
  printf '\n======== Checking out aseprite version 1.2.25\n'
  cd "${asesrcdir}"
  if [ "$(git config --get remote.origin.url)" != 'https://github.com/aseprite/aseprite.git' ] \
     || [ "$(git remote get-url --all origin)" != 'https://github.com/aseprite/aseprite.git' ] \
      || [ "$(git ls-remote --get-url origin)" != 'https://github.com/aseprite/aseprite.git' ]; then
    printf '\nError: aseprite git repository url does not match\n'
    exit 1
  fi
  clean_and_update_repo 'f44aad06db9d7a7efe9beb0038df37140ac9c2ba'
  
  # just check out a random depot_tools commit that is known to work
  #cd "${depottoolsdir}"
  #if [ "$(git config --get remote.origin.url)" != 'https://chromium.googlesource.com/chromium/tools/depot_tools.git' ] \
  #   || [ "$(git remote get-url --all origin)" != 'https://chromium.googlesource.com/chromium/tools/depot_tools.git' ] \
  #    || [ "$(git ls-remote --get-url origin)" != 'https://chromium.googlesource.com/chromium/tools/depot_tools.git' ]; then
  #  printf '\nError: depot_tools git repository url does not match\n'
  #  exit 1
  #fi
  #clean_and_update_repo 'b073999c6f90103a36a923e63ae8cf7a5c9c6c8c'
  
  printf '\n======== Checking out commit aseprite-m81 skia was forked from\n'
  cd "${skiasrcdir}"
  if [ "$(git config --get remote.origin.url)" != 'https://skia.googlesource.com/skia.git' ] \
     || [ "$(git remote get-url --all origin)" != 'https://skia.googlesource.com/skia.git' ] \
      || [ "$(git ls-remote --get-url origin)" != 'https://skia.googlesource.com/skia.git' ]; then
    printf '\nError: skia git repository url does not match\n'
    exit 1
  fi
  clean_and_update_repo '3e98c0e1d11516347ecc594959af2c1da4d04fc9'
  PATH="${PATH}:${tempbindir}" python tools/git-sync-deps
  
  printf '\n==== Modifying files to match aseprite-m81 skia\n'
  sed -i -e '1878i\
            return;' \
               'src/gpu/GrRenderTargetContext.cpp'
  sed -i -e '249c\
static inline double sk_ieee_double_divide_TODO_IS_DIVIDE_BY_ZERO_SAFE_HERE(double n, double d) {' \
               'include/private/SkFloatingPoint.h'
  sed -i -e '66c\
    # Setup the env before\
    #env_setup = "cmd /c $win_sdk\\\\bin\\\\SetEnv.cmd /x86 \&\& "' \
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
  printf '\n==== Done modifying skia files\n'
  
  
  printf '\n======== Building skia\n'
  cd "${skiasrcdir}"
  PATH="${PATH}:${tempbindir}" bin/gn gen "${skiabuilddir}" \
    --args='is_debug=false is_official_build=true skia_use_sfntly=false skia_use_dng_sdk=false skia_use_piex=false'
  cd "${skiabuilddir}"
  ninja -C "${skiabuilddir}" skia modules
  
  printf '\n======== Copying built skia into aseprite/skia-build\n'
  mkdir "${skiainstalldir}/lib"
  mv "${skiabuilddir}"/*.a "${skiainstalldir}/lib"
  cd "${skiasrcdir}"
  cp -R --parents \
    include \
    modules/particles/include/*.h \
    modules/skottie/include/*.h \
    modules/skresources/include/*.h \
    modules/sksg/include/*.h \
    modules/skshaper/include/*.h \
    "${skiainstalldir}"
  
  
  printf '\n======== Building aseprite\n'
  cd "${asebuilddir}"
  # enable shared libraries not in universe repo
  # disable network stuff (news and updates)
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DLAF_BACKEND=skia \
        -DSKIA_DIR="${skiainstalldir}" \
        -DSKIA_LIBRARY_DIR="${skiainstalldir}/lib" \
        -DSKIA_LIBRARY="${skiainstalldir}/lib/libskia.a" \
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
  
  printf '\n======== Moving final builds\n'
  mv --no-target-directory "${asebuilddir}/bin" "${aseinstalldir}/bin"
  mv --no-target-directory "${asebuilddir}/lib" "${aseinstalldir}/lib"
  cp --no-target-directory "${skiainstalldir}/lib" "${aseinstalldir}/lib/skia"
  
  
  printf '\n======== Generating checksums\n'
  cd "${aseinstalldir}"
  sha256r "${asepritedir}/aseprite-1_2_25-sha256sums.txt"
  cd "${skiainstalldir}"
  sha256r "${asepritedir}/skia-aseprite-m81-sha256sums.txt"
  
  
  printf '\n======== Cleaning up\n'
  rm -R "${builddir}" "${tempbindir}"
  if [ "$4" = 'keep_sources' ]; then
    printf '\n==== Keeping source repos\n'
  else
    rm -R "${srcdir}"
  fi
  
  
  printf '\n======== Creating application launcher\n'
  launcher_path="${HOME}/.local/share/applications/org.aseprite.desktop"
  launcher_text="[Desktop Entry]
Type=Application
Name=Aseprite
Comment=Animated Sprite Editor & Pixel Art Tool
Icon=${aseinstalldir}/bin/data/icons/ase256.png
Exec=${aseinstalldir}/bin/aseprite
Path=${aseinstalldir}
Terminal=false
Category=Graphics;"
  
  if [ -e "${launcher_path}" ]; then
    printf '\n==== Launcher not created, file already exists\n'
  else
    printf '%s\n' "$launcher_text" > "${launcher_path}"
  fi
}



# Process input
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Usage:\n'
  printf 'manage_software.sh 1 2 3 4 (5)\n'
  printf '  1 = software name [ aseprite ]\n'
  printf '  2 = [ install | update ]\n'
  printf '  3 = software version [ default | (a git commit sha1) ]\n'
  printf '  4 = where to create installation directory\n'
  printf '  5 = "keep_sources" will keep source repos after building, all other values ignored\n'
  exit 0
fi

action=''
version=''
install_parent_directory=''
keep_sources=''

if [ "$5" = 'keep_sources' ]; then
  keep_sources='keep_sources'
fi

if [ -d "$4" ]; then
  install_parent_directory="$4"
else
  printf '\nError: Invalid install parent directory\n'
  exit 1
fi

case "$3" in
  'default')
    version='default'
  ;;
  *)
    if is_valid_sha1 "$3"; then
      version="$3"
    else
      printf '\nError: Version is not default or a valid sha1 hash\n'
      exit 1
    fi
  ;;
esac

case "$2" in
  'install')
    action='install'
  ;;
  'update')
    action='update'
  ;;
  *)
    printf '\nError: 2nd parameter must be install or update\n'
    exit 1
  ;;
esac

case "$1" in
  'aseprite')
    manage_aseprite "$action" "$version" "$install_parent_directory" "$keep_sources"
  ;;
  '')
    printf '\nError: No arguments supplied, see -h or --help\n'
    exit 1
  ;;
  *)
    printf '\nError: Invalid software name\n'
    exit 1
  ;;
esac

printf '\n======== All done!\n'

exit 0
