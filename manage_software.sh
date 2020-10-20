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

check_repo_urls() {
  [ "$(git config --get remote.origin.url)" = "$1" ] \
  && [ "$(git remote get-url --all origin)" = "$1" ] \
   && [ "$(git ls-remote --get-url origin)" = "$1" ]
}

# arguments:
# 1 = sha1 hash of git repo to checkout
# 2 = 'fetch_updates' to fetch remote changes, otherwise ignored
clean_and_update_repo() {
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

# manage_aseprite arguments:
# 1 = action (install or update)
# 2 = version (default or a commit sha1 hash)
# 3 = parent directory, i.e. where to create (or find) 'aseprite' directory
# 4 = 'keep_sources' to keep source code after installation
manage_aseprite() {
  if [ "$2" = 'default' ]; then
    aseprite_version='f44aad06db9d7a7efe9beb0038df37140ac9c2ba'
    printf '\n======== Defaulting to aseprite version 1.2.25\n'
  else if is_valid_sha1 "$2"; then
    aseprite_version="$2"
  else
    printf '\n======== Error: aseprite version is not default or a valid sha1 hash\n'
    exit 1
  fi
  
  printf '\n======== Creating directories\n'
  aseprite_dir="${3}/aseprite"
  
  ase_install_dir="${aseprite_dir}/aseprite-${aseprite_version}"
  skia_install_dir="${aseprite_dir}/skia-aseprite-m81"
  
  build_dir="${aseprite_dir}/build"
  ase_build_dir="${build_dir}/aseprite"
  skia_build_dir="${build_dir}/skia"
  
  src_dir="${aseprite_dir}/src"
  ase_src_dir="${src_dir}/aseprite"
  skia_src_dir="${src_dir}/skia"
  #depot_tools_dir="${src_dir}/depot_tools"
  
  temp_bin_dir="${aseprite_dir}/tempbin"
  
  if [ "$1" = 'update' ]; then
    if [ ! -d "${aseprite_dir}" ] \
       || [ ! -d "${skia_install_dir}" ] \
       || [ ! -d "${src_dir}" ] \
       || [ ! -f "${aseprite_dir}/skia-aseprite-m81-sha256sums.txt" ]; then
      printf '\n==== Error: Missing files from original installation\n'
      exit 1
    fi
    if [ -e "${ase_install_dir}" ]; then
      printf '\n==== Error: Aseprite install directory already exists\n'
      printf '==== To reinstall, first delete the previous installation directory:\n'
      printf '%s\n' "${ase_install_dir}"
      exit 1
    fi
    if ! mkdir "${ase_install_dir}" \
               "${build_dir}" "${ase_build_dir}" "${skia_build_dir}" \
               "${temp_bin_dir}"; then
      printf '\n==== Error: Could not create build directories\n'
      exit 1
    fi
  else if [ "$1" = 'install' ]; then
    if [ -e "${aseprite_dir}" ] \
       || ! mkdir "${aseprite_dir}" "${ase_install_dir}" "${skia_install_dir}" \
                                   "${build_dir}" "${ase_build_dir}" "${skia_build_dir}" \
                                   "${src_dir}" \
                                   "${temp_bin_dir}"; then
      printf '\n==== Error: Directories could not be created\n'
      exit 1
    fi
  else
    printf '\n======== Error: Invalid specified action, must be install or update\n'
    exit 1
  fi
  
  # in case python doesn't point to python2 binary,
  # set up a temp folder with a link to temporarily add to path
  ln -s '/usr/bin/python2' "${temp_bin_dir}/python"
  
  if [ "$1" = 'install' ]; then
    printf '\n======== Checking out git repositories\n'
    cd "${src_dir}"
    #git clone --no-checkout 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'
    git clone --no-checkout 'https://skia.googlesource.com/skia.git'
    git clone --no-checkout 'https://github.com/aseprite/aseprite.git'
  fi
  
  printf '\n======== Checking out aseprite commit\n======== %s\n' "$aseprite_version"
  cd "${ase_src_dir}"
  if ! check_repo_urls 'https://github.com/aseprite/aseprite.git'; then
    printf '\n==== Error: aseprite git repository url does not match\n'
    exit 1
  fi
  
  if [ "$1" = 'update' ]; then
    clean_and_update_repo "$aseprite_version" 'fetch_updates'
  else
    clean_and_update_repo "$aseprite_version"
  fi
  if [ "$?" != 0 ]; then
    printf '\n==== Error: An error occurred when managing aseprite repo\n'
    exit 1
  fi
  
  if [ "$1" = 'install' ]; then
    # just check out a random depot_tools commit that is known to work
    #cd "${depot_tools_dir}"
    #if ! check_repo_urls 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'; then
    #  printf '\n==== Error: depot_tools git repository url does not match\n'
    #  exit 1
    #fi
    #
    #clean_and_update_repo 'b073999c6f90103a36a923e63ae8cf7a5c9c6c8c'
    #if [ "$?" != 0 ]; then
    #  printf '\n==== Error: An error occurred when managing depot_tools repo\n'
    #  exit 1
    #fi
    
    printf '\n======== Checking out commit aseprite-m81 skia was forked from\n'
    cd "${skia_src_dir}"
    if ! check_repo_urls 'https://skia.googlesource.com/skia.git'; then
      printf '\n==== Error: skia git repository url does not match\n'
      exit 1
    fi
    
    clean_and_update_repo '3e98c0e1d11516347ecc594959af2c1da4d04fc9'
    if [ "$?" != 0 ]; then
      printf '\n==== Error: An error occurred when managing skia repo\n'
      exit 1
    fi
    
    PATH="${PATH}:${temp_bin_dir}" python tools/git-sync-deps
    
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
    cd "${skia_src_dir}"
    PATH="${PATH}:${temp_bin_dir}" bin/gn gen "${skia_build_dir}" \
      --args='is_debug=false is_official_build=true skia_use_sfntly=false skia_use_dng_sdk=false skia_use_piex=false'
    cd "${skia_build_dir}"
    ninja -C "${skia_build_dir}" skia modules
    
    printf '\n======== Moving built skia into skia install directory\n'
    mkdir "${skia_install_dir}/lib"
    mv "${skia_build_dir}"/*.a "${skia_install_dir}/lib"
    cd "${skia_src_dir}"
    cp -R --parents \
      include \
      modules/particles/include/*.h \
      modules/skottie/include/*.h \
      modules/skresources/include/*.h \
      modules/sksg/include/*.h \
      modules/skshaper/include/*.h \
      "${skia_install_dir}"
    
    printf '\n======== Generating skia-aseprite-m81 checksums\n'
    cd "${skia_install_dir}"
    sha256r "${aseprite_dir}/skia-aseprite-m81-sha256sums.txt"
    
  else if [ "$1" = 'update' ]; then
    # TODO: need a better way to check if skia installation matches checksums
    if ! cd "${skia_install_dir}" \
       || ! sha256sum -c --quiet "${aseprite_dir}/skia-aseprite-m81-sha256sums.txt"; then
      printf '\n==== Error: Skia installation does not match checksums\n'
      exit 1
    fi
  fi
  
  printf '\n======== Building aseprite\n'
  cd "${ase_build_dir}"
  # enable shared libraries not in universe repo
  # disable network stuff (news and updates)
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DLAF_BACKEND=skia \
        -DSKIA_DIR="${skia_install_dir}" \
        -DSKIA_LIBRARY_DIR="${skia_install_dir}/lib" \
        -DSKIA_LIBRARY="${skia_install_dir}/lib/libskia.a" \
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
        "${ase_src_dir}"
  ninja aseprite
  
  printf '\n======== Moving built aseprite into aseprite install directory\n'
  mv --no-target-directory "${ase_build_dir}/bin" "${ase_install_dir}/bin"
  mv --no-target-directory "${ase_build_dir}/lib" "${ase_install_dir}/lib"
  cp --no-target-directory "${skia_install_dir}/lib" "${ase_install_dir}/lib/skia"
  
  printf '\n======== Generating aseprite checksums\n'
  cd "${ase_install_dir}"
  sha256r "${aseprite_dir}/aseprite-${aseprite_version}-sha256sums.txt"
  
  
  printf '\n======== Cleaning up\n'
  rm -R "${build_dir}" "${temp_bin_dir}"
  if [ "$4" = 'keep_sources' ]; then
    printf '\n==== Keeping source repos\n'
  else
    rm -R "${src_dir}"
  fi
  
  
  printf '\n======== Creating application launcher\n'
  launcher_path="${HOME}/.local/share/applications/org.aseprite.desktop"
  launcher_text="[Desktop Entry]
Type=Application
Name=Aseprite
Comment=Animated Sprite Editor & Pixel Art Tool
Icon=${ase_install_dir}/bin/data/icons/ase256.png
Exec=${ase_install_dir}/bin/aseprite
Path=${ase_install_dir}
Terminal=false
Category=Graphics;"
  
  if [ -e "${launcher_path}" ]; then
    # TODO: If launcher exists, should check if valid and if so then update install path
    # edit: actually that might be difficult because filenames can have newlines...
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
  printf '  4 = where to create (or find existing) installation directory\n'
  printf '  5 = "keep_sources" will keep source repos after building, all other values ignored\n'
  exit 0
fi

action=''
version=''
install_parent_dir=''
keep_sources=''

if [ "$5" = 'keep_sources' ]; then
  keep_sources='keep_sources'
fi

if [ -d "$4" ]; then
  install_parent_dir="$4"
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
    printf '\nError: 2nd argument must be install or update\n'
    exit 1
  ;;
esac

case "$1" in
  'aseprite')
    manage_aseprite "$action" "$version" "$install_parent_dir" "$keep_sources"
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
