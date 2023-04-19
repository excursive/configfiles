#!/bin/bash

# make bash stricter about errors
set -e
set -o pipefail

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
    printf -- '%s\n' "$output" > "${1}"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty sha256sum
  fi
}

install_dir_check() {
  if [ -e "${1}" ] || [ -e "${1}-sha256sums.txt" ]; then
    printf '\n==== Error: Install directory or checksums already exist\n'
    printf '==== To reinstall, first delete the previous installation:\n'
    printf -- '%s\n%s\n\n' "${1}" "${1}-sha256sums.txt"
    exit 1
  fi
}

build_dir_check() {
  if [ -e "${1}" ]; then
    printf '\n==== Error: Build directory already exists:\n'
    printf -- '%s\n' "${1}"
    exit 1
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
  printf '\n'
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
  printf '\n'
}

# checks out the given git commit, cloning/fetching updates as necessary
# afterwards, working directory will be the specified directory
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
    printf '\n======== Cloning git repository\n\n'
    git clone --no-checkout -- "$url" "${dir}"
    if [ "$?" -ne 0 ]; then
      printf '\n==== Error: Could not clone git repository\n'
      exit 1
    fi
    fetch_updates='skip_update'
  fi
  
  printf -- '\n======== Checking out git commit\n======== %s\n' "$commit"
  if [ ! -d "${dir}/.git" ] || ! cd -- "${dir}"; then
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

dl_and_verify_file() {
  local checksum="$1"
  local outfile="${2}"
  local url="$3"
  if ! is_valid_sha256 "$checksum"; then
    printf -- '\n==== Error: Not a valid sha256 hash\n'
    exit 1
  fi
  if contains_nl_or_bs "${outfile}"; then
    printf -- '\n==== Error: Filename cannot contain newlines or backslashes\n'
    exit 1
  fi
  local file_basename="$(basename "${outfile}")"
  
  if [ ! -e "${outfile}" ]; then
    printf -- '\n======== Downloading %s\n\n' "${file_basename}"
    wget --execute robots=off --no-verbose --output-document="${outfile}" \
         --no-clobber --no-use-server-timestamps --https-only -- "$url"
    if [ "$?" -ne 0 ]; then
      printf -- '\n==== Error: Download failed: %s\n' "${outfile}"
      exit 1
    fi
  else
    printf -- '\n==== %s exists; skipping download\n' "${outfile}"
  fi
  
  printf -- '\n==== Verifying %s matches specified sha256 checksum:\n' "${file_basename}"
  printf -- '%s\n' "$checksum"
  printf -- '\n==== Downloaded file checksum is:\n'
  sha256sum "${outfile}"
  
  printf -- '%s  %s\n' "$checksum" "${outfile}" | sha256sum --check
  if [ "$?" -ne 0 ]; then
    printf -- '\n==== Error: Download does not match checksum\n'
    rm -f -- "${outfile}"
    exit 1
  fi
  printf '\n'
}

# backslashes, spaces, newlines, tabs, and carriage returns can require escaping
escape_desktop_entry_string() {
  printf -- '%s' "${1}" | sed -z -e 's/\\/\\\\/g' -e 's/ /\\s/g' -e 's/\n/\\n/g' -e 's/\t/\\t/g' -e 's/\r/\\r/g' -- -
}

# arguments/commands to be quoted require escaping the following characters:
# backslash, double quote, backtick, dollar sign
# backslash string escape rule is also applied before quoting rule, so escape it twice
escape_desktop_entry_argument() {
  printf -- '%s' "${1}" | sed -z -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/`/\\`/g' -e 's/\$/\\$/g' -z -e 's/\\/\\\\/g' -- -
}

# writes a desktop entry with the given contents to ~/.local/share/applications
save_desktop_entry() {
  local filename="${1}"
  local contents="$2"
  local path="${HOME}/.local/share/applications/${filename}"
  if [ -e "${path}" ]; then
    if [ -f "${path}" ] \
    && [ "$(head --lines=1 "${path}")" = '[Desktop Entry]' ]; then
      if printf -- '%s\n' "$contents" > "${path}"; then
        printf -- '\n==== Replaced old launcher for %s in applications\n' "${filename}"
      else
        printf -- '\n==== Error: Could not overwrite desktop entry at: %s\n' "${path}" 1>&2
        return 1
      fi
    else
      printf -- '\n==== Warning: launcher not created for %s\n' "${filename}"
      printf   '====   unknown file with that name exists in ~/.local/share/applications\n'
      return 1
    fi
  else
    if printf -- '%s\n' "$contents" > "${path}"; then
      printf -- '\n==== Created launcher for %s in applications\n' "${filename}"
    else
      printf -- '\n==== Error: Could not save desktop entry to: %s\n' "${path}" 1>&2
      return 1
    fi
  fi
}

# escapes paths so they can be used as input in shell scripts
# TODO is currently bash specific
escape_shell_path() {
  printf -- '%q' "${1}"
}

# writes a launcher bash script with the given contents to ~/bin
save_launcher_script() {
  local filename="${1}"
  local contents="$2"
  local path="${HOME}/bin/${filename}"
  if [ ! -d "${HOME}/bin" ] && ! mkdir "${HOME}/bin"; then
    printf '\n==== Warning: Could not create ~/bin directory;\n'
    printf -- '====   launcher %s not created\n' "${filename}"
    return 1
  fi
  if [ -e "${path}" ]; then
    if [ -f "${path}" ] \
    && [ "$(head --lines=1 "${path}")" = '#!/bin/bash' ]; then
      printf -- '%s\n' "$contents" > "${path}"
      chmod +x "${path}"
      printf -- '\n==== Replaced old launcher in ~/bin for %s\n' "${filename}"
    else
      printf -- '\n==== Warning: launcher not created for %s\n' "${filename}"
      printf   '====   unknown file with that name exists in ~/bin\n'
      return 1
    fi
  else
    printf -- '%s\n' "$contents" > "${path}"
    chmod +x "${path}"
    printf -- '\n==== Created launcher in ~/bin for %s\n' "${filename}"
  fi
}

# creates a symlink with the given name in ~/bin to target
create_symlink() {
  local target="${1}"
  local link_name="${2}"
  local link_path="${HOME}/bin/${link_name}"
  if [ ! -d "${HOME}/bin" ] && ! mkdir "${HOME}/bin"; then
    printf '\n==== Warning: Could not create ~/bin directory;\n'
    printf -- '====   symlink %s not created\n' "${link_name}"
    return 1
  fi
  if [ -L "${link_path}" ]; then
    rm -f -- "${link_path}"
    ln -s --no-target-directory "${target}" "${link_path}"
    printf -- '\n==== Replaced old symlink in ~/bin for %s\n' "${link_name}"
  elif [ -e "${link_path}" ]; then
    printf -- '\n==== Warning: symlink not created for %s\n' "${link_name}"
    printf   '====   unknown file with that name exists in ~/bin\n'
    return 1
  else
    ln -s --no-target-directory "${target}" "${link_path}"
    printf -- '\n==== Created symlink in ~/bin for %s\n' "${link_name}"
  fi
}

# creates symlinks in ~/bin to the given targets
create_symlinks() {
  for target in "$@"; do
    local link_name="$(basename -- "${target}")"
    create_symlink "${target}" "${link_name}"
  done
}




manage_blender() {
  local blender_version='3.2.1'
  local blender_sha256='d363a836d03a2462341d7f5cac98be2024120e648258f9ae8e7b69c9f88d6ac1'
  local blender_dl_url='Blender3.2/blender-3.2.1-linux-x64.tar.xz'
  
  local blender_dir="${PWD}/blender"
  local install_dir="${blender_dir}/blender-${blender_version}-linux-x64"
  local dl_file="${install_dir}.tar.xz"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${install_dir}"
  
  dl_and_verify_file "$blender_sha256" "${dl_file}" \
                     "https://download.blender.org/release/${blender_dl_url}"
  
  tar --extract --keep-old-files --restrict --one-top-level \
      --directory="${blender_dir}" \
      --file="${dl_file}"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  rm -f -- "${dl_file}"
  
  local escaped_install_dir="$(escape_desktop_entry_string "${install_dir}")"
  local escaped_executable_path=\""$(escape_desktop_entry_argument "${install_dir}/blender")"\"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Blender
Comment=Free and open source 3D creation suite
Icon=${escaped_install_dir}/blender.svg
Exec=env MESA_LOADER_DRIVER_OVERRIDE=i965 ${escaped_executable_path}
Path=${escaped_install_dir}
Terminal=false
Category=Video;Graphics;"
  
  save_desktop_entry 'org.blender.desktop' "$launcher_text"
}




manage_lmms() {
  local lmms_version='1.2.2'
  local lmms_commit_sha1='94363be152f526edba4e884264d891f1361cf54b'
  local lmms_sha256='6cdc45a0699b8cd85295c49bcac03fcce6f3d8ffd7da23d646d0cb4258869b76'
  local lmms_dl_url='v1.2.2/lmms-1.2.2-linux-x86_64.AppImage'
  
  local lmms_icon_sha256='e0d9507eabd86a79546bd948683ed83ec0eb5c569fee52cbad64bf957f362f20'
  local lmms_icon_url='data/themes/default/icon.png'
  
  local lmms_dir="${PWD}/lmms"
  local install_dir="${lmms_dir}/lmms-${lmms_version}-linux-x86_64"
  local dl_file="${install_dir}.AppImage"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${install_dir}"
  
  dl_and_verify_file "$lmms_sha256" "${dl_file}" \
                     "https://github.com/LMMS/lmms/releases/download/${lmms_dl_url}"
  
  dl_and_verify_file "$lmms_icon_sha256" "${lmms_dir}/icon.png" \
                     "https://raw.githubusercontent.com/LMMS/lmms/${lmms_commit_sha1}/${lmms_icon_url}"
  
  chmod --verbose +x -- "${dl_file}"
  mv --no-clobber --verbose "--target-directory=${install_dir}" -- \
                            "${dl_file}" \
                            "${lmms_dir}/icon.png"
  
  local escaped_install_dir="$(escape_desktop_entry_string "${install_dir}")"
  local escaped_executable_path=\""$(escape_desktop_entry_argument "${install_dir}/lmms-${lmms_version}-linux-x86_64.AppImage")"\"
  local launcher_text="[Desktop Entry]
Type=Application
Name=LMMS
Comment=Free, open source, multiplatform digital audio workstation
Icon=${escaped_install_dir}/icon.png
Exec=${escaped_executable_path}
Path=${escaped_install_dir}
Terminal=false
Category=Audio;"
  
  save_desktop_entry 'io.lmms.desktop' "$launcher_text"
}




manage_krita() {
  local krita_version='4.4.3'
  local krita_sha256='95b35a7ff2d591d8adad6159b98558f9b88e99a24568ba9ee217126188f5d026'
  local krita_dl_url='stable/krita/4.4.3/krita-4.4.3-x86_64.appimage'
  
  local krita_commit_sha1='fe63f49aea3cfbc3f04717883a67731f41531eae'
  local krita_icon_sha256='86ba89aadd20e9bf076c0721f0700c7fb4eaf6acc26e602c363277368c2373b4'
  local krita_icon_url='krita/pics/app/256-apps-krita.png'
  
  local krita_dir="${PWD}/krita"
  local install_dir="${krita_dir}/krita-${krita_version}-x86_64"
  local dl_file="${install_dir}.appimage"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${install_dir}"
  
  dl_and_verify_file "$krita_sha256" "${dl_file}" \
                     "https://download.kde.org/${krita_dl_url}"
  
  dl_and_verify_file "$krita_icon_sha256" "${krita_dir}/icon.png" \
                     "https://invent.kde.org/graphics/krita/-/raw/${krita_commit_sha1}/${krita_icon_url}"
  
  chmod --verbose +x -- "${dl_file}"
  mv --no-clobber --verbose "--target-directory=${install_dir}" -- \
                            "${dl_file}" \
                            "${krita_dir}/icon.png"
  
  local escaped_install_dir="$(escape_desktop_entry_string "${install_dir}")"
  local escaped_executable_path=\""$(escape_desktop_entry_argument "${install_dir}/krita-${krita_version}-x86_64.appimage")"\"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Krita
Comment=Free and open source painting and drawing program
Icon=${escaped_install_dir}/icon.png
Exec=${escaped_executable_path}
Path=${escaped_install_dir}
Terminal=false
Category=Graphics;"
  
  save_desktop_entry 'org.krita.desktop' "$launcher_text"
}




manage_rust() {
  local rust_installer_sha256='173f4881e2de99ba9ad1acb59e65be01b2a44979d83b6ec648d0d22f8654cbce'
  
  dl_and_verify_file "$rust_installer_sha256" 'rustup-init.sh' \
                     'https://sh.rustup.rs/'
  
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




manage_vim_gruvbox() {
  local gruvbox_version='bf2885a95efdad7bd5e4794dd0213917770d79b7'
  
  local gruvbox_dir="${HOME}/.vim/pack/gruvbox/start/gruvbox"
  mkdir --verbose --parents -- "${HOME}/.vim/pack/gruvbox/start"
  
  checkout_commit "${gruvbox_dir}" "$gruvbox_version" \
                  'https://github.com/morhetz/gruvbox.git'
}




manage_vim_two_firewatch() {
  local two_firewatch_version='efa0689e54881f09275e574f8fc19d8422c3bdc8'
  
  local two_firewatch_dir="${HOME}/.vim/pack/vim-two-firewatch/start/vim-two-firewatch"
  mkdir --verbose --parents -- "${HOME}/.vim/pack/vim-two-firewatch/start"
  
  checkout_commit "${two_firewatch_dir}" "$two_firewatch_version" \
                  'https://github.com/rakr/vim-two-firewatch.git'
}




manage_vim_lightline() {
  local lightline_version='709b2d8dc88fa622d6c076f34b05b58fcccf393f'
  
  local lightline_dir="${HOME}/.vim/pack/lightline/start/lightline"
  mkdir --verbose --parents -- "${HOME}/.vim/pack/lightline/start"
  
  checkout_commit "${lightline_dir}" "$lightline_version" \
                  'https://github.com/itchyny/lightline.vim.git'
}




manage_gallery_dl() {
  local gallery_dl_version='2d7d80d3025d42d5c0186525c8c54f85d1d03232'
  
  local gallery_dl_dir="${PWD}/gallery-dl"
  
  checkout_commit "${gallery_dl_dir}" "$gallery_dl_version" \
                  'https://github.com/mikf/gallery-dl.git'
  
  local escaped_gallery_dl_path="$(escape_shell_path "${gallery_dl_dir}/gallery_dl/__main__.py")"
  local launcher_text='#!/bin/bash

python3 '"${escaped_gallery_dl_path}"' "$@"'
  
  save_launcher_script 'gallery-dl' "$launcher_text"
}




manage_yt_dlp() {
  local yt_dlp_version='392389b7df7b818f794b231f14dc396d4875fbad'
  
  local yt_dlp_dir="${PWD}/yt-dlp"
  
  checkout_commit "${yt_dlp_dir}" "$yt_dlp_version" \
                  'https://github.com/yt-dlp/yt-dlp.git'
  
  local escaped_yt_dlp_path="$(escape_shell_path "${yt_dlp_dir}/yt_dlp/__main__.py")"
  local launcher_text='#!/bin/bash

python3 '"${escaped_yt_dlp_path}"' "$@"'
  
  save_launcher_script 'yt-dlp' "$launcher_text"
}




manage_youtube_dl() {
  local youtube_dl_version='5014bd67c22b421207b2650d4dc874b95b36dda1'
  
  local youtube_dl_dir="${PWD}/youtube-dl"
  
  checkout_commit "${youtube_dl_dir}" "$youtube_dl_version" \
                  'https://github.com/ytdl-org/youtube-dl.git'
  
  local escaped_youtube_dl_path="$(escape_shell_path "${youtube_dl_dir}/youtube_dl/__main__.py")"
  local launcher_text='#!/bin/bash

python3 '"${escaped_youtube_dl_path}"' "$@"'
  
  save_launcher_script 'youtube-dl' "$launcher_text"
}




manage_winetricks() {
  # sed deletion is by line number, remember to update both
  local winetricks_version='fa11b11a91a984666bf83b42e09be33ec0d6b294'
  
  local winetricks_dir="${PWD}/winetricks"
  
  checkout_commit "${winetricks_dir}" "$winetricks_version" \
                  'https://github.com/Winetricks/winetricks.git'
  
  printf '\n==== Deleting checksum skip for downloads over 500 MB (lines 1318 to 1326)\n'
  sed -i -e '1321,1329d' "${winetricks_dir}/src/winetricks"
  
  create_symlinks "${winetricks_dir}/src/winetricks"
}




manage_qt5_deb() {
  printf '\n======== unfinished\n'
}




manage_fceux() {
  local fceux_version='2b8c61802029721229a26592e4578f92efe814fb'
  
  local fceux_dir="${PWD}/fceux"
  
  local install_dir="${fceux_dir}/fceux-${fceux_version}"
  local build_dir="${fceux_dir}/build"
  local src_dir="${fceux_dir}/src"
  
  local fceux_src_dir="${src_dir}/fceux"
  
  install_dir_check "${install_dir}"
  build_dir_check "${build_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${build_dir}" "${install_dir}"
  
  checkout_commit "${fceux_src_dir}" "$fceux_version" \
                  'https://github.com/TASEmulators/fceux.git'
  
  cmake -S "${fceux_src_dir}" -B "${build_dir}" -DCMAKE_INSTALL_PREFIX="${install_dir}" -DCMAKE_BUILD_TYPE=Release
  make --directory="${build_dir}" -j2
  
  strip --strip-all --verbose -- "${build_dir}/src/fceux"
  
  mkdir --parents -- "${install_dir}/bin" \
                     "${install_dir}/share/applications" \
                     "${install_dir}/share/man/man6" \
                     "${install_dir}/share/pixmaps"
  mv --no-clobber "--target-directory=${install_dir}/bin" -- \
                  "${build_dir}/src/fceux"
  cp --no-clobber "--target-directory=${install_dir}/share/applications" -- \
                  "${fceux_src_dir}/fceux.desktop"
  cp --no-clobber -R --no-target-directory -- \
     "${fceux_src_dir}/output" "${install_dir}/share/fceux"
  cp --no-clobber "--target-directory=${install_dir}/share/fceux/luaScripts" -- \
                  "${fceux_src_dir}/src/auxlib.lua"
  cp --no-clobber "--target-directory=${install_dir}/share/man/man6" -- \
                  "${fceux_src_dir}/documentation/fceux.6" \
                  "${fceux_src_dir}/documentation/fceux-net-server.6"
  cp --no-clobber "--target-directory=${install_dir}/share/pixmaps" -- \
                  "${fceux_src_dir}/fceux1.png"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  rm -R -f -- "${build_dir}"
  cd -- "${fceux_src_dir}"
  clean_and_update_repo "$fceux_version" 'skip_update'
  
  create_symlinks "${install_dir}/bin/fceux"
  
  local escaped_install_dir="$(escape_desktop_entry_string "${install_dir}")"
  local escaped_executable_path=\""$(escape_desktop_entry_argument "${install_dir}/bin/fceux")"\"
  local launcher_text="[Desktop Entry]
Type=Application
Name=FCEUX
Comment=NES/Famicom Emulator and Debugger
Icon=${escaped_install_dir}/share/pixmaps/fceux1.png
Exec=${escaped_executable_path}
Path=${escaped_install_dir}
Terminal=false
Category=Game;Development;"
  
  save_desktop_entry 'com.fceux.desktop' "$launcher_text"
}




manage_discimagecreator() {
  local dic_version='0e7c48f1aae0ff7fcb0fe34acffe010488bc5745'
  
  local dic_dir="${PWD}/DiscImageCreator"
  
  local install_dir="${dic_dir}/DiscImageCreator-${dic_version}"
  local src_dir="${dic_dir}/src"
  
  local dic_src_dir="${src_dir}/DiscImageCreator"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${install_dir}"
  
  checkout_commit "${dic_src_dir}" "$dic_version" \
                  'https://github.com/saramibreak/DiscImageCreator.git'
  
  make "--directory=${dic_src_dir}/DiscImageCreator"
  
  mkdir --verbose --parents -- "${install_dir}/bin" "${install_dir}/share/DiscImageCreator"
  mv --no-clobber --verbose "--target-directory=${install_dir}/bin" -- \
                            "${dic_src_dir}/DiscImageCreator/DiscImageCreator"
  cp --no-clobber --verbose "--target-directory=${install_dir}/share/DiscImageCreator" -- \
                            "${dic_src_dir}/Release_ANSI/default.dat" \
                            "${dic_src_dir}/Release_ANSI/driveOffset.txt"
  
  strip --strip-all --verbose -- "${install_dir}/bin/DiscImageCreator"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  create_symlinks "${install_dir}/bin/DiscImageCreator"
  
  cd -- "${dic_src_dir}"
  clean_and_update_repo "$dic_version" 'skip_update'
}




manage_bchunk() {
  local bchunk_version='2d57a4b2477f1f4098d640a089e97fae4cf5abcf'
  
  local bchunk_dir="${PWD}/bchunk"
  
  local install_dir="${bchunk_dir}/bchunk-${bchunk_version}"
  local src_dir="${bchunk_dir}/src"
  
  local bchunk_src_dir="${src_dir}/bchunk"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${install_dir}"
  
  checkout_commit "${bchunk_src_dir}" "$bchunk_version" \
                  'https://github.com/hessu/bchunk.git'
  
  cd -- "${bchunk_src_dir}"
  make
  
  mkdir --verbose --parents -- "${install_dir}/bin" "${install_dir}/man/man1"
  mv --no-clobber --verbose "--target-directory=${install_dir}/bin" -- \
                            "${bchunk_src_dir}/bchunk"
  cp --no-clobber --verbose "--target-directory=${install_dir}/man/man1" -- \
                            "${bchunk_src_dir}/bchunk.1"
  
  strip --strip-all --verbose -- "${install_dir}/bin/bchunk"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  create_symlinks "${install_dir}/bin/bchunk"
  
  cd -- "${bchunk_src_dir}"
  clean_and_update_repo "$bchunk_version" 'skip_update'
}




manage_cc65() {
  local cc65_version='555282497c3ecf8b313d87d5973093af19c35bd5'
  
  local cc65_dir="${PWD}/cc65"
  
  local install_dir="${cc65_dir}/cc65-${cc65_version}"
  local src_dir="${cc65_dir}/src"
  
  local cc65_src_dir="${src_dir}/cc65"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${install_dir}"
  
  checkout_commit "${cc65_src_dir}" "$cc65_version" \
                  'https://github.com/cc65/cc65.git'
  
  cd -- "${cc65_src_dir}"
  make -j2
  
  mkdir --verbose --parents -- "${install_dir}/share/cc65"
  mv --no-clobber "--target-directory=${install_dir}" -- \
                  "${cc65_src_dir}/bin"
  cp --no-clobber -R "--target-directory=${install_dir}/share/cc65" -- \
                     "${cc65_src_dir}/asminc" \
                     "${cc65_src_dir}/cfg" \
                     "${cc65_src_dir}/include" \
                     "${cc65_src_dir}/lib" \
                     "${cc65_src_dir}/samples" \
                     "${cc65_src_dir}/target"
  
  strip --strip-all -- "${install_dir}/bin/ar65" \
                       "${install_dir}/bin/ca65" \
                       "${install_dir}/bin/cc65" \
                       "${install_dir}/bin/chrcvt65" \
                       "${install_dir}/bin/cl65" \
                       "${install_dir}/bin/co65" \
                       "${install_dir}/bin/da65" \
                       "${install_dir}/bin/grc65" \
                       "${install_dir}/bin/ld65" \
                       "${install_dir}/bin/od65" \
                       "${install_dir}/bin/sim65" \
                       "${install_dir}/bin/sp65"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  create_symlinks "${install_dir}/bin/ar65" \
                  "${install_dir}/bin/ca65" \
                  "${install_dir}/bin/cc65" \
                  "${install_dir}/bin/chrcvt65" \
                  "${install_dir}/bin/cl65" \
                  "${install_dir}/bin/co65" \
                  "${install_dir}/bin/da65" \
                  "${install_dir}/bin/grc65" \
                  "${install_dir}/bin/ld65" \
                  "${install_dir}/bin/od65" \
                  "${install_dir}/bin/sim65" \
                  "${install_dir}/bin/sp65"
  
  cd -- "${cc65_src_dir}"
  clean_and_update_repo "$cc65_version" 'skip_update'
}




manage_cyanrip() {
  local cyanrip_version='25879a9c16b81410a1dee793f6674020edb7029e'
  
  local cyanrip_dir="${PWD}/cyanrip"
  
  local install_dir="${cyanrip_dir}/cyanrip-${cyanrip_version}"
  local build_dir="${cyanrip_dir}/build"
  local src_dir="${cyanrip_dir}/src"
  
  local cyanrip_src_dir="${src_dir}/cyanrip"
  
  install_dir_check "${install_dir}"
  build_dir_check "${build_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${build_dir}" "${install_dir}"
  
  checkout_commit "${cyanrip_src_dir}" "$cyanrip_version" \
                  'https://github.com/cyanreg/cyanrip.git'
  
  meson setup --prefix "${install_dir}" --buildtype release "${build_dir}" "${cyanrip_src_dir}"
  ninja -C "${build_dir}"
  
  mv --no-clobber --verbose "--target-directory=${install_dir}" -- \
                            "${build_dir}/src/cyanrip"
  
  create_symlinks "${install_dir}/cyanrip"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  rm -R -f -- "${build_dir}"
  cd -- "${cyanrip_src_dir}"
  clean_and_update_repo "$cyanrip_version" 'skip_update'
}




manage_whipper() {
  local whipper_version='18a41b6c2880e577f9f1d7b1b6e7df0be7371378'
  
  local whipper_dir="${PWD}/whipper"
  
  checkout_commit "${whipper_dir}" "$whipper_version" \
                  'https://github.com/whipper-team/whipper.git'
  
  local escaped_whipper_path="$(escape_shell_path "${whipper_dir}/whipper/__main__.py")"
  local launcher_text='#!/bin/bash

python3 '"${escaped_whipper_path}"' "$@"'
  
  save_launcher_script 'whipper' "$launcher_text"
}




manage_zopflipng() {
  local zopflipng_version='831773bc28e318b91a3255fa12c9fcde1606058b'
  
  local zopflipng_dir="${PWD}/zopflipng"
  
  local install_dir="${zopflipng_dir}/zopflipng-${zopflipng_version}"
  local src_dir="${zopflipng_dir}/src"
  
  local zopflipng_src_dir="${src_dir}/zopflipng"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${install_dir}"
  
  checkout_commit "${zopflipng_src_dir}" "$zopflipng_version" \
                  'https://github.com/google/zopfli.git'
  
  cd -- "${zopflipng_src_dir}"
  g++ "src/zopfli/"{blocksplitter,cache,deflate,gzip_container,hash,katajainen}.c \
      "src/zopfli/"{lz77,squeeze,tree,util,zlib_container,zopfli_lib}.c \
      "src/zopflipng/"{zopflipng_bin,zopflipng_lib}.cc \
      "src/zopflipng/lodepng/"{lodepng,lodepng_util}.cpp \
      -O2 -W -Wall -Wextra -Wno-unused-function -ansi -pedantic -fPIC -o zopflipng
  
  mv --no-clobber --verbose "--target-directory=${install_dir}" -- \
                            "${zopflipng_src_dir}/zopflipng"
  
  create_symlinks "${install_dir}/zopflipng"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  cd -- "${zopflipng_src_dir}"
  clean_and_update_repo "$zopflipng_version" 'skip_update'
}




manage_pngquant() {
  local pngquant_version='a6ff122ac96f47deec2a9b3d67f5e6654ccd9bbf'
  
  local pngquant_dir="${PWD}/pngquant"
  
  local install_dir="${pngquant_dir}/pngquant-${pngquant_version}"
  local src_dir="${pngquant_dir}/src"
  
  local pngquant_src_dir="${src_dir}/pngquant"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${install_dir}"
  
  checkout_commit "${pngquant_src_dir}" "$pngquant_version" \
                  'https://github.com/kornelski/pngquant.git'
  
  cd -- "${pngquant_src_dir}"
  "${pngquant_src_dir}/configure" "--prefix=${install_dir}" \
                                  --enable-sse \
                                  --with-openmp=static
  make
  
  strip --strip-all -- "${pngquant_src_dir}/pngquant"
  
  mkdir --verbose --parents -- "${install_dir}/bin" "${install_dir}/share/man/man1"
  mv --no-clobber --verbose "--target-directory=${install_dir}/bin" -- \
                            "${pngquant_src_dir}/pngquant"
  mv --no-clobber --verbose "--target-directory=${install_dir}/share/man/man1" -- \
                            "${pngquant_src_dir}/pngquant.1"
  
  create_symlinks "${install_dir}/bin/pngquant"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  cd -- "${pngquant_src_dir}"
  clean_and_update_repo "$pngquant_version" 'skip_update'
}




manage_gifski() {
  local gifski_version='12a362e0d14d555ae10e3b0795f6320af1458927'
  
  local gifski_dir="${PWD}/gifski"
  
  local install_dir="${gifski_dir}/gifski-${gifski_version}"
  local build_dir="${gifski_dir}/build"
  local src_dir="${gifski_dir}/src"
  
  local gifski_src_dir="${src_dir}/gifski"
  
  install_dir_check "${install_dir}"
  build_dir_check "${build_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${build_dir}" "${install_dir}"
  
  checkout_commit "${gifski_src_dir}" "$gifski_version" \
                  'https://github.com/ImageOptim/gifski.git'
  
  cd -- "${gifski_src_dir}"
  CARGO_TARGET_DIR="${build_dir}" cargo build --release --features=openmp
  
  strip --strip-all -- "${build_dir}/release/gifski"
  
  mv --no-clobber --verbose "--target-directory=${install_dir}" -- \
                            "${build_dir}/release/gifski" \
                            "${gifski_src_dir}/gifski.h" \
                            "${build_dir}/release/libgifski.a" \
                            "${build_dir}/release/libgifski.rlib" \
                            "${build_dir}/release/libgifski.so"
  
  create_symlinks "${install_dir}/gifski"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  rm -R -f -- "${build_dir}"
  cd -- "${gifski_src_dir}"
  clean_and_update_repo "$gifski_version" 'skip_update'
}




manage_gifsicle() {
  local gifsicle_version='1e2ca7401692ba94d7405de6e9dd1d1e73ca880f'
  
  local gifsicle_dir="${PWD}/gifsicle"
  
  local install_dir="${gifsicle_dir}/gifsicle-${gifsicle_version}"
  local build_dir="${gifsicle_dir}/build"
  local src_dir="${gifsicle_dir}/src"
  
  local gifsicle_src_dir="${src_dir}/gifsicle"
  
  install_dir_check "${install_dir}"
  build_dir_check "${build_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${build_dir}" "${install_dir}"
  
  checkout_commit "${gifsicle_src_dir}" "$gifsicle_version" \
                  'https://github.com/kohler/gifsicle.git'
  
  
  cd -- "${build_dir}"
  autoreconf -i "${gifsicle_src_dir}"
  "${gifsicle_src_dir}/configure" --disable-gifview
  make
  
  strip --strip-all -- "${build_dir}/src/gifsicle"
  strip --strip-all -- "${build_dir}/src/gifdiff"
  
  mkdir --verbose --parents -- "${install_dir}/bin"
  mv --no-clobber --verbose "--target-directory=${install_dir}/bin" -- \
                            "${build_dir}/src/gifsicle" \
                            "${build_dir}/src/gifdiff"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  create_symlinks "${install_dir}/bin/gifsicle" \
                  "${install_dir}/bin/gifdiff"
  
  rm -R -f -- "${build_dir}"
  cd -- "${gifsicle_src_dir}"
  clean_and_update_repo "$gifsicle_version" 'skip_update'
}




manage_mozjpeg() {
  local mozjpeg_version='a2d2907ff023227e80c1e4efa809812410275a12'
  
  local mozjpeg_dir="${PWD}/mozjpeg"
  
  local install_dir="${mozjpeg_dir}/mozjpeg-${mozjpeg_version}"
  local build_dir="${mozjpeg_dir}/build"
  local src_dir="${mozjpeg_dir}/src"
  
  local mozjpeg_src_dir="${src_dir}/mozjpeg"
  
  install_dir_check "${install_dir}"
  build_dir_check "${build_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${build_dir}" "${install_dir}"
  
  checkout_commit "${mozjpeg_src_dir}" "$mozjpeg_version" \
                  'https://github.com/mozilla/mozjpeg.git'
  
  cd -- "${build_dir}"
  cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE='Release' \
        -DCMAKE_BUILD_RPATH_USE_ORIGIN='TRUE' \
        -DCMAKE_INSTALL_PREFIX="${install_dir}" \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH='TRUE' \
        "${mozjpeg_src_dir}"
  make -j2
  
  mkdir --verbose --parents -- "${install_dir}/bin" \
                               "${install_dir}/include" \
                               "${install_dir}/lib/cmake/mozjpeg" \
                               "${install_dir}/lib/pkgconfig" \
                               "${install_dir}/share/doc/mozjpeg" \
                               "${install_dir}/share/man/man1"
  #                             "${install_dir}/md5"
  mv --no-clobber --verbose "--target-directory=${install_dir}/bin" -- \
                            "${build_dir}/cjpeg" \
                            "${build_dir}/cjpeg-static" \
                            "${build_dir}/djpeg" \
                            "${build_dir}/djpeg-static" \
                            "${build_dir}/jpegtran" \
                            "${build_dir}/jpegtran-static" \
                            "${build_dir}/rdjpgcom" \
                            "${build_dir}/tjbench" \
                            "${build_dir}/tjbench-static" \
                            "${build_dir}/wrjpgcom"
  #                          "${build_dir}/jcstest" \
  #                          "${build_dir}/tjexample" \
  #                          "${build_dir}/tjunittest" \
  #                          "${build_dir}/tjunittest-static" \
  cp --no-clobber --verbose "--target-directory=${install_dir}/include" -- \
                            "${build_dir}/jconfig.h" \
                            "${mozjpeg_src_dir}/jerror.h" \
                            "${mozjpeg_src_dir}/jmorecfg.h" \
                            "${mozjpeg_src_dir}/jpeglib.h" \
                            "${mozjpeg_src_dir}/turbojpeg.h"
  mv --no-clobber --verbose "--target-directory=${install_dir}/lib/cmake/mozjpeg" -- \
                            "${build_dir}/pkgscripts/mozjpegConfig.cmake" \
                            "${build_dir}/pkgscripts/mozjpegConfigVersion.cmake" \
                            "${build_dir}/CMakeFiles/Export/lib/cmake/mozjpeg/mozjpegTargets.cmake" \
                            "${build_dir}/CMakeFiles/Export/lib/cmake/mozjpeg/mozjpegTargets-release.cmake"
  mv --no-clobber --verbose "--target-directory=${install_dir}/lib" -- \
                            "${build_dir}/libjpeg.a" \
                            "${build_dir}/libjpeg.so" \
                            "${build_dir}/libjpeg.so.62" \
                            "${build_dir}/libjpeg.so.62.3.0" \
                            "${build_dir}/libturbojpeg.a" \
                            "${build_dir}/libturbojpeg.so" \
                            "${build_dir}/libturbojpeg.so.0" \
                            "${build_dir}/libturbojpeg.so.0.2.0"
  mv --no-clobber --verbose "--target-directory=${install_dir}/lib/pkgconfig" -- \
                            "${build_dir}/pkgscripts/libjpeg.pc" \
                            "${build_dir}/pkgscripts/libturbojpeg.pc"
  #mv --no-clobber --verbose "--target-directory=${install_dir}/md5" -- \
  #                          "${build_dir}/md5/md5cmp"
  cp --no-clobber --verbose "--target-directory=${install_dir}/share/doc/mozjpeg" -- \
                            "${mozjpeg_src_dir}/example.txt" \
                            "${mozjpeg_src_dir}/libjpeg.txt" \
                            "${mozjpeg_src_dir}/LICENSE.md" \
                            "${mozjpeg_src_dir}/README-mozilla.txt" \
                            "${mozjpeg_src_dir}/README-turbo.txt" \
                            "${mozjpeg_src_dir}/README.ijg" \
                            "${mozjpeg_src_dir}/README.md" \
                            "${mozjpeg_src_dir}/release/License.rtf" \
                            "${mozjpeg_src_dir}/structure.txt" \
                            "${mozjpeg_src_dir}/tjexample.c" \
                            "${mozjpeg_src_dir}/usage.txt" \
                            "${mozjpeg_src_dir}/wizard.txt"
  cp --no-clobber --verbose "--target-directory=${install_dir}/share/man/man1" -- \
                            "${mozjpeg_src_dir}/cjpeg.1" \
                            "${mozjpeg_src_dir}/djpeg.1" \
                            "${mozjpeg_src_dir}/jpegtran.1" \
                            "${mozjpeg_src_dir}/rdjpgcom.1" \
                            "${mozjpeg_src_dir}/wrjpgcom.1"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  create_symlink "${install_dir}/bin/cjpeg"    'mozcjpeg'
  create_symlink "${install_dir}/bin/djpeg"    'mozdjpeg'
  create_symlink "${install_dir}/bin/jpegtran" 'mozjpegtran'
  create_symlink "${install_dir}/bin/rdjpgcom" 'mozrdjpgcom'
  create_symlink "${install_dir}/bin/tjbench"  'moztjbench'
  create_symlink "${install_dir}/bin/wrjpgcom" 'mozwrjpgcom'
  
  rm -R -f -- "${build_dir}"
  cd -- "${mozjpeg_src_dir}"
  clean_and_update_repo "$mozjpeg_version" 'skip_update'
}




manage_godot() {
  local godot_version='faf3f883d1a25ec8a2b7a31ecc9e3363613b2478'
  
  local godot_dir="${PWD}/godot"
  
  local install_dir="${godot_dir}/godot-${godot_version}"
  local src_dir="${godot_dir}/src"
  
  local godot_src_dir="${src_dir}/godot"
  
  install_dir_check "${install_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${install_dir}"
  
  checkout_commit "${godot_src_dir}" "$godot_version" \
                  'https://github.com/godotengine/godot.git'
  
  cd -- "${godot_src_dir}"
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
  
  strip --strip-all -- "${godot_src_dir}/bin/godot.x11.opt.tools.64"
  
  mv --no-clobber --verbose "--target-directory=${install_dir}" -- \
                            "${godot_src_dir}/bin/godot.x11.opt.tools.64"
  cp --no-clobber --verbose "--target-directory=${install_dir}" -- \
                            "${godot_src_dir}/main/app_icon.png"
  
  cd -- "${install_dir}"
  sha256r "${install_dir}-sha256sums.txt"
  
  cd -- "${godot_src_dir}"
  clean_and_update_repo "$godot_version" 'skip_update'
  
  local escaped_install_dir="$(escape_desktop_entry_string "${install_dir}")"
  local escaped_executable_path=\""$(escape_desktop_entry_argument "${install_dir}/godot.x11.opt.tools.64")"\"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Godot Engine
Comment=2D and 3D cross-platform game engine
Icon=${escaped_install_dir}/app_icon.png
Exec=${escaped_executable_path}
Path=${escaped_install_dir}
Terminal=false
Category=Development;Game;Graphics;"
  
  save_desktop_entry 'org.godotengine.desktop' "$launcher_text"
}




manage_aseprite() {
  local aseprite_version='32b5d20a8d88d92e413cad474325fb64a9860f12'
  
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
  
  install_dir_check "${ase_install_dir}"
  build_dir_check "${build_dir}"
  mkdir --verbose --parents -- "${src_dir}" "${ase_build_dir}" "${skia_build_dir}" "${ase_install_dir}"
  
  # in case python doesn't point to python2 binary,
  # set up a temp folder with a link to temporarily add to path
  mkdir --verbose --parents -- "${temp_bin_dir}"
  ln -s '/usr/bin/python2' "${temp_bin_dir}/python"
  
  
  if [ -e "${skia_install_dir}" ]; then
    printf '\n======== Skia install directory found. Verifying checksums...\n'
    # TODO: need a better way to check if skia installation matches checksums
    if ! cd -- "${skia_install_dir}" \
       || ! sha256sum --check --quiet "${skia_install_dir}-sha256sums.txt"; then
      printf '\n==== Error: Skia installation does not match checksums\n'
      exit 1
    fi
  else
    # just check out a random depot_tools commit that is known to work
    #checkout_commit "${depot_tools_dir}" 'b073999c6f90103a36a923e63ae8cf7a5c9c6c8c' \
    #                'https://chromium.googlesource.com/chromium/tools/depot_tools.git'
    
    printf '\n======== Checking out commit aseprite-m81 skia was forked from\n'
    local skia_version='3e98c0e1d11516347ecc594959af2c1da4d04fc9'
    checkout_commit "${skia_src_dir}" "$skia_version" \
                    'https://skia.googlesource.com/skia.git'
    
    printf '\n==== Syncing skia dependencies\n'
    env PATH="${PATH}:${temp_bin_dir}" python tools/git-sync-deps
    
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
    cd -- "${skia_src_dir}"
    env PATH="${PATH}:${temp_bin_dir}" bin/gn gen "${skia_build_dir}" \
      --args='is_debug=false is_official_build=true skia_use_sfntly=false skia_use_dng_sdk=false skia_use_piex=false'
    cd -- "${skia_build_dir}"
    ninja -C "${skia_build_dir}" skia modules
    
    # TODO: make library directory dynamic to handle other architectures
    mkdir --verbose --parents -- "${skia_install_dir}/lib/x86_64-linux-gnu"
    mv --no-clobber --verbose "--target-directory=${skia_install_dir}/lib/x86_64-linux-gnu" -- \
                              "${skia_build_dir}"/*.a
    cd -- "${skia_src_dir}"
    cp --no-clobber --verbose -R --parents "--target-directory=${skia_install_dir}" -- \
       include \
       modules/particles/include/*.h \
       modules/skottie/include/*.h \
       modules/skresources/include/*.h \
       modules/sksg/include/*.h \
       modules/skshaper/include/*.h
    
    cd -- "${skia_install_dir}"
    sha256r "${skia_install_dir}-sha256sums.txt"
    
    cd -- "${skia_src_dir}"
    clean_and_update_repo "$skia_version" 'skip_update'
  fi
  
  
  checkout_commit "${ase_src_dir}" "$aseprite_version" \
                  'https://github.com/aseprite/aseprite.git'
  
  printf '\n======== Building aseprite\n'
  cd -- "${ase_build_dir}"
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
  
  mv --no-clobber --verbose "--target-directory=${ase_install_dir}" -- \
                            "${ase_build_dir}/bin" \
                            "${ase_build_dir}/lib"
  cp --no-clobber --verbose "--target-directory=${ase_install_dir}/lib" -- \
                            "${skia_install_dir}"/lib/x86_64-linux-gnu/*.a
  
  cd -- "${ase_install_dir}"
  sha256r "${ase_install_dir}-sha256sums.txt"
  
  rm -R -f -- "${build_dir}" "${temp_bin_dir}"
  cd -- "${ase_src_dir}"
  clean_and_update_repo "$aseprite_version" 'skip_update'
  
  local escaped_ase_install_dir="$(escape_desktop_entry_string "${ase_install_dir}")"
  local escaped_ase_executable_path=\""$(escape_desktop_entry_argument "${ase_install_dir}/bin/aseprite")"\"
  local launcher_text="[Desktop Entry]
Type=Application
Name=Aseprite
Comment=Animated Sprite Editor & Pixel Art Tool
Icon=${escaped_ase_install_dir}/bin/data/icons/ase256.png
Exec=${escaped_ase_executable_path}
Path=${escaped_ase_install_dir}
Terminal=false
Category=Graphics;"
  
  save_desktop_entry 'org.aseprite.desktop' "$launcher_text"
}




# Process input
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  printf '  software name:\n'
  printf '    [ aseprite | godot | mozjpeg | gifsicle | gifski | pngquant | zopflipng |\n'
  printf '      youtube-dl | yt-dlp |\n'
  printf '      vim-lightline | vim-two-firewatch | vim-gruvbox |\n'
  printf '      rust | krita | lmms | blender ]\n'
  printf '  software version [ default | (a git commit sha1) | (a version number) ]\n'
  printf '  "keep_sources" will keep source repos after install, otherwise ignored\n'
  exit 0
fi

starting_dir="${PWD}"

case "$1" in
  'aseprite') manage_aseprite ;;
  'godot') manage_godot ;;
  'mozjpeg') manage_mozjpeg ;;
  'gifsicle') manage_gifsicle ;;
  'gifski') manage_gifski ;;
  'zopflipng') manage_zopflipng ;;
  'pngquant') manage_pngquant ;;
  'whipper') manage_whipper ;;
  'cyanrip') manage_cyanrip ;;
  'cc65') manage_cc65 ;;
  'bchunk') manage_bchunk ;;
  'discimagecreator') manage_discimagecreator ;;
  'fceux') manage_fceux ;;
  'qt5-deb') manage_qt5_deb ;;
  'winetricks') manage_winetricks ;;
  'youtube-dl') manage_youtube_dl ;;
  'yt-dlp') manage_yt_dlp ;;
  'gallery-dl') manage_gallery_dl ;;
  'vim-lightline') manage_vim_lightline ;;
  'vim-two-firewatch') manage_vim_two_firewatch ;;
  'vim-gruvbox') manage_vim_gruvbox ;;
  'rust') manage_rust ;;
  'krita') manage_krita ;;
  'lmms') manage_lmms ;;
  'blender') manage_blender ;;
  '')
    printf '\nError: No arguments supplied, see -h or --help\n'
    exit 1
  ;;
  *)
    printf '\nError: Invalid software name\n'
    exit 1
  ;;
esac

cd -- "${starting_dir}"

printf '\n======== All done!\n\n'

exit 0
