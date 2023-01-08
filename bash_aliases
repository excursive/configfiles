#!/bin/bash

PATH="${PATH}:${HOME}/bin"

alias ddsafe="dd conv=excl bs=65536 iflag=skip_bytes"

alias md5c="md5sum -c --quiet"
alias sha256c="sha256sum -c --quiet"

alias chardiff="git diff --no-index --word-diff=color --word-diff-regex=. --"

alias pngreduce="pngquant --speed 1 --strip --verbose"

alias png8fs="pngquant --quality 100 --speed 1 --strip --verbose 256 --"
alias png8nofs="pngquant --quality 100 --speed 1 --nofs --strip --verbose 256 --"

alias optipng7="optipng -strip all -o7"
alias optipng8="optipng -strip all -o7 -zm1-9"

alias mozjpegoptim="mozjpegtran -copy none -optimize -perfect"

alias gifinfo='gifsicle --info --color-info --extension-info --size-info'
alias gifoptimize='gifsicle --merge --no-app-extensions --no-names --no-comments --no-extensions -O2'

alias aadebug="apparmor_parser -Q --debug"




srm() {
  rm -I --one-file-system --verbose "$@"
}

smv() {
  mv --no-clobber --verbose "$@"
}

fp_add_flathub_user() {
  flatpak remote-add --user --if-not-exists flathub 'https://flathub.org/repo/flathub.flatpakrepo'
}

fp_add_flathub_system() {
  flatpak remote-add --if-not-exists flathub 'https://flathub.org/repo/flathub.flatpakrepo'
}

fp_install_flatseal() {
  flatpak install flathub com.github.tchx84.Flatseal
}

fp_install_firefox() {
  flatpak install flathub org.mozilla.firefox
}

fp_install_chrome() {
  flatpak install flathub com.google.Chrome
}

fp_install_vlc() {
  flatpak install flathub org.videolan.VLC
}

fp_install_steam() {
  flatpak install flathub com.valvesoftware.Steam
}

fp_install_gimp() {
  flatpak install flathub org.gimp.GIMP
}

fp_install_krita() {
  flatpak install flathub org.kde.krita
}

fp_install_inkscape() {
  flatpak install flathub org.inkscape.Inkscape
}

fp_install_libreoffice() {
  flatpak install flathub org.libreoffice.LibreOffice
}

fp_install_ghex() {
  flatpak install flathub org.gnome.GHex
}

fp_install_calculator() {
  flatpak install flathub org.gnome.Calculator
}

fp_install_transmission() {
  flatpak install flathub com.transmissionbt.Transmission
}

fp_install_obs() {
  flatpak install --user flathub com.obsproject.Studio
}

fp_install_kdenlive() {
  flatpak install --user flathub org.kde.kdenlive
}

fp_install_displaycal() {
  flatpak install --user flathub net.displaycal.DisplayCAL
}

fp_install_natron() {
  flatpak install --user flathub fr.natron.Natron
}

fp_install_godot() {
  flatpak install --user flathub org.godotengine.Godot
}

fp_install_libresprite() {
  flatpak install --user flathub com.github.libresprite.LibreSprite
}

fp_install_vscode() {
  flatpak install --user flathub com.visualstudio.code
}

fp_install_famistudio() {
  flatpak install --user flathub org.famistudio.FamiStudio
}

fp_install_dolphin() {
  flatpak install --user flathub org.DolphinEmu.dolphin-emu
}

fp_install_ppsspp() {
  flatpak install --user flathub org.ppsspp.PPSSPP
}

fp_install_rpcs3() {
  flatpak install --user flathub net.rpcs3.RPCS3
}

fp_install_duckstation() {
  flatpak install --user flathub org.duckstation.DuckStation
}

fp_install_snes9x() {
  flatpak install --user flathub com.snes9x.Snes9x
}

fp_install_yuzu() {
  flatpak install --user flathub org.yuzu_emu.yuzu
}

fp_install_citra() {
  flatpak install --user flathub org.citra_emu.citra
}

fp_install_primehack() {
  flatpak install --user flathub io.github.shiiion.primehack
}

fp_install_pcsx2() {
  flatpak install --user flathub net.pcsx2.PCSX2
}

fp_install_desmume() {
  flatpak install --user flathub org.desmume.DeSmuME
}

fp_install_mgba() {
  flatpak install --user flathub io.mgba.mGBA
}

fp_install_runelite() {
  flatpak install --user flathub net.runelite.RuneLite
}

fp_install_basilisk() {
  flatpak install --user flathub net.cebix.basilisk
}

fp_install_dosbox() {
  flatpak install --user flathub com.dosbox.DOSBox
}

fp_install_scummvm() {
  flatpak install --user flathub org.scummvm.ScummVM
}

fp_install_lutris() {
  flatpak install --user flathub net.lutris.Lutris
}

fp_install_bottles() {
  flatpak install --user flathub com.usebottles.bottles
}

is_positive_integer() {
  local LC_ALL=C
  export LC_ALL
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

is_positive_integer_range() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:digit:]]+-[[:digit:]]+$'
  [[ "$1" =~ $regex ]]
}

is_decimal() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[+-]?(([[:digit:]]+(\.[[:digit:]]*)?)|(\.[[:digit:]]+))$'
  [[ "$1" =~ $regex ]]
}

is_color_hex_code() {
  local LC_ALL=C
  export LC_ALL
  local regex='^#[[:xdigit:]]{6}([[:xdigit:]]{2})?$'
  [[ "$1" =~ $regex ]]
}

is_alphanumeric() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:alnum:]]+$'
  [[ "$1" =~ $regex ]]
}

is_printable_ascii() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[ -~]*$'
  [[ "$1" =~ $regex ]]
}

is_permissions() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[0-7]{3}$'
  [[ "$1" =~ $regex ]]
}

contains_nl_or_bs() {
  [[ "$1" =~ $'\n' ]] || [[ "$1" =~ $'\\' ]]
}

is_valid_ascii() {
  iconv --silent --from-code=ASCII --to-code=ASCII --output=/dev/null -- "${1}" 2>/dev/null
}

is_valid_utf8() {
  iconv --silent --from-code=UTF-8 --to-code=UTF-8 --output=/dev/null -- "${1}" 2>/dev/null
}

permcheck_ow() {
  find . -perm -o=w -a \! -type l
}

permcheck_ouser() {
  find . \! -user "$1"
}

gzip_deterministic() {
  touch --no-create --date='@0' -- "${1}"
  gzip --no-name --best -- "${1}"
}

tar_deterministic() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments: target [ output.tar ] [ "gzip" ]\n'
    return 0
  fi
  
  local target=''
  target="$(readlink -e -- "${1}")"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not get target\n' 1>&2
    return 1
  fi
  local target_location=''
  target_location="$(dirname -- "${target}")"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not get target location\n' 1>&2
    return 1
  fi
  local target_name=''
  target_name="$(basename -- "${target}")"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not get target filename\n' 1>&2
    return 1
  fi
  local output="${target}.tar"
  if [ -n "${2}" ] && [ "${2}" != 'gzip' ]; then
    output="${2}"
    shift 1
  fi
  if [ -e "${output}" ]; then
    printf 'Error: Output file already exists\n' 1>&2
    return 2
  fi
  
  tar --restrict --create --mtime='@0' --no-same-owner --no-same-permissions \
      --numeric-owner --owner=0 --group=0 --sort=name \
      --no-acls --no-selinux --no-xattrs \
      --pax-option='exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime' \
      --file="${output}" --directory="${target_location}" -- "${target_name}"
  
  [ "$?" -eq 0 ] && [ "$2" = 'gzip' ] && gzip_deterministic "${output}"
}

delete_if_identical_to() {
  if [ -f "${1}" ] && [ -f "${2}" ] && [ ! -L "${1}" ] && [ ! -L "${2}" ] && \
     [ "$(readlink -e -- "${1}")" != "$(readlink -e -- "${2}")" ] && \
     ! [ "$(readlink -e -- "${1}")" -ef "$(readlink -e -- "${2}")" ]; then
    cmp -- "${1}" "${2}" && rm -f -- "${1}"
  else
    printf 'Error: Files must be different regular files (and not symlinks)\n' 1>&2
    return 2
  fi
}

md5r() {
  if [ -n "${1}" ]; then
    local output="$(md5r)"
    if [ -e "${1}" ]; then
      printf 'Error: Output file already exists\n' 1>&2
      return 1
    fi
    printf -- '%s\n' "$output" > "${1}"
  else
    find . -type f -print0 | sort -z -- | xargs -0 --no-run-if-empty md5sum --
  fi
}

sha256r() {
  if [ -n "${1}" ]; then
    local output="$(sha256r)"
    if [ -e "${1}" ]; then
      printf 'Error: Output file already exists\n' 1>&2
      return 1
    fi
    printf -- '%s\n' "$output" > "${1}"
  else
    find . -type f -print0 | sort -z -- | xargs -0 --no-run-if-empty sha256sum --
  fi
}

wget_ff() {
  wget --no-verbose --no-clobber --wait=0.5 --random-wait --max-redirect 0 \
       --user-agent='Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0' \
       --secure-protocol=auto --https-only "$@"
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

proton_wine() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '    [ launcher ] (optional, make launcher for wine/steam action)\n'
    printf '  action: [ env | wine | steam ]\n'
    printf '    env: set WINE and WINEPREFIX environment variables and run command\n'
    printf '    wine: set wine env vars and run command with proton like normal wine\n'
    printf '    steam: set STEAM_COMPAT_DATA_PATH var and run command with proton\n'
    printf '    launcher: create .desktop entry for launching windows application\n'
    printf '  proton version [ version number | experimental ]\n'
    printf '  start from: [ temp-dir | current-dir | executable-dir ]\n'
    printf '    (helpful for windows programs that only check current directory for dlls)\n'
    printf '  wine prefix: [ (wine prefix path) | (steam app id) ]\n'
    printf '  command to run (or to be run with wine)\n'
    printf '    command args, OR, if making launcher:\n'
    printf '      .desktop file name\n'
    printf '      launcher name\n'
    printf '      launcher comment\n'
    printf '      launcher categories (Audio;Video;Development;Game;Graphics;Utility;etc;)\n'
    printf '      launcher icon path (optional)\n'
    return 0
  fi
  
  printf '\n'
  local launcher='no'
  if [ "$1" = 'launcher' ]; then
    launcher='yes'
    shift 1
  fi
  
  local action="$1"
  local proton_install="${HOME}/.steam/steam/steamapps/common/Proton ${2}"
  local wine_executable="${proton_install}/dist/bin/wine"
  if [ "$2" = 'experimental' ]; then
    proton_install="${HOME}/.steam/steam/steamapps/common/Proton - Experimental"
    wine_executable="${proton_install}/files/bin/wine"
  fi
  if [ ! -x "${wine_executable}" ]; then
    printf -- 'Error: Could not find specified proton version: %s\n' "$2" 1>&2
    return 1
  fi
  local steam_runtime="${HOME}/.steam/steam/ubuntu12_32/steam-runtime/run.sh"
  
  local executable_path=''
  if [ "$(type -f -t "${5}")" = 'file' ]; then
    executable_path="$(realpath -e "$(type -f -p "${5}")")"
  else
    executable_path="$(realpath -e "${5}")"
  fi
  if [ "$?" -ne 0 ]; then
    printf -- '\nError: Could not get path of executable:\n%s\n' "${5}" 1>&2
    return 1
  fi
  local orig_dir="${PWD}"
  local start_dir=''
  case "${3}" in
    'temp-dir' | 'tmp-dir') start_dir='/tmp' ;;
    'current-dir') start_dir="${orig_dir}" ;;
    'executable-dir') start_dir="$(dirname "${executable_path}")" ;;
    *)
      printf 'Error: Invalid start directory, see --help\n' 1>&2
      return 1
    ;;
  esac
  
  local prefix=''
  if is_positive_integer "${4}"; then
    if [ ! -d "${HOME}/.steam/steam/steamapps/compatdata/${4}/pfx" ]; then
      printf -- 'Error: Could not find prefix for specified steam app id: %s\n' "${4}" 1>&2
      return 1
    fi
    if [ "$action" = 'steam' ]; then
      prefix="${HOME}/.steam/steam/steamapps/compatdata/${4}"
    else
      prefix="${HOME}/.steam/steam/steamapps/compatdata/${4}/pfx"
    fi
  else
    prefix="$(realpath "${4}")" || return 1
  fi
  shift 5
  
  if [ "$launcher" = 'yes' ]; then
    local desktop_file_name="${1}"
    local escaped_name="$(escape_desktop_entry_string "$2")"
    local escaped_comment="$(escape_desktop_entry_string "$3")"
    local escaped_categories="$(escape_desktop_entry_string "$4")"
    local escaped_icon_pair='#Icon='
    [ -n "${5}" ] && escaped_icon_pair='Icon='"$(escape_desktop_entry_string "${5}")"
    local escaped_wine_executable="$(escape_desktop_entry_argument "${wine_executable}")"
    local escaped_prefix="$(escape_desktop_entry_argument "${prefix}")"
    local escaped_steam_runtime="$(escape_desktop_entry_argument "${steam_runtime}")"
    local escaped_proton_install="$(escape_desktop_entry_argument "${proton_install}")"
    local escaped_executable_path="$(escape_desktop_entry_argument "${executable_path}")"
    local escaped_command=''
    case "$action" in
      'env') escaped_command='env "WINE='"${escaped_wine_executable}"'" "WINEPREFIX='"${escaped_prefix}"'" "'"${escaped_steam_runtime}"'" "'"${escaped_executable_path}"\" ;;
      'wine') escaped_command='env "WINE='"${escaped_wine_executable}"'" "WINEPREFIX='"${escaped_prefix}"'" "'"${escaped_steam_runtime}"'" "'"${escaped_wine_executable}"'" "'"${escaped_executable_path}"\" ;;
      'steam') escaped_command='env "STEAM_COMPAT_DATA_PATH='"${escaped_prefix}"'" "'"${escaped_steam_runtime}"'" "'"${escaped_proton_install}/proton"'" run "'"${escaped_executable_path}"\" ;;
      *)
        printf 'Error: Invalid action, see --help\n' 1>&2
        return 1
      ;;
    esac
    local escaped_start_dir="$(escape_desktop_entry_string "${start_dir}")"
    local launcher_text="[Desktop Entry]
Type=Application
Name=${escaped_name}
Comment=${escaped_comment}
${escaped_icon_pair}
Exec=${escaped_command}
Path=${escaped_start_dir}
Terminal=false
Category=${escaped_categories}"
    
    printf -- 'Writing the following to %s\n\n%s\n\n' "${desktop_file_name}" "$launcher_text"
    save_desktop_entry "${desktop_file_name}" "$launcher_text"
    return
  fi
  
  if ! cd -- "${start_dir}"; then
    printf 'Error: Could not change to start directory\n' 1>&2
    return 1
  fi
  case "$action" in
    'env') env WINE="${wine_executable}" WINEPREFIX="${prefix}" "${steam_runtime}" "${executable_path}" "$@" ;;
    'wine') env WINE="${wine_executable}" WINEPREFIX="${prefix}" "${steam_runtime}" "${wine_executable}" "${executable_path}" "$@" ;;
    'steam') env STEAM_COMPAT_DATA_PATH="${prefix}" "${steam_runtime}" "${proton_install}/proton" run "${executable_path}" "$@" ;;
    *)
      printf 'Error: Invalid action, see --help\n' 1>&2
      cd -- "${orig_dir}"
      return 1
    ;;
  esac
  cd -- "${orig_dir}"
}

grep_control_chars() {
  local LC_ALL=C
  export LC_ALL
  
  local print_line_numbers=''
  case "$1" in
    'no') print_line_numbers='no' ;;
    'yes') print_line_numbers='yes' ;;
    *)
      printf -- '\e[0;31m==== Error:\e[0m Invalid print-line-numbers setting\n' 1>&2
      return 1
    ;;
  esac
  local encoding_check="$2"
  local regex="$3"
  shift 3
  
  #printf -- '==== perl-regexp: %s\n' "$regex"
  
  for in_file in "$@"; do
    if [ ! -e "${in_file}" ]; then
      printf -- '%s: file does not exist\n' "${in_file}"
      continue
    fi
    
    case "$encoding_check" in
      'ASCII')
        if ! is_valid_ascii "${in_file}"; then
          printf -- '\e[0;31m%s: (not a valid ASCII file)\e[0m\n' "${in_file}"
          continue
        fi
      ;;
      'UTF-8')
        if ! is_valid_utf8 "${in_file}"; then
          printf -- '\e[0;31m%s: (not a valid UTF-8 file)\e[0m\n' "${in_file}"
          continue
        fi
      ;;
      *)
        printf -- '\e[0;31m==== Error:\e[0m Invalid encoding specified\n' 1>&2
        return 1
      ;;
    esac
    
    local total_lines="$(grep --color='auto' --binary-files=text -c --binary --perl-regexp "$regex" -- "${in_file}")"
    
    if [ "$total_lines" -gt 0 ]; then
      printf -- '\e[0;31m%s: %s\e[0m' "${in_file}" "$total_lines"
    else
      printf -- '%s: %s' "${in_file}" "$total_lines"
    fi
    
    if [ -s "${in_file}" ] && [ ! -z "$(tail --bytes=1 "${in_file}")" ]; then
      printf ' \e[0;31m(missing newline at end of file)\e[0m'
    fi
    
    printf '\n'
    
    if [ "$total_lines" -gt 0 ] && [ "$print_line_numbers" = 'yes' ]; then
      printf -- '\e[0;36m%s\e[0m\n' \
        "$(grep --color='auto' -n --binary-files=text --binary --perl-regexp "$regex" -- "${in_file}" | \
             cut --fields=1 --delimiter=':' -- | tr '\n' ' ' )"
    fi
  done
}

grep_non_printable_ascii() {
  local chars_start='[^'
  local h_tab=''
  local newline='\x0A'
  local c_return=''
  local chars_end='\x20-\x7E]'
  local not_cr_lf=''
  local print_line_numbers='no'
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Arguments:\n'
        printf '  [ -h | --help ]\n'
        printf '  [ -t | --horizontal-tabs ] allow (ignore) horizontal tabs\n'
        printf '  [ --cr | --windows-line-endings ] expect windows line endings\n'
        printf '    (also match any CR or LF characters not paired in that order)\n'
        printf '    (lines are numbered according to LF characters even when not preceeded\n'
        printf '     by a CR character, because of how grep works)\n'
        printf '  [ -n | --line-numbers ] print line numbers in a space separated list\n'
        return 0
      ;;
      '-t' | '--horizontal-tabs')
        h_tab='\x09'
        shift 1
      ;;
      '--cr' | '--windows-line-endings')
        c_return='\x0D'
        # would like to handle line endings with \x0A rather than $, but perl's
        # (?ms) modification doesn't seem to work in grep
        not_cr_lf='|([\x0D][^\x0A])|([^\x0D]$)|(^$)'
        shift 1
      ;;
      '-n' | '--line-numbers')
        print_line_numbers='yes'
        shift 1
      ;;
      '--') shift 1 ; break ;;
      *) break ;;
    esac
  done
  local regex="${chars_start}${h_tab}${newline}${c_return}${chars_end}${not_cr_lf}"
  
  grep_control_chars "$print_line_numbers" 'ASCII' "$regex" "$@"
}

grep_utf8_control_chars() {
  local c0_controls_start='[\x00-\x08'
  local h_tab='\x09'
  local newline=''
  local vt_ff='\x0B-\x0C'
  local c_return='\x0D'
  local c0_controls_end='\x0E-\x1F\x7F]'
  local c1_controls='|([\xC2][\x80-\x9F])'
  local not_cr_lf=''
  local print_line_numbers='no'
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Arguments:\n'
        printf '  [ -h | --help ]\n'
        printf '  [ -t | --horizontal-tabs ] allow (ignore) horizontal tabs\n'
        printf '  [ --cr | --windows-line-endings ] expect windows line endings\n'
        printf '    (also match any CR or LF characters not paired in that order)\n'
        printf '    (lines are numbered according to LF characters even when not preceeded\n'
        printf '     by a CR character, because of how grep works)\n'
        printf '  [ -n | --line-numbers ] print line numbers in a space separated list\n'
        return 0
      ;;
      '-t' | '--horizontal-tabs')
        h_tab=''
        shift 1
      ;;
      '--cr' | '--windows-line-endings')
        c_return=''
        # would like to handle line endings with \x0A rather than $, but perl's
        # (?ms) modification doesn't seem to work in grep
        not_cr_lf='|([\x0D][^\x0A])|([^\x0D]$)|(^$)'
        shift 1
      ;;
      '-n' | '--line-numbers')
        print_line_numbers='yes'
        shift 1
      ;;
      '--') shift 1 ; break ;;
      *) break ;;
    esac
  done
  local regex="${c0_controls_start}${h_tab}${newline}${vt_ff}${c_return}${c0_controls_end}${c1_controls}${not_cr_lf}"
  
  grep_control_chars "$print_line_numbers" 'UTF-8' "$regex" "$@"
}

cmpimg() {
  local out_file=''
  if [ -z "${3}" ]; then
    out_file='null:'
  elif [ -e "${3}" ]; then
    printf 'Error: Output file already exists\n' 1>&2
    return 1
  else
    out_file="${3}"
  fi
  
  compare -metric AE "${1}" "${2}" "${out_file}"
  
  printf '\n'
}

cmpgif() {
  local out_file=''
  if [ -z "${3}" ]; then
    out_file='null:'
  elif [ -e "${3}" ]; then
    printf 'Error: Output file already exists\n' 1>&2
    return 1
  else
    out_file="${3}"
  fi
  
  convert \( -alpha Set "${1}" -coalesce -append \) \
          \( -alpha Set "${2}" -coalesce -append \) +depth miff:- | \
  compare -metric AE - "${out_file}"
  
  printf '\n'
}

cmpgifdiff() {
  gifdiff "${1}" "${2}"
  printf -- '%s\n' "$?"
}

sha256audio() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Like sha256sum, but decodes and computes checksum of only audio streams\n'
        printf 'Will fail for raw audio data, but sha256sum can be used for that\n\n'
        return 0
      ;;
      '--') shift 1 ; break ;;
      *) break ;;
    esac
  done
  
  local in_file=''
  for in_file in "$@"; do
    if [ ! -e "${in_file}" ]; then
      printf -- '\e[0;31m==== Error:\e[0m File does not exist:\n%s\n\n' "${in_file}" 1>&2
      return 1
    fi
    
    local ffmpeg_output=''
    ffmpeg_output="$(ffmpeg -loglevel quiet -i "${in_file}" -map '0:a' -f hash -hash SHA256 -)"
    if [ "$?" -ne 0 ]; then
      printf -- '\e[0;31m==== Error:\e[0m Could not calculate sha256 of decoded audio streams in file:\n%s\n\n' "${in_file}" 1>&2
      return 1
    fi
    local audio_sha256="$(printf -- '%s\n' "$ffmpeg_output" | cut -d '=' --fields='2-' --)"
    
    if contains_nl_or_bs "${in_file}"; then
      local escaped_filename="$(printf -- '%s' "${in_file}" | sed -z -e 's/\\/\\\\/g' -e 's/\n/\\n/g' -- -)"
      printf -- '\\%s  %s\n' "$audio_sha256" "$escaped_filename"
    else
      printf -- '%s  %s\n' "$audio_sha256" "$in_file"
    fi
  done
}

sha256video() {
  ffmpeg -loglevel error -i "$1" -map 0:v -f hash -
}

tablet_calibration() {
  # adjusted for viewing angle and hand positioning
  xinput set-float-prop 'HID 256c:006d Pen Pen (0)' 'Coordinate Transformation Matrix' \
         1.005000 -0.001500 -0.000500 0.000000 0.499500 0.500500 0.000000 0.000000 1.000000
  #      h-stretch h-off-diff h-off  v-off-diff v-stretch v-off      A        B        C
  
  # A - keep along left edge, lag h at top edge (of all monitors), lag h+v at bottom right
  # B - keep along top edge, lag v at left edge (of all monitors), lag h+v at bottom right
  # C - keep at top left corner (of all monitors), stretch v at left edge, stretch h at top edge, stretch h+v at bottom right corner
}

ffmpeg_bitexact() {
  local out_file="${1}"
  shift 1
  ffmpeg "$@" \
         -map_metadata -1 -flags bitexact -flags:v bitexact -flags:a bitexact -fflags bitexact \
         "${out_file}"
}

ffmpeg_screenrec() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  output_file.mkv\n'
    printf '  screen offset [ "x,y" ]\n'
    printf '  recording resolution [ "widthxhegiht" ]\n'
    printf '  fps [ 24 | 30 | 60 ] (24 will use decimate filter to remove dup frames)\n'
    printf '  colorspace [ yuv420p (default) | rgb24 ]\n'
    printf '  ... ffmpeg arguments, video and audio codec options, examples below:\n'
    printf '    -c:v [ libx264 | ... ]\n'
    printf '    -threads [ 1 | 2 | 3 | ... ] (libx264, more threads = small quality loss)\n'
    printf '    -tune [ film | animation | stillimage | ... ]\n'
    printf '    -crf [ ... | 22 | 23 (default) | 24 | ... ] (lower = higher quality)\n'
    printf '    -preset [ veryfast | faster | fast | medium | slow | slower | veryslow ]\n'
    printf '    -c:a [ aac | ... ]\n'
    printf '    -b:a audio bitrate [ 320k is a good choice for nearly lossless audio ]\n'
    return 0
  fi
  
  local out_file="${1}"
  local offset="$2"
  local resolution="$3"
  local fps="$4"
  local colorspace="$5"
  shift 5
  
  if contains_nl_or_bs "${out_file}" || ! is_printable_ascii "${out_file}"; then
    printf 'Error: output name cannot contain LF or \ or non-printable ascii characters\n' 1>&2
    return 1
  fi
  
  if [ "$colorspace" != 'yuv420p' ] && [ "$colorspace" != 'rgb24' ]; then
    printf 'Error: colorspace should be yuv420p or rgb24\n' 1>&2
    return 1
  fi
  local vf='format='"${colorspace}"
  if [ "$fps" = '24' ]; then
    fps='30'
    vf="decimate=cycle=5,setpts=N/24/TB,${vf}"
  fi
  
  local -a ffmpeg_args=( '-loglevel' 'warning' \
         '-f' 'x11grab' \
         '-framerate' "$fps" '-video_size' "$resolution" \
         '-draw_mouse' '0' '-show_region' '0' '-thread_queue_size' '1024' \
         '-i' "${DISPLAY}.0+${offset}" \
         '-f' 'pulse' '-channels' '2' '-ac' '2' '-thread_queue_size' '1024' \
         '-i' 'alsa_output.pci-0000_00_1f.3.analog-stereo.monitor' \
         '-filter:v' "$vf" \
         "$@" \
         '-map' '0:v:0' '-map' '1:a:0' \
         '-map_metadata' '-1' \
         '-flags' 'bitexact' '-flags:v' 'bitexact' '-flags:a' 'bitexact' \
         '-fflags' 'bitexact' \
         "${out_file}" )
  printf -- '\nrunning ffmpeg with these arguments: %s\n\n' "${ffmpeg_args[*]}"
  ffmpeg "${ffmpeg_args[@]}"
}

video_snapshot() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  (frames/)output(-%03d).png\n'
    printf '  (bluray:)input.mp4\n'
    printf '  bt709 | smpte170m (SD NTSC) video colorspace\n'
    printf '  00:00:00.00   start timestamp\n'
    printf '  00s / 1f      duration / 1f for single frame\n'
    printf '  (playlist number if bluray)\n'
    return 0
  fi
  
  local out_file="${1}"
  local in_file="${2}"
  local colorspace="$3"
  local start="$4"
  local duration="$5"
  local playlist="$6"
  
  if [ "$colorspace" != 'bt709' ] && [ "$colorspace" != 'smpte170m' ]; then
    printf 'Error: colorspace not bt709 or smpte170m\n' 1>&2
    return 1
  fi
  
  [ "$duration" = '1f' ] && duration='0.00001s'
  
  local -a ffmpeg_args=( '-loglevel' 'warning' \
                         '-ss' "$start" )
  
  [ -n "$playlist" ] && ffmpeg_args+=( '-playlist' "$playlist" )
  
  ffmpeg_args+=( '-i' "${in_file}" \
                 '-t' "$duration" \
                 '-sws_flags' '+full_chroma_inp+full_chroma_int+accurate_rnd+bitexact' \
                 '-vf' "setparams=range=limited:color_primaries=${colorspace}:color_trc=${colorspace}:colorspace=${colorspace}" \
                 '-map_metadata' '-1' '-flags' 'bitexact' '-flags:v' 'bitexact' '-flags:a' 'bitexact' '-fflags' 'bitexact' \
                 "${out_file}" )
  ffmpeg "${ffmpeg_args[@]}"
  
  printf '\n\n\n==== Must also remove gAMA chunk from pngs! (pngqoptimstripall) ====\n\n'
}

ytdl_options() {
  yt-dlp --no-overwrites --no-continue --no-mtime --no-call-home \
             --no-post-overwrites --fixup never "$@"
}

ytdl() {
  ytdl_options --output '%(extractor)s-%(uploader_id)s-%(id)s-%(format_id)s.%(ext)s' "$@"
}

ytdl_cookies() {
  ytdl --cookies 'cookies.txt' \
       --user-agent 'Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0' "$@"
}

youtube_output() {
  ytdl_options --output '%(uploader_id)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' "$@"
}

youtube_backup() {
  youtube_output --format 'bestvideo[ext=mp4],bestaudio[ext=m4a],bestvideo[ext=webm],bestaudio[acodec=opus]' "$@"
}

youtube_backup_mp4() {
  youtube_output --format 'bestvideo[ext=mp4]+bestaudio[ext=m4a]' "$@"
}

youtube_backup_video_only() {
  youtube_output --format 'bestvideo[ext=mp4],bestvideo[ext=webm]' "$@"
}

youtube_backup_audio_only() {
  youtube_output --format 'bestaudio[ext=m4a],bestaudio[acodec=opus]' "$@"
}

# arguments:
# 1 = [ jpeg | png | pngm | gif | audio | video | video-subtitled ]
# 2... = files to process
batch_optimize_files() {
  local filetype="$1"
  shift 1
  
  local success_count='0'
  local fail_count='0'
  for in_file in "$@"; do
    printf -- '======== Processing file: %s\n' "${in_file}"
    local in_size="$(stat -c '%s' "${in_file}")"
    local in_perms="$(stat -c '%a' "${in_file}")"
    if ! is_permissions "$in_perms"; then
      fail_count="$(( "$fail_count" + 1 ))"
      printf '\e[0;31m==== Error:\e[0m Could not read input file permissions\n\n\n' 1>&2
      continue
    fi
    
    # TODO: handle case where extension is missing or doesn't match container format
    local base_name="$(basename "${in_file}")"
    local extension="${base_name##*.}"
    local suffix=''
    if [ -n "${extension}" ]; then
      suffix=".${extension}"
    fi
    local temp_file=''
    temp_file="$(mktemp "--suffix=${suffix}" "${in_file}.XXXXXX")"
    if [ "$?" -ne 0 ]; then
      fail_count="$(( "$fail_count" + 1 ))"
      printf '\e[0;31m==== Error:\e[0m Could not create temp file\n\n\n' 1>&2
      continue
    fi
    
    case "$filetype" in
      'jpg' | 'jpeg')
        mozjpegtran -copy all -optimize -perfect "${in_file}" > "${temp_file}"
      ;;
      'jpgstrip' | 'jpegstrip')
        mozjpegtran -copy icc -optimize -perfect "${in_file}" > "${temp_file}"
      ;;
      'jpgstripall' | 'jpegstripall')
        mozjpegtran -copy none -optimize -perfect "${in_file}" > "${temp_file}"
      ;;
      'png')
        zopflipng -y --keepchunks=PLTE,tRNS,cHRM,gAMA,iCCP,sBIT,sRGB,iTXt,tEXt,zTXt,bKGD,hIST,pHYs,sPLT,tIME "${in_file}" "${temp_file}"
      ;;
      'pngm')
        zopflipng -m -y --keepchunks=PLTE,tRNS,cHRM,gAMA,iCCP,sBIT,sRGB,iTXt,tEXt,zTXt,bKGD,hIST,pHYs,sPLT,tIME "${in_file}" "${temp_file}"
      ;;
      'pngstrip')
        zopflipng -y --keepchunks=PLTE,tRNS,cHRM,gAMA,sRGB "${in_file}" "${temp_file}"
      ;;
      'pngmstrip')
        zopflipng -m -y --keepchunks=PLTE,tRNS,cHRM,gAMA,sRGB "${in_file}" "${temp_file}"
      ;;
      'pngmncstripall')
        zopflipng -m -y --keepcolortype --keepchunks=PLTE,tRNS "${in_file}" "${temp_file}"
      ;;
      'pngmstripall')
        zopflipng -m -y --keepchunks=PLTE,tRNS "${in_file}" "${temp_file}"
      ;;
      'pngqstripall')
        zopflipng -q --iterations=1 --filters=e -y --keepchunks=PLTE,tRNS "${in_file}" "${temp_file}"
      ;;
      'imagemagick')
        convert "${in_file}" -strip "${temp_file}"
      ;;
      'gif')
        gifsicle --merge --no-app-extensions --no-names --no-comments --no-extensions -O3 \
                 "${in_file}" > "${temp_file}"
      ;;
      'video-subtitled')
        ffmpeg_bitexact "${temp_file}" -loglevel warning -i "${in_file}" \
                        -y -c copy -c:v copy -c:a copy -c:s copy \
                        -map 0:v:0 -map 0:a:0 -map 0:s:0
      ;;
      'video')
        ffmpeg_bitexact "${temp_file}" -loglevel warning -i "${in_file}" \
                        -y -c copy -c:v copy -c:a copy \
                        -map 0:v:0 -map 0:a:0
      ;;
      'audio')
        ffmpeg_bitexact "${temp_file}" -loglevel warning -i "${in_file}" \
                        -y -c copy -c:a copy \
                        -map 0:a:0
      ;;
      *)
        printf 'Error: Invalid filetype. Valid filetypes are:\n' 1>&2
        printf '       [ png | pngm | pngstrip | pngmstrip | \n' 1>&2
        printf '         jpeg | gif | audio | video | video-subtitled ]\n' 1>&2
        return 1
      ;;
    esac
    if [ "$?" -ne 0 ]; then
      rm -f -- "${temp_file}"
      fail_count="$(( "$fail_count" + 1 ))"
      printf -- '\e[0;31m==== Error:\e[0m Could not optimize %s\n\n\n' "${in_file}" 1>&2
      continue
    fi
    
    rm -f -- "${in_file}"
    chmod "$in_perms" -- "${temp_file}"
    mv --no-target-directory "${temp_file}" "${in_file}"
    success_count="$(( "$success_count" + 1 ))"
    local out_size="$(stat -c '%s' "${in_file}")"
    
    local size_diff="$(( "$in_size" - "$out_size" ))"
    local percent_diff="$(printf -- '100 * %s / %s\n' "$size_diff" "$in_size" | bc -l)"
    printf '==== Reduced file size by %d bytes (%.2f%%)\n\n\n' "$size_diff" "$percent_diff"
  done
  printf -- '======== %s files successfully optimized\n' "$success_count"
  if [ "$fail_count" -ne 0 ]; then
    printf -- '\e[0;31m==== Note:\e[0m %s files could not be optimized due to errors\n' "$fail_count" 1>&2
  fi
}

jpgoptim() {
  batch_optimize_files 'jpeg' "$@"
}

jpgoptimstrip() {
  batch_optimize_files 'jpegstrip' "$@"
}

jpgoptimstripall() {
  batch_optimize_files 'jpegstripall' "$@"
}

pngoptim() {
  batch_optimize_files 'png' "$@"
}

pngmoptim() {
  batch_optimize_files 'pngm' "$@"
}

pngoptimstrip() {
  batch_optimize_files 'pngstrip' "$@"
}

pngmoptimstrip() {
  batch_optimize_files 'pngmstrip' "$@"
}

pngmoptimncstripall() {
  batch_optimize_files 'pngmncstripall' "$@"
}

pngmoptimstripall() {
  batch_optimize_files 'pngmstripall' "$@"
}

pngqoptimstripall() {
  batch_optimize_files 'pngqstripall' "$@"
}

imoptim() {
  batch_optimize_files 'imagemagick' "$@"
}

gifoptim() {
  batch_optimize_files 'gif' "$@"
}

stripvideo() {
  batch_optimize_files 'video' "$@"
}

# edit an 8 bit/channel srgb image in the given colorspace using imagemagick
edit_in_colorspace() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  input image\n'
    printf '  output image\n'
    printf '  working colorspace: [ LAB | sRGB | (colorspace) ]\n'
    printf '    (LAB is almost always the best option)\n'
    printf '  ...arguments to pass to imagemagick after converting to the working\n'
    printf '     colorspace, and before converting back to srgb\n'
    return 0
  fi
  
  local in_file="${1}"
  local out_file="${2}"
  local working_colorspace="$3"
  shift 3
  
  local -a im_arguments=()
  im_arguments+=( '-background' '#000000' '-alpha' 'Set' )
  im_arguments+=( '-depth' '16' '-colorspace' "$working_colorspace" )
  im_arguments+=( '-quantize' "$working_colorspace" )
  im_arguments+=( '-alpha' 'Background' )
  im_arguments+=( "$@" )
  im_arguments+=( '-colorspace' 'sRGB' '-depth' '8' )
  im_arguments+=( '-strip' )
  
  convert "${in_file}[0]" "${im_arguments[@]}" "${out_file}"
}

set_terminal_colors() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  [ background color | _ ]\n'
    printf '  [ foreground color | _ ]\n'
    printf '  [ palette | _ ]\n'
    return 0
  fi

  # default color scheme
  local bg_color="'#162a40'"
  local fg_color="'#abb3ba'"
  local palette="['#000000', '#ce2c3d', '#0da62f', '#d7c94b', '#3272d1', '#9c5bba', '#4db5d1', '#abb3ba', '#0a0d0f', '#f2182f', '#07db36', '#f2dc18', '#2e81ff', '#c75ef7', '#41cbf0', '#ffffff']"

  # sanitize arguments
  local color_regex='^'\''#[[:xdigit:]]{6}'\''$'
  local palette_regex='^\[('\''#[[:xdigit:]]{6}'\'', ){15}'\''#[[:xdigit:]]{6}'\''\]$'
  if [ -n "$1" ] && [ "$1" != _ ]; then
    if [[ ! "$1" =~ $color_regex ]]; then
      printf 'Error: Invalid background color\n' 1>&2
      return 1
    fi
    bg_color="$1"
  fi
  if [ -n "$2" ] && [ "$2" != _ ]; then
    if [[ ! "$2" =~ $color_regex ]]; then
      printf 'Error: Invalid foreground color\n' 1>&2
      return 1
    fi
    fg_color="$2"
  fi
  if [ -n "$3" ] && [ "$3" != _ ]; then
    if [[ ! "$3" =~ $palette_regex ]]; then
      printf 'Error: Invalid palette\n' 1>&2
      return 1
    fi
    palette="$3"
  fi

  local profiles="$(dconf list '/org/gnome/terminal/legacy/profiles:/')"
  local regex='^:[[:xdigit:]-]+/$'
  if [[ ! "$profiles" =~ $regex ]]; then
    # TODO: allow specifying a profile
    printf 'Error: Could not get terminal profile, or got multiple profiles\n' 1>&2
    return 1
  fi
  local profile="$profiles"
  dconf write "/org/gnome/terminal/legacy/profiles:/${profile}use-theme-colors" "false"
  dconf write "/org/gnome/terminal/legacy/profiles:/${profile}background-color" "$bg_color"
  dconf write "/org/gnome/terminal/legacy/profiles:/${profile}foreground-color" "$fg_color"
  dconf write "/org/gnome/terminal/legacy/profiles:/${profile}palette" "$palette"
}

mouse_sensitivity_config() {
  case "$1" in
    '-h' | '--help')
      printf 'Arguments:\n'
      printf '  [ desktop | gaming ]\n'
      printf '    OR:\n'
      printf '  mouse speed (-1.0 <= double <= 1.0)\n'
      printf '  mouse accel-profile [ default | flat | adaptive ]\n'
      printf '    (adaptive not recommended)\n'
      printf '\n======== Descriptions of gnome mouse settings:'
      printf '\n==== gsettings describe org.gnome.desktop.peripherals.mouse speed\n'
      gsettings describe org.gnome.desktop.peripherals.mouse speed
      printf '==== gsettings range org.gnome.desktop.peripherals.mouse speed\n'
      gsettings range org.gnome.desktop.peripherals.mouse speed
      printf '\n==== gsettings describe org.gnome.desktop.peripherals.mouse accel-profile\n'
      gsettings describe org.gnome.desktop.peripherals.mouse accel-profile
      printf '==== gsettings range org.gnome.desktop.peripherals.mouse accel-profile\n'
      gsettings range org.gnome.desktop.peripherals.mouse accel-profile
    ;;
    'desktop')
      gsettings set org.gnome.desktop.peripherals.mouse speed '-0.25'
      gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'default'
    ;;
    'gaming')
      gsettings set org.gnome.desktop.peripherals.mouse speed '0'
      gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
    ;;
    *)
      if ! is_decimal "$1"; then
        printf 'Error: Invalid speed\n' 1>&2
        return 1
      fi
      if [ "$2" != 'default' ] && [ "$2" != 'flat' ] && [ "$2" != 'adaptive' ]; then
        printf 'Error: Invalid accel-profile\n' 1>&2
        return 1
      fi
      gsettings set org.gnome.desktop.peripherals.mouse speed "$1"
      gsettings set org.gnome.desktop.peripherals.mouse accel-profile "$2"
    ;;
  esac
}

capslock_key_config() {
  case "$1" in
    '-h' | '--help')
      printf 'Arguments:\n'
      printf '  [ capslock | escape | swapescape | reset ]\n'
    ;;
    'capslock')
      gsettings set org.gnome.desktop.input-sources xkb-options "['caps:capslock']"
    ;;
    'escape')
      gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
    ;;
    'swapescape')
      gsettings set org.gnome.desktop.input-sources xkb-options "['caps:swapescape']"
    ;;
    'reset')
      gsettings reset org.gnome.desktop.input-sources xkb-options
    ;;
    *)
      printf 'Error: Invalid setting, see --help\n' 1>&2
    ;;
  esac
}

kppextract() {
  local line="$(identify -verbose "$1" | grep 'preset:' --)"
  local l1="${line#*preset: }"
  printf -- '%s\n' "$l1"
}

kpptotxt() {
  if [ -e "${1}.txt" ]; then
    printf -- 'Error: Output file %s already exists\n' "${1}.txt" 1>&2
    return 1
  fi
  local preset="$(kppextract "${1}")"
  local formatted="${preset//> <param />$'\n'<param }"
  printf -- '%s\n' "$formatted" > "${1}.txt"
}

kppdiff() {
  local preset1="$(kppextract "${1}" | xmllint --c14n -- - | xmllint --format -- -)"
  local preset2="$(kppextract "${2}" | xmllint --c14n -- - | xmllint --format -- -)"
  diff <(printf -- '%s' "$preset1") <(printf -- '%s' "$preset2")
}

kppwrite() {
  if [ -e "${2}" ]; then
    printf -- 'Error: Output file %s already exists\n' "${2}" 1>&2
    return 1
  fi
  local text="$(<"${3}")"
  local unformatted="${text//>$'\n'<param /> <param }"
  convert "${1}" -set 'preset' "$unformatted" "${2}"
}

if [ -f ~/.bash_aliases_extra ]; then
  . ~/.bash_aliases_extra
fi
