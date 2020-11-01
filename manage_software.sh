#!/bin/bash

# make bash stricter about errors
#set -e -o pipefail

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
  repo_dir="${PWD}/.git"
  [ "$(git --git-dir="${repo_dir}" config --get remote.origin.url)" = "$1" ] \
  && [ "$(git --git-dir="${repo_dir}" remote get-url --all origin)" = "$1" ] \
   && [ "$(git --git-dir="${repo_dir}" ls-remote --get-url origin)" = "$1" ]
}

# arguments:
# 1 = sha1 hash of git repo to checkout
# 2 = 'skip_update' to skip fetch remote changes, otherwise ignored
# must be run in top level of working tree
clean_and_update_repo() {
  repo_dir="${PWD}/.git"
  if ! is_valid_sha1 "$1"; then
    printf '\n==== Error: commit is not a valid sha1 hash\n'
    exit 1
  fi
  git --git-dir="${repo_dir}" clean --quiet -d -f -f -x
  if [ "$2" != 'skip_update' ]; then
    git --git-dir="${repo_dir}" fetch --recurse-submodules=on-demand
    if [ "$?" != 0 ]; then
      printf '\n==== Warning: Could not fetch updates\n'
    fi
  fi
  git --git-dir="${repo_dir}" checkout --force --recurse-submodules "$1"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not checkout specified commit\n'
    exit 1
  fi
  git --git-dir="${repo_dir}" submodule deinit --force --all
  git --git-dir="${repo_dir}" reset --hard --recurse-submodules "$1"
  git --git-dir="${repo_dir}" clean -d -f -f -x
  git --git-dir="${repo_dir}" checkout --force --recurse-submodules "$1"
  git --git-dir="${repo_dir}" submodule update --init --force --checkout --recursive --
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not checkout submodules\n'
    exit 1
  fi
}

# arguments:
# 1 = output file path
# 2 = output text
save_launcher() {
  if [ -e "${1}" ]; then
    if [ -f "${1}" ] \
    && [ "$(head --lines=1 "${1}")" = '[Desktop Entry]' ]; then
      printf '\n==== Overwriting old launcher\n'
      printf '%s\n' "$2" > "${1}"
    else
      printf '\n==== Launcher not created, unknown file with that name already exists\n'
    fi
  else
    printf '%s\n' "$2" > "${1}"
  fi
}




# manage_blender arguments:
# 1 = version (default or blender version number)
manage_blender() {
  case "$1" in
    'default' | '2.90.1')
      printf '\n======== Defaulting to Blender version 2.90.1\n'
      blender_version='2.90.1'
      blender_sha256='054668c46a3e56921f283709f51a35f7860786183001cf2ea9be3249d13ac667'
      blender_dl_url='Blender2.90/blender-2.90.1-linux64.tar.xz'
    ;;
    *)
      printf '\n======== Error: Unknown Blender version number\n'
      exit 1
    ;;
  esac
  
  
  printf '\n======== Checking directories\n'
  blender_dir="${PWD}/blender"
  install_dir="${blender_dir}/blender-${blender_version}-linux64"
  
  if [ ! -d "${blender_dir}" ] && ! mkdir "${blender_dir}"; then
    printf '\n==== Error: Could not create blender directory\n'
    exit 1
  fi
  if [ -e "${install_dir}" ]; then
    printf '\n==== Error: Install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${install_dir}"
    exit 1
  fi
  
  
  printf '\n======== Downloading Blender\n'
  cd "${blender_dir}"
  wget --execute robots=off --output-document='dl-temp.tar.xz' \
       --no-clobber --no-use-server-timestamps --https-only \
       "https://download.blender.org/release/${blender_dl_url}"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not download Blender\n'
    exit 1
  fi
  
  printf '\n======== Verifying download matches Blender %s sha256 checksum:\n' "$blender_version"
  printf '==== %s\n' "$blender_sha256"
  printf '\n======== Downloaded file checksum is:\n'
  cd "${blender_dir}"
  sha256sum 'dl-temp.tar.xz'
  
  printf '%s  dl-temp.tar.xz\n' "$blender_sha256" | sha256sum --check
  if [ "$?" != 0 ]; then
    printf '\n======== Error: Download does not match checksum\n'
    rm -f -- "${blender_dir}/dl-temp.tar.xz"
    exit 1
  fi
  
  
  printf '\n======== Extracting Blender:\n'
  tar --extract --keep-old-files --one-top-level="blender-${blender_version}-linux64" --restrict \
      --file='dl-temp.tar.xz'
  
  printf '\n======== Generating checksums\n'
  cd "${install_dir}"
  sha256r "blender-${blender_version}-linux64-sha256sums.txt"
  
  
  printf '\n======== Cleaning up\n'
  rm -f -- "${blender_dir}/dl-temp.tar.xz"
  
  
  printf '\n======== Creating application launcher\n'
  launcher_path="${HOME}/.local/share/applications/org.blender.desktop"
  launcher_text="[Desktop Entry]
Type=Application
Name=Blender
Comment=Free and open source 3D creation suite
Icon=${install_dir}/blender.svg
Exec=${install_dir}/blender
Path=${install_dir}
Terminal=false
Category=Video;Graphics;"
  
  save_launcher "${launcher_path}" "$launcher_text"
}




# manage_lmms arguments:
# 1 = version (default or lmms version number)
manage_lmms() {
  case "$1" in
    'default' | '1.2.2')
      printf '\n======== Defaulting to LMMS version 1.2.2\n'
      lmms_version='1.2.2'
      lmms_commit_sha1='94363be152f526edba4e884264d891f1361cf54b'
      lmms_sha256='6cdc45a0699b8cd85295c49bcac03fcce6f3d8ffd7da23d646d0cb4258869b76'
      lmms_dl_url='v1.2.2/lmms-1.2.2-linux-x86_64.AppImage'
    ;;
    *)
      printf '\n======== Error: Unknown LMMS version number\n'
      exit 1
    ;;
  esac
  lmms_icon_sha256='e0d9507eabd86a79546bd948683ed83ec0eb5c569fee52cbad64bf957f362f20'
  lmms_icon_url='data/themes/default/icon.png'
  
  
  printf '\n======== Checking directories\n'
  lmms_dir="${PWD}/lmms"
  install_dir="${lmms_dir}/lmms-${lmms_version}-linux-x86_64"
  
  if [ ! -d "${lmms_dir}" ] && ! mkdir "${lmms_dir}"; then
    printf '\n==== Error: Could not create lmms directory\n'
    exit 1
  fi
  if [ -e "${install_dir}" ]; then
    printf '\n==== Error: Install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${install_dir}"
    exit 1
  fi
  
  
  printf '\n======== Downloading LMMS\n'
  cd "${lmms_dir}"
  wget --execute robots=off --output-document='dl-temp' \
       --no-clobber --no-use-server-timestamps --https-only \
       "https://github.com/LMMS/lmms/releases/download/${lmms_dl_url}"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not download LMMS\n'
    exit 1
  fi
  
  printf '\n======== Verifying download matches LMMS %s sha256 checksum:\n' "$lmms_version"
  printf '==== %s\n' "$lmms_sha256"
  printf '\n======== Downloaded file checksum is:\n'
  cd "${lmms_dir}"
  sha256sum 'dl-temp'
  
  printf '%s  dl-temp\n' "$lmms_sha256" | sha256sum --check
  if [ "$?" != 0 ]; then
    printf '\n======== Error: Download does not match checksum\n'
    rm -f -- "${lmms_dir}/dl-temp"
    exit 1
  fi
  
  
  printf '\n======== Downloading icon\n'
  cd "${lmms_dir}"
  wget --execute robots=off --output-document='icon.png' \
       --no-clobber --no-use-server-timestamps --https-only \
       "https://raw.githubusercontent.com/LMMS/lmms/${lmms_commit_sha1}/${lmms_icon_url}"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not download icon\n'
    exit 1
  fi
  
  printf '\n======== Verifying download matches icon sha256 checksum:\n'
  printf '==== %s\n' "$lmms_icon_sha256"
  printf '\n======== Downloaded file checksum is:\n'
  cd "${lmms_dir}"
  sha256sum 'icon.png'
  
  printf '%s  icon.png\n' "$lmms_icon_sha256" | sha256sum --check
  if [ "$?" != 0 ]; then
    printf '\n======== Error: Download does not match checksum\n'
    rm -f -- "${lmms_dir}/icon.png"
    exit 1
  fi
  
  
  printf '\n======== Installing LMMS:\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create install directory\n'
    exit 1
  fi
  mv --no-target-directory "${lmms_dir}/dl-temp" "${install_dir}/lmms-${lmms_version}-linux-x86_64.AppImage"
  mv --no-target-directory "${lmms_dir}/icon.png" "${install_dir}/icon.png"
  chmod +x "${install_dir}/lmms-${lmms_version}-linux-x86_64.AppImage"
  
  
  printf '\n======== Creating application launcher\n'
  launcher_path="${HOME}/.local/share/applications/io.lmms.desktop"
  launcher_text="[Desktop Entry]
Type=Application
Name=LMMS
Comment=Free, open source, multiplatform digital audio workstation
Icon=${install_dir}/icon.png
Exec=${install_dir}/lmms-${lmms_version}-linux-x86_64.AppImage
Path=${install_dir}
Terminal=false
Category=Audio;"
  
  save_launcher "${launcher_path}" "$launcher_text"
}




# manage_krita arguments:
# 1 = version (default or krita version number)
manage_krita() {
  case "$1" in
    'default' | '4.4.1')
      printf '\n======== Defaulting to krita version 4.4.1\n'
      krita_version='4.4.1'
      krita_commit_sha1='fe63f49aea3cfbc3f04717883a67731f41531eae'
      krita_sha256='c995f6a15499cfd4e5b3dc84bae44625f14a4c287da50003d6bb7f8b57feff08'
      krita_dl_url='stable/krita/4.4.1/krita-4.4.1-x86_64.appimage'
    ;;
    *)
      printf '\n======== Error: Unknown krita version number\n'
      exit 1
    ;;
  esac
  krita_icon_sha256='86ba89aadd20e9bf076c0721f0700c7fb4eaf6acc26e602c363277368c2373b4'
  krita_icon_url='krita/pics/app/256-apps-krita.png'
  
  printf '\n======== Checking directories\n'
  krita_dir="${PWD}/krita"
  install_dir="${krita_dir}/krita-${krita_version}-x86_64"
  
  if [ ! -d "${krita_dir}" ] && ! mkdir "${krita_dir}"; then
    printf '\n==== Error: Could not create krita directory\n'
    exit 1
  fi
  if [ -e "${install_dir}" ]; then
    printf '\n==== Error: Install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${install_dir}"
    exit 1
  fi
  
  
  printf '\n======== Downloading krita\n'
  cd "${krita_dir}"
  wget --execute robots=off --output-document='dl-temp' \
       --no-clobber --no-use-server-timestamps --https-only \
       "https://download.kde.org/${krita_dl_url}"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not download krita\n'
    exit 1
  fi
  
  printf '\n======== Verifying download matches krita %s sha256 checksum:\n' "$krita_version"
  printf '==== %s\n' "$krita_sha256"
  printf '\n======== Downloaded file checksum is:\n'
  cd "${krita_dir}"
  sha256sum 'dl-temp'
  
  printf '%s  dl-temp\n' "$krita_sha256" | sha256sum --check
  if [ "$?" != 0 ]; then
    printf '\n======== Error: Download does not match checksum\n'
    rm -f -- "${krita_dir}/dl-temp"
    exit 1
  fi
  
  
  printf '\n======== Downloading icon\n'
  cd "${krita_dir}"
  wget --execute robots=off --output-document='icon.png' \
       --no-clobber --no-use-server-timestamps --https-only \
       "https://invent.kde.org/graphics/krita/-/raw/${krita_commit_sha1}/${krita_icon_url}"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: Could not download icon\n'
    exit 1
  fi
  
  printf '\n======== Verifying download matches icon sha256 checksum:\n'
  printf '==== %s\n' "$krita_icon_sha256"
  printf '\n======== Downloaded file checksum is:\n'
  cd "${krita_dir}"
  sha256sum 'icon.png'
  
  printf '%s  icon.png\n' "$krita_icon_sha256" | sha256sum --check
  if [ "$?" != 0 ]; then
    printf '\n======== Error: Download does not match checksum\n'
    rm -f -- "${krita_dir}/icon.png"
    exit 1
  fi
  
  
  printf '\n======== Installing krita:\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create install directory\n'
    exit 1
  fi
  mv --no-target-directory "${krita_dir}/dl-temp" "${install_dir}/krita-${krita_version}-x86_64.appimage"
  mv --no-target-directory "${krita_dir}/icon.png" "${install_dir}/icon.png"
  chmod +x "${install_dir}/krita-${krita_version}-x86_64.appimage"
  
  
  printf '\n======== Creating application launcher\n'
  launcher_path="${HOME}/.local/share/applications/org.krita.desktop"
  launcher_text="[Desktop Entry]
Type=Application
Name=Krita
Comment=Free and open source painting and drawing program
Icon=${install_dir}/icon.png
Exec=${install_dir}/krita-${krita_version}-x86_64.appimage
Path=${install_dir}
Terminal=false
Category=Graphics;"
  
  save_launcher "${launcher_path}" "$launcher_text"
}




# manage_mozjpeg arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_mozjpeg() {
  printf 'mozjpeg stuff is unfinished/untested\n'
  exit 1
  
  case "$1" in
    'default')
      # TODO: update this with latest release
      exit 1
      printf '\n======== Defaulting to mozjpeg version\n'
      mozjpeg_version=''
    ;;
    *)
      if is_valid_sha1 "$1"; then
        mozjpeg_version="$1"
      else
        printf '\n======== Error: mozjpeg version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  mozjpeg_dir="${PWD}/mozjpeg"
  
  install_dir="${mozjpeg_dir}/mozjpeg-${mozjpeg_version}"
  build_dir="${mozjpeg_dir}/build"
  src_dir="${mozjpeg_dir}/src"
  
  mozjpeg_src_dir="${src_dir}/mozjpeg"
  
  if [ ! -d "${mozjpeg_dir}" ] && ! mkdir "${mozjpeg_dir}"; then
    printf '\n==== Error: Could not create mozjpeg directory\n'
    exit 1
  fi
  if [ -e "${install_dir}" ]; then
    printf '\n==== Error: Install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${install_dir}"
    exit 1
  fi
  if [ -e "${build_dir}" ]; then
    printf '\n==== Error: Build directory already exists\n'
    printf '==== Please delete existing build directory and try again:\n'
    printf '%s\n' "${build_dir}"
    exit 1
  fi
  if [ ! -d "${src_dir}" ] && ! mkdir "${src_dir}"; then
    printf '\n==== Error: Could not create src directory\n'
    exit 1
  fi
  
  
  if [ ! -e "${mozjpeg_src_dir}" ]; then
    printf '\n======== Cloning mozjpeg git repository\n'
    cd "${src_dir}"
    git clone --no-checkout 'https://github.com/mozilla/mozjpeg.git'
    if [ "$?" != 0 ]; then
      printf '\n==== Error: Could not clone mozjpeg git repository\n'
      exit 1
    fi
    fetch_updates='skip_update'
  fi
  
  printf '\n======== Checking out mozjpeg commit\n======== %s\n' "$mozjpeg_version"
  if [ ! -d "${mozjpeg_src_dir}/.git" ] || ! cd "${mozjpeg_src_dir}"; then
    printf '\n==== Error: mozjpeg repo is missing or invalid\n'
    exit 1
  fi
  if ! check_repo_urls 'https://github.com/mozilla/mozjpeg.git'; then
    printf '\n==== Error: Repo url does not match mozjpeg url\n'
    exit 1
  fi
  clean_and_update_repo "$mozjpeg_version" "$fetch_updates"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: An error occurred when managing mozjpeg repo\n'
    exit 1
  fi
  
  
  printf '\n======== Building mozjpeg\n'
  if ! mkdir "${build_dir}"; then
    printf '\n==== Error: Could not create build directory\n'
    exit 1
  fi
  cd "${build_dir}"
  cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE='Release' "${mozjpeg_src_dir}"
  make
  
  # TODO: copy final build into install directory and generate checksums
  #       (or install with the cmake variable? see mozjpeg readme)
  
  #printf '\n======== Moving mozjpeg build to install directory\n'
  #if ! mkdir "${install_dir}"; then
  #  printf '\n==== Error: Could not create mozjpeg install directory\n'
  #  exit 1
  #fi
  
  #printf '\n======== Generating checksums\n'
  #cd "${install_dir}"
  #sha256r "mozjpeg-${mozjpeg_version}-sha256sums.txt"
  
  
  printf '\n======== Cleaning up\n'
  # TODO: uncomment when figured out installation
  #rm -R -f -- "${build_dir}"
  if [ "$2" != 'keep_sources' ]; then
    rm -R -f -- "${src_dir}"
  else
    printf '\n==== Keeping source repos\n'
  fi
}




# manage_godot arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_godot() {
  case "$1" in
    'default')
      printf '\n======== Defaulting to godot version 3.2.3\n'
      godot_version='31d0f8ad8d5cf50a310ee7e8ada4dcdb4510690b'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        godot_version="$1"
      else
        printf '\n======== Error: godot version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  godot_dir="${PWD}/godot"
  
  install_dir="${godot_dir}/godot-${godot_version}"
  src_dir="${godot_dir}/src"
  
  godot_src_dir="${src_dir}/godot"
  
  if [ ! -d "${godot_dir}" ] && ! mkdir "${godot_dir}"; then
    printf '\n==== Error: Could not create godot directory\n'
    exit 1
  fi
  if [ -e "${install_dir}" ]; then
    printf '\n==== Error: Install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${install_dir}"
    exit 1
  fi
  if [ ! -d "${src_dir}" ] && ! mkdir "${src_dir}"; then
    printf '\n==== Error: Could not create src directory\n'
    exit 1
  fi
  
  
  if [ ! -e "${godot_src_dir}" ]; then
    printf '\n======== Cloning godot git repository\n'
    cd "${src_dir}"
    git clone --no-checkout 'https://github.com/godotengine/godot.git'
    if [ "$?" != 0 ]; then
      printf '\n==== Error: Could not clone godot git repository\n'
      exit 1
    fi
    fetch_updates='skip_update'
  fi
  
  printf '\n======== Checking out godot commit\n======== %s\n' "$godot_version"
  if [ ! -d "${godot_src_dir}/.git" ] || ! cd "${godot_src_dir}"; then
    printf '\n==== Error: godot repo is missing or invalid\n'
    exit 1
  fi
  if ! check_repo_urls 'https://github.com/godotengine/godot.git'; then
    printf '\n==== Error: Repo url does not match godot url\n'
    exit 1
  fi
  clean_and_update_repo "$godot_version" "$fetch_updates"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: An error occurred when managing godot repo\n'
    exit 1
  fi
  
  printf '\n======== Building godot\n'
  cd "${godot_src_dir}"
  # TODO: switch to this for godot 4:
  #platform=linuxbsd
  scons -j 3 platform=x11 target=release_debug tools=yes debug_symbols=no use_lto=yes
  #      builtin_certs=no \
  #      builtin_freetype=no \
  #      builtin_libogg=no \
  #      builtin_libpng=no \
  #      builtin_libtheora=no \
  #      builtin_libvorbis=no \
  #      builtin_libvpx=no \
  #      builtin_libwebp=no \
  #      builtin_miniupnpc=no \
  #      builtin_opus=no \
  #      builtin_pcre2=no \
  #      builtin_pcre2_with_jit=no \
  #      builtin_zlib=no \
  #      builtin_zstd=no
  
  
  printf '\n======== Stripping debug symbols\n'
  strip --strip-all "${godot_src_dir}/bin/godot.x11.opt.tools.64"
  
  printf '\n======== Moving godot build to install directory\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create install directory\n'
    exit 1
  fi
  mv "${godot_src_dir}/bin/godot.x11.opt.tools.64" "${install_dir}"
  cp "${godot_src_dir}/main/app_icon.png" "${install_dir}"
  
  printf '\n======== Generating checksums\n'
  cd "${install_dir}"
  sha256r "godot-${godot_version}-sha256sums.txt"
  
  
  printf '\n======== Cleaning up\n'
  if [ "$2" != 'keep_sources' ]; then
    rm -R -f -- "${src_dir}"
  else
    printf '\n==== Keeping source repo\n'
    cd "${godot_src_dir}"
    clean_and_update_repo "$godot_version"
  fi
  
  
  printf '\n======== Creating application launcher\n'
  launcher_path="${HOME}/.local/share/applications/org.godotengine.desktop"
  launcher_text="[Desktop Entry]
Type=Application
Name=Godot Engine
Comment=2D and 3D cross-platform game engine
Icon=${install_dir}/app_icon.png
Exec=${install_dir}/godot.x11.opt.tools.64
Path=${install_dir}
Terminal=false
Category=Development;Game;Graphics;"
  
  save_launcher "${launcher_path}" "$launcher_text"
}




# manage_aseprite arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_aseprite() {
  case "$1" in
    'default')
      printf '\n======== Defaulting to aseprite version 1.2.25\n'
      aseprite_version='f44aad06db9d7a7efe9beb0038df37140ac9c2ba'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        aseprite_version="$1"
      else
        printf '\n======== Error: aseprite version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  aseprite_dir="${PWD}/aseprite"
  
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
  
  if [ ! -d "${aseprite_dir}" ] && ! mkdir "${aseprite_dir}"; then
    printf '\n==== Error: Could not create aseprite directory\n'
    exit 1
  fi
  if [ -e "${ase_install_dir}" ]; then
    printf '\n==== Error: Aseprite install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${ase_install_dir}"
    exit 1
  fi
  if [ -e "${build_dir}" ]; then
    printf '\n==== Error: Build directory already exists\n'
    printf '==== Please delete existing build directory and try again:\n'
    printf '%s\n' "${build_dir}"
    exit 1
  fi
  if ! mkdir "${build_dir}"; then
    printf '\n==== Error: Could not create build directory\n'
    exit 1
  fi
  if [ ! -d "${src_dir}" ] && ! mkdir "${src_dir}"; then
    printf '\n==== Error: Could not create src directory\n'
    exit 1
  fi
  
  
  # in case python doesn't point to python2 binary,
  # set up a temp folder with a link to temporarily add to path
  if ! mkdir "${temp_bin_dir}"; then
    printf '\n==== Error: Could not create temporary bin directory\n'
    exit 1
  fi
  ln -s '/usr/bin/python2' "${temp_bin_dir}/python"
  
  
  if [ -e "${skia_install_dir}" ]; then
    printf '\n======== Skia install directory found. Verifying checksums...\n'
    # TODO: need a better way to check if skia installation matches checksums
    if ! cd "${skia_install_dir}" \
       || ! sha256sum --check --quiet "${skia_install_dir}/skia-aseprite-m81-sha256sums.txt"; then
      printf '\n==== Error: Skia installation does not match checksums\n'
      exit 1
    fi
  else
    #if [ ! -e "${depot_tools_dir}" ]; then
    #  printf '\n======== Cloning depot_tools git repository\n'
    #  cd "${src_dir}"
    #  git clone --no-checkout 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'
    #  if [ "$?" != 0 ]; then
    #    printf '\n==== Error: Could not clone depot_tools git repository\n'
    #    exit 1
    #  fi
    #  fetch_depot_tools_updates='skip_update'
    #fi
    #
    # just check out a random depot_tools commit that is known to work
    #if [ ! -d "${depot_tools_dir}/.git" ] || ! cd "${depot_tools_dir}"; then
    #  printf '\n==== Error: depot_tools repo is missing or invalid\n'
    #  exit 1
    #fi
    #if ! check_repo_urls 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'; then
    #  printf '\n==== Error: Repo url does not match depot_tools url\n'
    #  exit 1
    #fi
    #clean_and_update_repo 'b073999c6f90103a36a923e63ae8cf7a5c9c6c8c' "$fetch_depot_tools_updates"
    #if [ "$?" != 0 ]; then
    #  printf '\n==== Error: An error occurred when managing depot_tools repo\n'
    #  exit 1
    #fi
    
    if [ ! -e "${skia_src_dir}" ]; then
      printf '\n======== Cloning skia git repository\n'
      cd "${src_dir}"
      git clone --no-checkout 'https://skia.googlesource.com/skia.git'
      if [ "$?" != 0 ]; then
        printf '\n==== Error: Could not clone skia git repository\n'
        exit 1
      fi
      fetch_skia_updates='skip_update'
    fi
    
    printf '\n======== Checking out commit aseprite-m81 skia was forked from\n'
    if [ ! -d "${skia_src_dir}/.git" ] || ! cd "${skia_src_dir}"; then
      printf '\n==== Error: skia repo is missing or invalid\n'
      exit 1
    fi
    if ! check_repo_urls 'https://skia.googlesource.com/skia.git'; then
      printf '\n==== Error: Repo url does not match skia url\n'
      exit 1
    fi
    clean_and_update_repo '3e98c0e1d11516347ecc594959af2c1da4d04fc9' "$fetch_skia_updates"
    if [ "$?" != 0 ]; then
      printf '\n==== Error: An error occurred when managing skia repo\n'
      exit 1
    fi
    
    printf '\n==== Syncing skia dependencies\n'
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
    if ! mkdir "${skia_build_dir}"; then
      printf '\n==== Error: Could not create skia build directory\n'
      exit 1
    fi
    cd "${skia_src_dir}"
    PATH="${PATH}:${temp_bin_dir}" bin/gn gen "${skia_build_dir}" \
      --args='is_debug=false is_official_build=true skia_use_sfntly=false skia_use_dng_sdk=false skia_use_piex=false'
    cd "${skia_build_dir}"
    ninja -C "${skia_build_dir}" skia modules
    
    
    printf '\n======== Moving skia build to skia install directory\n'
    if ! mkdir "${skia_install_dir}"; then
      printf '\n==== Error: Could not create skia install directory\n'
      exit 1
    fi
    # TODO: make library directory dynamic to handle other architectures
    mkdir "${skia_install_dir}/lib" "${skia_install_dir}/lib/x86_64-linux-gnu"
    mv "${skia_build_dir}"/*.a "${skia_install_dir}/lib/x86_64-linux-gnu"
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
    sha256r 'skia-aseprite-m81-sha256sums.txt'
  fi
  
  if [ ! -e "${ase_src_dir}" ]; then
    printf '\n======== Cloning aseprite git repository\n'
    cd "${src_dir}"
    git clone --no-checkout 'https://github.com/aseprite/aseprite.git'
    if [ "$?" != 0 ]; then
      printf '\n==== Error: Could not clone aseprite git repository\n'
      exit 1
    fi
    fetch_aseprite_updates='skip_update'
  fi
  
  printf '\n======== Checking out aseprite commit\n======== %s\n' "$aseprite_version"
  if [ ! -d "${ase_src_dir}/.git" ] || ! cd "${ase_src_dir}"; then
    printf '\n==== Error: aseprite repo is missing or invalid\n'
    exit 1
  fi
  if ! check_repo_urls 'https://github.com/aseprite/aseprite.git'; then
    printf '\n==== Error: Repo url does not match aseprite url\n'
    exit 1
  fi
  clean_and_update_repo "$aseprite_version" "$fetch_aseprite_updates"
  if [ "$?" != 0 ]; then
    printf '\n==== Error: An error occurred when managing aseprite repo\n'
    exit 1
  fi
  
  printf '\n======== Building aseprite\n'
  if ! mkdir "${ase_build_dir}"; then
    printf '\n==== Error: Could not create aseprite build directory\n'
    exit 1
  fi
  cd "${ase_build_dir}"
  # enable shared libraries not in universe repo
  # disable network stuff (news and updates)
  cmake -DCMAKE_BUILD_TYPE=Release \
        -DLAF_BACKEND=skia \
        -DSKIA_DIR="${skia_install_dir}" \
        -DSKIA_LIBRARY_DIR="${skia_install_dir}/lib/x86_64-linux-gnu" \
        -DSKIA_LIBRARY="${skia_install_dir}/lib/x86_64-linux-gnu/libskia.a" \
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
  
  
  printf '\n======== Moving aseprite build to aseprite install directory\n'
  if ! mkdir "${ase_install_dir}"; then
    printf '\n==== Error: Could not create aseprite install directory\n'
    exit 1
  fi
  mv --no-target-directory "${ase_build_dir}/bin" "${ase_install_dir}/bin"
  mv --no-target-directory "${ase_build_dir}/lib" "${ase_install_dir}/lib"
  cp "${skia_install_dir}"/lib/x86_64-linux-gnu/*.a "${ase_install_dir}/lib"
  
  printf '\n======== Generating aseprite checksums\n'
  cd "${ase_install_dir}"
  sha256r "aseprite-${aseprite_version}-sha256sums.txt"
  
  
  printf '\n======== Cleaning up\n'
  rm -R -f -- "${build_dir}" "${temp_bin_dir}"
  if [ "$2" != 'keep_sources' ]; then
    rm -R -f -- "${src_dir}"
  else
    printf '\n==== Keeping source repos\n'
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
  
  save_launcher "${launcher_path}" "$launcher_text"
}




# Process input
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Usage:\n'
  printf 'manage_software.sh 1 2 3 4 (5)\n'
  printf '  1 = software name [ aseprite | godot | mozjpeg | krita | lmms | blender ]\n'
  printf '  2 = software version [ default | (a git commit sha1) | (a version number) ]\n'
  printf '  3 = where to create (or find existing) installation directory\n'
  printf '  4 = "keep_sources" will keep source repos after install, otherwise ignored\n'
  exit 0
fi


keep_sources=''
if [ "$4" = 'keep_sources' ]; then
  keep_sources='keep_sources'
fi

if [ ! -d "${3}" ] || ! cd "${3}"; then
  printf '\n======== Error: Specified directory is invalid or inaccessible\n'
  exit 1
fi

version="$2"

case "$1" in
  'aseprite')
    manage_aseprite "$version" "$keep_sources"
  ;;
  'godot')
    manage_godot "$version" "$keep_sources"
  ;;
  'mozjpeg')
    manage_mozjpeg "$version" "$keep_sources"
  ;;
  'krita')
    manage_krita "$version"
  ;;
  'lmms')
    manage_lmms "$version"
  ;;
  'blender')
    manage_blender "$version"
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
