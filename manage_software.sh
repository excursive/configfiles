#!/bin/bash

# make bash stricter about errors
#set -e -o pipefail

is_valid_sha1() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:xdigit:]]{40}$'
  [[ "$1" =~ $regex ]]
}

is_valid_sha256() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:xdigit:]]{64}$'
  [[ "$1" =~ $regex ]]
}

contains_nl_or_bs() {
  [[ "$1" =~ $'\n' ]] || [[ "$1" =~ $'\\' ]]
}

sha256r() {
  if [ -n "${1}" ]; then
    local output="$(sha256r)"
    if [ -e "${1}" ]; then
      printf 'Error: Output file already exists\n'
      exit 1
    fi
    printf '%s\n' "$output" > "${1}"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty sha256sum
  fi
}

check_repo_urls() {
  local repo_dir="${PWD}/.git"
  [ "$(git --git-dir="${repo_dir}" config --get remote.origin.url)" = "$1" ] \
  && [ "$(git --git-dir="${repo_dir}" remote get-url --all origin)" = "$1" ] \
   && [ "$(git --git-dir="${repo_dir}" ls-remote --get-url origin)" = "$1" ]
}

# arguments:
# 1 = sha1 hash of git repo to checkout
# 2 = 'skip_update' to skip fetch remote changes, otherwise ignored
# must be run in top level of working tree
clean_and_update_repo() {
  local repo_dir="${PWD}/.git"
  if ! is_valid_sha1 "$1"; then
    printf '\n==== Error: commit is not a valid sha1 hash\n'
    exit 1
  fi
  git --git-dir="${repo_dir}" clean --quiet -d -f -f -x
  if [ "$2" != 'skip_update' ]; then
    git --git-dir="${repo_dir}" fetch --recurse-submodules=on-demand
    if [ "$?" -ne 0 ]; then
      printf '\n==== Warning: Could not fetch updates\n'
    fi
  fi
  git --git-dir="${repo_dir}" checkout --force --recurse-submodules "$1"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not checkout specified commit\n'
    exit 1
  fi
  git --git-dir="${repo_dir}" submodule deinit --force --all
  git --git-dir="${repo_dir}" reset --hard --recurse-submodules "$1"
  git --git-dir="${repo_dir}" clean -d -f -f -x
  git --git-dir="${repo_dir}" checkout --force --recurse-submodules "$1"
  git --git-dir="${repo_dir}" submodule update --init --force --checkout --recursive --
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not checkout submodules\n'
    exit 1
  fi
}

# checks out the given git commit, cloning/fetching updates as necessary
# afterwards, working directory will be the specified directory
# arguments:
# 1 = directory to clone into
# 2 = commit
# 3 = url
checkout_commit() {
  local dir="${1}"
  local commit="$2"
  local url="$3"
  if ! is_valid_sha1 "$commit"; then
    printf '\n==== Error: commit is not a valid sha1 hash\n'
    exit 1
  fi
  
  local fetch_updates=''
  if [ ! -e "${dir}" ]; then
    printf '\n======== Cloning git repository\n'
    git clone --no-checkout -- "$url" "${dir}"
    if [ "$?" -ne 0 ]; then
      printf '\n==== Error: Could not clone git repository\n'
      exit 1
    fi
    fetch_updates='skip_update'
  fi
  
  printf '\n======== Checking out git commit\n======== %s\n' "$commit"
  if [ ! -d "${dir}/.git" ] || ! cd "${dir}"; then
    printf '\n==== Error: git repo is missing or invalid\n'
    exit 1
  fi
  if ! check_repo_urls "$url"; then
    printf '\n==== Error: Repo url does not match specified url\n'
    exit 1
  fi
  clean_and_update_repo "$commit" "$fetch_updates"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not checkout specified commit\n'
    exit 1
  fi
}

# arguments:
# 1 = sha256 hash
# 2 = filename to save to
# 3 = download url
dl_and_verify_file() {
  if ! is_valid_sha256 "$1"; then
    printf '\n==== Error: Not a valid sha256 hash\n'
    exit 1
  fi
  if contains_nl_or_bs "${2}"; then
    printf '\n==== Error: Filename cannot contain newlines or backslashes\n'
    exit 1
  fi
  
  wget --execute robots=off --output-document="${2}" \
       --no-clobber --no-use-server-timestamps --https-only "$3"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not download %s\n' "${2}"
    exit 1
  fi
  
  printf '\n==== Verifying download matches specified sha256 checksum:\n'
  printf '%s\n' "$1"
  printf '\n==== Downloaded file checksum is:\n'
  sha256sum "${2}"
  
  printf '%s  %s\n' "$1" "${2}" | sha256sum --check
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Download does not match checksum\n'
    rm -f -- "${2}"
    exit 1
  fi
}

# arguments:
# 1 = output file path
# 2 = output text
save_desktop_entry() {
  if [ -e "${1}" ]; then
    if [ -f "${1}" ] \
    && [ "$(head --lines=1 "${1}")" = '[Desktop Entry]' ]; then
      printf '%s\n' "$2" > "${1}"
      printf '\n==== Replaced old launcher %s\n' "${1}"
    else
      printf '\n==== Warning: launcher not created, unknown file exists with that name:\n'
      printf '%s\n' "${1}"
      return 1
    fi
  else
    printf '%s\n' "$2" > "${1}"
  fi
}

# saves a launcher bash script to ~/bin
# arguments:
# 1 = launcher basename
# 2 = launcher script text
save_launcher_script() {
  local name="${1}"
  local contents="$2"
  local path="${HOME}/bin/${name}"
  if [ ! -d "${HOME}/bin" ] && ! mkdir "${HOME}/bin"; then
    printf '\n==== Warning: Could not create ~/bin directory to save launcher %s\n' "${name}"
    return 1
  fi
  if [ -e "${path}" ]; then
    if [ -f "${path}" ] \
    && [ "$(head --lines=1 "${path}")" = '#!/bin/bash' ]; then
      printf '%s\n' "$contents" > "${path}"
      chmod +x "${path}"
      printf '\n==== Replaced old launcher in ~/bin for %s\n' "${name}"
    else
      printf '\n==== Warning: launcher not created for %s\n' "${name}"
      printf   '====          unknown file with that name already exists in ~/bin\n'
      return 1
    fi
  else
    printf '%s\n' "$contents" > "${path}"
    chmod +x "${path}"
    printf '\n==== Created launcher in ~/bin for %s\n' "${name}"
  fi
}

# creates a symlink with the given name in ~/bin to target
# arguments:
# 1 = link target
# 2 = link name
create_symlink() {
  local target="${1}"
  local link_name="${2}"
  local link_path="${HOME}/bin/${link_name}"
  if [ ! -d "${HOME}/bin" ] && ! mkdir "${HOME}/bin"; then
    printf '\n==== Warning: Could not create ~/bin directory to save symlink %s\n' "${link_name}"
    return 1
  fi
  if [ -e "${link_path}" ]; then
    if [ -L "${link_path}" ]; then
      rm -f -- "${link_path}"
      ln -s --no-target-directory "${target}" "${link_path}"
      printf '\n==== Replaced old symlink in ~/bin for %s\n' "${link_name}"
    else
      printf '\n==== Warning: link not created for %s\n' "${link_name}"
      printf   '====          unknown file with that name already exists in ~/bin\n'
      return 1
    fi
  else
    ln -s --no-target-directory "${target}" "${link_path}"
    printf '\n==== Created symlink in ~/bin for %s\n' "${link_name}"
  fi
}

# creates symlinks in ~/bin to the given targets
# arguments:
# 1.. link targets
create_symlinks() {
  for target in "$@"; do
    local link_name="$(basename -- "${target}")"
    create_symlink "${target}" "${link_name}"
  done
}




# manage_blender arguments:
# 1 = version (default or blender version number)
manage_blender() {
  case "$1" in
    'default' | '2.90.1')
      printf '\n======== Defaulting to Blender version 2.90.1\n'
      local blender_version='2.90.1'
      local blender_sha256='054668c46a3e56921f283709f51a35f7860786183001cf2ea9be3249d13ac667'
      local blender_dl_url='Blender2.90/blender-2.90.1-linux64.tar.xz'
    ;;
    *)
      printf '\n======== Error: Unknown Blender version number\n'
      exit 1
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  local blender_dir="${PWD}/blender"
  local install_dir="${blender_dir}/blender-${blender_version}-linux64"
  
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
  dl_and_verify_file "$blender_sha256" "blender-${blender_version}-linux64.tar.xz" \
                     "https://download.blender.org/release/${blender_dl_url}"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not download Blender\n'
    exit 1
  fi
  
  printf '\n======== Extracting Blender:\n'
  tar --extract --keep-old-files --one-top-level="blender-${blender_version}-linux64" --restrict \
      --file="blender-${blender_version}-linux64.tar.xz"
  
  printf '\n======== Generating checksums\n'
  cd "${install_dir}"
  sha256r "blender-${blender_version}-linux64-sha256sums.txt"
  
  printf '\n======== Cleaning up\n'
  rm -f -- "${blender_dir}/blender-${blender_version}-linux64.tar.xz"
  
  printf '\n======== Creating application launcher\n'
  local launcher_path="${HOME}/.local/share/applications/org.blender.desktop"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Blender
Comment=Free and open source 3D creation suite
Icon=${install_dir}/blender.svg
Exec=${install_dir}/blender
Path=${install_dir}
Terminal=false
Category=Video;Graphics;"
  
  save_desktop_entry "${launcher_path}" "$launcher_text"
}




# manage_lmms arguments:
# 1 = version (default or lmms version number)
manage_lmms() {
  case "$1" in
    'default' | '1.2.2')
      printf '\n======== Defaulting to LMMS version 1.2.2\n'
      local lmms_version='1.2.2'
      local lmms_commit_sha1='94363be152f526edba4e884264d891f1361cf54b'
      local lmms_sha256='6cdc45a0699b8cd85295c49bcac03fcce6f3d8ffd7da23d646d0cb4258869b76'
      local lmms_dl_url='v1.2.2/lmms-1.2.2-linux-x86_64.AppImage'
    ;;
    *)
      printf '\n======== Error: Unknown LMMS version number\n'
      exit 1
    ;;
  esac
  local lmms_icon_sha256='e0d9507eabd86a79546bd948683ed83ec0eb5c569fee52cbad64bf957f362f20'
  local lmms_icon_url='data/themes/default/icon.png'
  
  printf '\n======== Checking directories\n'
  local lmms_dir="${PWD}/lmms"
  local install_dir="${lmms_dir}/lmms-${lmms_version}-linux-x86_64"
  
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
  dl_and_verify_file "$lmms_sha256" "lmms-${lmms_version}-linux-x86_64.AppImage" \
                     "https://github.com/LMMS/lmms/releases/download/${lmms_dl_url}"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not download LMMS\n'
    exit 1
  fi
  
  printf '\n======== Downloading icon\n'
  cd "${lmms_dir}"
  dl_and_verify_file "$lmms_icon_sha256" 'icon.png' \
                     "https://raw.githubusercontent.com/LMMS/lmms/${lmms_commit_sha1}/${lmms_icon_url}"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not download icon\n'
    exit 1
  fi
  
  printf '\n======== Installing LMMS:\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create install directory\n'
    exit 1
  fi
  mv --no-target-directory "${lmms_dir}/lmms-${lmms_version}-linux-x86_64.AppImage" \
                           "${install_dir}/lmms-${lmms_version}-linux-x86_64.AppImage"
  mv --no-target-directory "${lmms_dir}/icon.png" "${install_dir}/icon.png"
  chmod +x "${install_dir}/lmms-${lmms_version}-linux-x86_64.AppImage"
  
  
  printf '\n======== Creating application launcher\n'
  local launcher_path="${HOME}/.local/share/applications/io.lmms.desktop"
  local launcher_text="[Desktop Entry]
Type=Application
Name=LMMS
Comment=Free, open source, multiplatform digital audio workstation
Icon=${install_dir}/icon.png
Exec=${install_dir}/lmms-${lmms_version}-linux-x86_64.AppImage
Path=${install_dir}
Terminal=false
Category=Audio;"
  
  save_desktop_entry "${launcher_path}" "$launcher_text"
}




# manage_krita arguments:
# 1 = version (default or krita version number)
manage_krita() {
  case "$1" in
    'default' | '4.4.1')
      printf '\n======== Defaulting to krita version 4.4.1\n'
      local krita_version='4.4.1'
      local krita_commit_sha1='fe63f49aea3cfbc3f04717883a67731f41531eae'
      local krita_sha256='c995f6a15499cfd4e5b3dc84bae44625f14a4c287da50003d6bb7f8b57feff08'
      local krita_dl_url='stable/krita/4.4.1/krita-4.4.1-x86_64.appimage'
    ;;
    *)
      printf '\n======== Error: Unknown krita version number\n'
      exit 1
    ;;
  esac
  local krita_icon_sha256='86ba89aadd20e9bf076c0721f0700c7fb4eaf6acc26e602c363277368c2373b4'
  local krita_icon_url='krita/pics/app/256-apps-krita.png'
  
  printf '\n======== Checking directories\n'
  local krita_dir="${PWD}/krita"
  local install_dir="${krita_dir}/krita-${krita_version}-x86_64"
  
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
  dl_and_verify_file "$krita_sha256" "krita-${krita_version}-x86_64.appimage" \
                     "https://download.kde.org/${krita_dl_url}"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not download krita\n'
    exit 1
  fi
  
  printf '\n======== Downloading icon\n'
  cd "${krita_dir}"
  dl_and_verify_file "$krita_icon_sha256" 'icon.png' \
                     "https://invent.kde.org/graphics/krita/-/raw/${krita_commit_sha1}/${krita_icon_url}"
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not download icon\n'
    exit 1
  fi
  
  printf '\n======== Installing krita:\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create install directory\n'
    exit 1
  fi
  mv --no-target-directory "${krita_dir}/krita-${krita_version}-x86_64.appimage" \
                           "${install_dir}/krita-${krita_version}-x86_64.appimage"
  mv --no-target-directory "${krita_dir}/icon.png" "${install_dir}/icon.png"
  chmod +x "${install_dir}/krita-${krita_version}-x86_64.appimage"
  
  
  printf '\n======== Creating application launcher\n'
  local launcher_path="${HOME}/.local/share/applications/org.krita.desktop"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Krita
Comment=Free and open source painting and drawing program
Icon=${install_dir}/icon.png
Exec=${install_dir}/krita-${krita_version}-x86_64.appimage
Path=${install_dir}
Terminal=false
Category=Graphics;"
  
  save_desktop_entry "${launcher_path}" "$launcher_text"
}




# manage_rust arguments:
manage_rust() {
  local rust_installer_sha256='8928261388c8fae83bfd79b08d9030dfe21d17a8b59e9dcabda779213f6a3d14'
  printf '\n======== Downloading rust installer\n'
  dl_and_verify_file "$rust_installer_sha256" 'rustup-init.sh' \
                     'https://sh.rustup.rs/'
  if [ "$?" -ne 0 ]; then
    printf '\n==== Error: Could not download rust intsaller\n'
    exit 1
  fi
  
  printf '\n======== Installing rust\n'
  bash -- 'rustup-init.sh' --no-modify-path
  
  rm -f -- 'rustup-init.sh'
  
  create_symlinks "${HOME}/.cargo/bin/cargo" \
                  "${HOME}/.cargo/bin/cargo-clippy" \
                  "${HOME}/.cargo/bin/cargo-fmt" \
                  "${HOME}/.cargo/bin/cargo-miri" \
                  "${HOME}/.cargo/bin/clippy-driver" \
                  "${HOME}/.cargo/bin/rls" \
                  "${HOME}/.cargo/bin/rustc" \
                  "${HOME}/.cargo/bin/rustdoc" \
                  "${HOME}/.cargo/bin/rustfmt" \
                  "${HOME}/.cargo/bin/rust-gdb" \
                  "${HOME}/.cargo/bin/rust-lldb" \
                  "${HOME}/.cargo/bin/rustup"
}




# manage_youtube_dl arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_youtube_dl() {
  case "$1" in
    'default' | '2020.11.26')
      printf '\n======== Defaulting to youtube-dl version 2020.11.26\n'
      local youtube_dl_version='9fe50837c3e8f6c40b7bed8bf7105a868a7a678f'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        local youtube_dl_version="$1"
      else
        printf '\n======== Error: youtube-dl version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  local youtube_dl_dir="${PWD}/youtube-dl"
  
  checkout_commit "${youtube_dl_dir}" "$youtube_dl_version" \
                  'https://github.com/ytdl-org/youtube-dl.git'
  
  local launcher_text='#!/bin/bash

python3 '"${youtube_dl_dir}"'/youtube_dl/__main__.py "$@"'
  
  save_launcher_script 'youtube-dl' "$launcher_text"
}




# manage_gifski arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_gifski() {
  case "$1" in
    'default' | '1.2.2')
      printf '\n======== Defaulting to gifski version 1.2.2\n'
      local gifski_version='08392458acf94abc6ab10b67b63caf30ba30192f'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        local gifski_version="$1"
      else
        printf '\n======== Error: gifski version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  local gifski_dir="${PWD}/gifski"
  
  local install_dir="${gifski_dir}/gifski-${gifski_version}"
  local build_dir="${gifski_dir}/build"
  local src_dir="${gifski_dir}/src"
  
  local gifski_src_dir="${src_dir}/gifski"
  
  if [ ! -d "${gifski_dir}" ] && ! mkdir "${gifski_dir}"; then
    printf '\n==== Error: Could not create gifski directory\n'
    exit 1
  fi
  if [ -e "${install_dir}" ]; then
    printf '\n==== Error: Install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${install_dir}"
    exit 1
  fi
  if [ -e "${build_dir}" ]; then
    printf '\n==== Error: Build directory already exists:\n'
    printf '%s\n' "${build_dir}"
    exit 1
  fi
  if [ ! -d "${src_dir}" ] && ! mkdir "${src_dir}"; then
    printf '\n==== Error: Could not create src directory\n'
    exit 1
  fi
  
  
  checkout_commit "${gifski_src_dir}" "$gifski_version" \
                  'https://github.com/ImageOptim/gifski.git'
  
  
  printf '\n======== Building gifski\n'
  if ! mkdir "${build_dir}"; then
    printf '\n==== Error: Could not create build directory\n'
    exit 1
  fi
  cd "${gifski_src_dir}"
  CARGO_TARGET_DIR="${build_dir}" cargo build --release --features=openmp
  
  
  printf '\n======== Stripping debug symbols\n'
  strip --strip-all "${build_dir}/release/gifski"
  
  printf '\n======== Moving gifski build to install directory\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create install directory\n'
    exit 1
  fi
  mv "--target-directory=${install_dir}" \
       "${build_dir}/release/gifski" \
       "${gifski_src_dir}/gifski.h" \
       "${build_dir}/release/libgifski.a" \
       "${build_dir}/release/libgifski.rlib" \
       "${build_dir}/release/libgifski.so"
  
  create_symlinks "${install_dir}/gifski"
  
  printf '\n======== Generating checksums\n'
  cd "${install_dir}"
  sha256r "gifski-${gifski_version}-sha256sums.txt"
  
  
  printf '\n======== Cleaning up\n'
  rm -R -f -- "${build_dir}"
  if [ "$2" != 'keep_sources' ]; then
    rm -R -f -- "${src_dir}"
  else
    printf '\n==== Keeping source repo\n'
    cd "${gifski_src_dir}"
    clean_and_update_repo "$gifski_version" 'skip_update'
  fi
}




# manage_gifsicle arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_gifsicle() {
  case "$1" in
    'default' | '1.92')
      printf '\n======== Defaulting to gifsicle version 1.92\n'
      local gifsicle_version='1e2ca7401692ba94d7405de6e9dd1d1e73ca880f'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        local gifsicle_version="$1"
      else
        printf '\n======== Error: gifsicle version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  local gifsicle_dir="${PWD}/gifsicle"
  
  local install_dir="${gifsicle_dir}/gifsicle-${gifsicle_version}"
  local build_dir="${gifsicle_dir}/build"
  local src_dir="${gifsicle_dir}/src"
  
  local gifsicle_src_dir="${src_dir}/gifsicle"
  
  if [ ! -d "${gifsicle_dir}" ] && ! mkdir "${gifsicle_dir}"; then
    printf '\n==== Error: Could not create gifsicle directory\n'
    exit 1
  fi
  if [ -e "${install_dir}" ]; then
    printf '\n==== Error: Install directory already exists\n'
    printf '==== To reinstall, first delete the previous installation directory:\n'
    printf '%s\n' "${install_dir}"
    exit 1
  fi
  if [ -e "${build_dir}" ]; then
    printf '\n==== Error: Build directory already exists:\n'
    printf '%s\n' "${build_dir}"
    exit 1
  fi
  if [ ! -d "${src_dir}" ] && ! mkdir "${src_dir}"; then
    printf '\n==== Error: Could not create src directory\n'
    exit 1
  fi
  
  
  checkout_commit "${gifsicle_src_dir}" "$gifsicle_version" \
                  'https://github.com/kohler/gifsicle.git'
  
  
  printf '\n======== Building gifsicle\n'
  if ! mkdir "${build_dir}"; then
    printf '\n==== Error: Could not create build directory\n'
    exit 1
  fi
  cd "${build_dir}"
  autoreconf -i "${gifsicle_src_dir}"
  "${gifsicle_src_dir}/configure" --disable-gifview
  make
  
  printf '\n======== Stripping debug symbols\n'
  strip --strip-all "${build_dir}/src/gifsicle"
  strip --strip-all "${build_dir}/src/gifdiff"
  
  printf '\n======== Moving gifsicle build to install directory\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create install directory\n'
    exit 1
  fi
  mkdir "${install_dir}/bin"
  mv "${build_dir}/src/gifsicle" "${install_dir}/bin"
  mv "${build_dir}/src/gifdiff" "${install_dir}/bin"
  
  printf '\n======== Generating checksums\n'
  cd "${install_dir}"
  sha256r "gifsicle-${gifsicle_version}-sha256sums.txt"
  
  create_symlinks "${install_dir}/bin/gifsicle" \
                  "${install_dir}/bin/gifdiff"
  
  
  printf '\n======== Cleaning up\n'
  rm -R -f -- "${build_dir}"
  if [ "$2" != 'keep_sources' ]; then
    rm -R -f -- "${src_dir}"
  else
    printf '\n==== Keeping source repo\n'
    cd "${gifsicle_src_dir}"
    clean_and_update_repo "$gifsicle_version" 'skip_update'
  fi
}




# manage_mozjpeg arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_mozjpeg() {
  case "$1" in
    'default' | '4.0.0')
      printf '\n======== Defaulting to mozjpeg version 4.0.0\n'
      local mozjpeg_version='d23e3fc58613bc3f0aa395a8c73a2b1e7dae9e25'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        local mozjpeg_version="$1"
      else
        printf '\n======== Error: mozjpeg version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  local mozjpeg_dir="${PWD}/mozjpeg"
  
  local install_dir="${mozjpeg_dir}/mozjpeg-${mozjpeg_version}"
  local build_dir="${mozjpeg_dir}/build"
  local src_dir="${mozjpeg_dir}/src"
  
  local mozjpeg_src_dir="${src_dir}/mozjpeg"
  
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
  
  
  checkout_commit "${mozjpeg_src_dir}" "$mozjpeg_version" \
                  'https://github.com/mozilla/mozjpeg.git'
  
  
  printf '\n======== Building mozjpeg\n'
  if ! mkdir "${build_dir}"; then
    printf '\n==== Error: Could not create build directory\n'
    exit 1
  fi
  cd "${build_dir}"
  cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE='Release' \
        -DCMAKE_BUILD_RPATH_USE_ORIGIN='TRUE' \
        "${mozjpeg_src_dir}"
  #      -DCMAKE_INSTALL_RPATH_USE_LINK_PATH='FALSE' \
  #      -DCMAKE_BUILD_WITH_INSTALL_RPATH='TRUE' \
  make
  
  # TODO: use install?
  printf '\n======== Moving mozjpeg build to install directory\n'
  if ! mkdir "${install_dir}"; then
    printf '\n==== Error: Could not create mozjpeg install directory\n'
    exit 1
  fi
  mkdir "${install_dir}/doc" "${install_dir}/man" "${install_dir}/md5"
  mv "--target-directory=${install_dir}" \
       "${build_dir}/cjpeg" \
       "${build_dir}/cjpeg-static" \
       "${build_dir}/djpeg" \
       "${build_dir}/djpeg-static" \
       "${build_dir}/jpegtran" \
       "${build_dir}/jpegtran-static" \
       "${build_dir}/libjpeg.a" \
       "${build_dir}/libjpeg.so" \
       "${build_dir}/libjpeg.so.62" \
       "${build_dir}/libjpeg.so.62.3.0" \
       "${build_dir}/libturbojpeg.a" \
       "${build_dir}/libturbojpeg.so" \
       "${build_dir}/libturbojpeg.so.0" \
       "${build_dir}/libturbojpeg.so.0.2.0" \
       "${build_dir}/rdjpgcom" \
       "${build_dir}/wrjpgcom"
  #     "${build_dir}/jcstest" \
  #     "${build_dir}/tjbench" \
  #     "${build_dir}/tjbench-static" \
  #     "${build_dir}/tjexample" \
  #     "${build_dir}/tjunittest" \
  #     "${build_dir}/tjunittest-static" \
  mv "--target-directory=${install_dir}/md5" \
       "${build_dir}/md5/md5cmp"
  cp "--target-directory=${install_dir}" \
       "${mozjpeg_src_dir}/turbojpeg.h"
  cp "--target-directory=${install_dir}/doc" \
       "${mozjpeg_src_dir}/example.txt" \
       "${mozjpeg_src_dir}/libjpeg.txt" \
       "${mozjpeg_src_dir}/LICENSE.md" \
       "${mozjpeg_src_dir}/README-mozilla.txt" \
       "${mozjpeg_src_dir}/README-turbo.txt" \
       "${mozjpeg_src_dir}/README.ijg" \
       "${mozjpeg_src_dir}/README.md" \
       "${mozjpeg_src_dir}/release/License.rtf" \
       "${mozjpeg_src_dir}/structure.txt" \
       "${mozjpeg_src_dir}/usage.txt" \
       "${mozjpeg_src_dir}/wizard.txt"
  cp "--target-directory=${install_dir}/man" \
       "${mozjpeg_src_dir}/cjpeg.1" \
       "${mozjpeg_src_dir}/djpeg.1" \
       "${mozjpeg_src_dir}/jpegtran.1" \
       "${mozjpeg_src_dir}/rdjpgcom.1" \
       "${mozjpeg_src_dir}/wrjpgcom.1"
  
  printf '\n======== Generating checksums\n'
  cd "${install_dir}"
  sha256r "mozjpeg-${mozjpeg_version}-sha256sums.txt"
  
  create_symlink "${install_dir}/cjpeg"    'mozcjpeg'
  create_symlink "${install_dir}/djpeg"    'mozdjpeg'
  create_symlink "${install_dir}/jpegtran" 'mozjpegtran'
  create_symlink "${install_dir}/rdjpgcom" 'mozrdjpgcom'
  create_symlink "${install_dir}/wrjpgcom" 'mozwrjpgcom'
  
  printf '\n======== Cleaning up\n'
  rm -R -f -- "${build_dir}"
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
    'default' | '3.2.3')
      printf '\n======== Defaulting to godot version 3.2.3\n'
      local godot_version='31d0f8ad8d5cf50a310ee7e8ada4dcdb4510690b'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        local godot_version="$1"
      else
        printf '\n======== Error: godot version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  local godot_dir="${PWD}/godot"
  
  local install_dir="${godot_dir}/godot-${godot_version}"
  local src_dir="${godot_dir}/src"
  
  local godot_src_dir="${src_dir}/godot"
  
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
  
  
  checkout_commit "${godot_src_dir}" "$godot_version" \
                  'https://github.com/godotengine/godot.git'
  
  
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
    clean_and_update_repo "$godot_version" 'skip_update'
  fi
  
  
  printf '\n======== Creating application launcher\n'
  local launcher_path="${HOME}/.local/share/applications/org.godotengine.desktop"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Godot Engine
Comment=2D and 3D cross-platform game engine
Icon=${install_dir}/app_icon.png
Exec=${install_dir}/godot.x11.opt.tools.64
Path=${install_dir}
Terminal=false
Category=Development;Game;Graphics;"
  
  save_desktop_entry "${launcher_path}" "$launcher_text"
}




# manage_aseprite arguments:
# 1 = version (default or a commit sha1 hash)
# 2 = 'keep_sources' to keep source code after installation
manage_aseprite() {
  case "$1" in
    'default' | '1.2.25')
      printf '\n======== Defaulting to aseprite version 1.2.25\n'
      local aseprite_version='f44aad06db9d7a7efe9beb0038df37140ac9c2ba'
    ;;
    *)
      if is_valid_sha1 "$1"; then
        local aseprite_version="$1"
      else
        printf '\n======== Error: aseprite version is not default or a valid sha1 hash\n'
        exit 1
      fi
    ;;
  esac
  
  printf '\n======== Checking directories\n'
  local aseprite_dir="${PWD}/aseprite"
  
  local ase_install_dir="${aseprite_dir}/aseprite-${aseprite_version}"
  local skia_install_dir="${aseprite_dir}/skia-aseprite-m81"
  
  local build_dir="${aseprite_dir}/build"
  local ase_build_dir="${build_dir}/aseprite"
  local skia_build_dir="${build_dir}/skia"
  
  local src_dir="${aseprite_dir}/src"
  local ase_src_dir="${src_dir}/aseprite"
  local skia_src_dir="${src_dir}/skia"
  #local depot_tools_dir="${src_dir}/depot_tools"
  
  local temp_bin_dir="${aseprite_dir}/tempbin"
  
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
    # just check out a random depot_tools commit that is known to work
    #checkout_commit "${depot_tools_dir}" 'b073999c6f90103a36a923e63ae8cf7a5c9c6c8c' \
    #                'https://chromium.googlesource.com/chromium/tools/depot_tools.git'
    
    
    printf '\n======== Checking out commit aseprite-m81 skia was forked from\n'
    checkout_commit "${skia_src_dir}" '3e98c0e1d11516347ecc594959af2c1da4d04fc9' \
                    'https://skia.googlesource.com/skia.git'
    
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
  
  
  checkout_commit "${ase_src_dir}" "$aseprite_version" \
                  'https://github.com/aseprite/aseprite.git'
  
  
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
  local launcher_path="${HOME}/.local/share/applications/org.aseprite.desktop"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Aseprite
Comment=Animated Sprite Editor & Pixel Art Tool
Icon=${ase_install_dir}/bin/data/icons/ase256.png
Exec=${ase_install_dir}/bin/aseprite
Path=${ase_install_dir}
Terminal=false
Category=Graphics;"
  
  save_desktop_entry "${launcher_path}" "$launcher_text"
}




# Process input
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  printf '  software name:\n'
  printf '    [ aseprite | godot | mozjpeg | gifsicle | gifski | youtube-dl |\n'
  printf '      rust | krita | lmms | blender ]\n'
  printf '  software version [ default | (a git commit sha1) | (a version number) ]\n'
  printf '  "keep_sources" will keep source repos after install, otherwise ignored\n'
  exit 0
fi


keep_sources=''
if [ "$3" = 'keep_sources' ]; then
  keep_sources='keep_sources'
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
  'gifsicle')
    manage_gifsicle "$version" "$keep_sources"
  ;;
  'gifski')
    manage_gifski "$version" "$keep_sources"
  ;;
  'youtube-dl')
    manage_youtube_dl "$version"
  ;;
  'rust')
    manage_rust
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
