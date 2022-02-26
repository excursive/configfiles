#!/bin/bash

PATH="${PATH}:${HOME}/bin"

alias srm="rm -I"

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

is_domain() {
  local LC_ALL=C
  export LC_ALL
  local regex='^\.?([a-z0-9-]+\.)*[a-z0-9-]+\.[a-z0-9-]+$'
  [[ "$1" =~ $regex ]]
}

is_domain_list() {
  local LC_ALL=C
  export LC_ALL
  local regex='^(\.?([a-z0-9-]+\.)*[a-z0-9-]+\.[a-z0-9-]+,)*\.?([a-z0-9-]+\.)*[a-z0-9-]+\.[a-z0-9-]+,?$'
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

permcheck() {
  find . -perm -o=w -a \! -type l
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

proton_wine() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  action: [ env | wine | steam ]\n'
    printf '    env: set WINE and WINEPREFIX environment variables and run command\n'
    printf '    wine: set wine env vars and run command with proton like normal wine\n'
    printf '    steam: set STEAM_COMPAT_DATA_PATH var and run command with proton\n'
    printf '  proton version\n'
    printf '  wine prefix: [ (wine prefix path) | (steam app id) ]\n'
    printf '  start from: [ temp-dir | current-dir | executable-dir ]\n'
    printf '    (helpful for windows programs that only check current directory for dlls)\n'
    printf '  command to run (or to be run with wine)\n'
    return 0
  fi
  local action="$1"
  local proton_version="$2"
  local command_to_run="${5}"
  if [ ! -x "${HOME}/.steam/debian-installation/steamapps/common/Proton ${proton_version}/dist/bin/wine" ]; then
    printf -- 'Error: Could not find specified proton version: %s\n' "$proton_version" 1>&2
    return 1
  fi
  local orig_dir="${PWD}"
  local start_dir=''
  case "${3}" in
    'temp-dir' | 'tmp-dir')
      start_dir='/tmp'
    ;;
    'current-dir')
      start_dir="${orig_dir}"
    ;;
    'executable-dir')
      local executable_path=''
      executable_path="$(realpath -e "${command_to_run}")"
      if [ "$?" -ne 0 ]; then
        printf -- 'Error: Could not get path of executable: %s\n' "${command_to_run}" 1>&2
        return 1
      fi
      start_dir="$(dirname "${executable_path}")"
    ;;
    *)
      printf 'Error: Invalid start directory, see --help\n' 1>&2
      return 1
    ;;
  esac
  local prefix=''
  if is_positive_integer "${4}"; then
    if [ ! -d "${HOME}/.steam/debian-installation/steamapps/compatdata/${4}/pfx" ]; then
      printf -- 'Error: Could not find prefix for specified steam app id: %s\n' "${4}" 1>&2
      return 1
    fi
    if [ "$action" = 'steam' ]; then
      prefix="${HOME}/.steam/debian-installation/steamapps/compatdata/${4}"
    else
      prefix="${HOME}/.steam/debian-installation/steamapps/compatdata/${4}/pfx"
    fi
  else
    prefix="${4}"
  fi
  shift 4
  
  if ! cd -- "${start_dir}"; then
    printf 'Error: Could not change to start directory\n' 1>&2
    return 1
  fi
  case "$action" in
    'env')
      env WINE="${HOME}/.steam/debian-installation/steamapps/common/Proton ${proton_version}/dist/bin/wine" \
          WINEPREFIX="${prefix}" \
          "${HOME}/.steam/debian-installation/ubuntu12_32/steam-runtime/run.sh" \
          "$@"
    ;;
    'wine')
      env WINE="${HOME}/.steam/debian-installation/steamapps/common/Proton ${proton_version}/dist/bin/wine" \
          WINEPREFIX="${prefix}" \
          "${HOME}/.steam/debian-installation/ubuntu12_32/steam-runtime/run.sh" \
          "${HOME}/.steam/debian-installation/steamapps/common/Proton ${proton_version}/dist/bin/wine" \
          "$@"
    ;;
    'steam')
      env STEAM_COMPAT_DATA_PATH="${prefix}" \
          "${HOME}/.steam/debian-installation/ubuntu12_32/steam-runtime/run.sh" \
          "${HOME}/.steam/debian-installation/steamapps/common/Proton ${proton_version}/proton" run \
          "$@"
    ;;
    *)
      printf 'Error: Invalid action, see --help\n' 1>&2
      cd -- "${orig_dir}"
      return 1
    ;;
  esac
  cd -- "${orig_dir}"
}

grep_non_ascii() {
  local LC_ALL=C
  export LC_ALL
  
  local chars_start='[^'
  local h_tab=''
  local newline='\x0A'
  local c_return=''
  local chars_end='\x20-\x7E]'
  local not_cr_lf=''
  local print_line_numbers=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Arguments:\n'
        printf '  [ -h | --help ]\n'
        printf '  [ -t | --horizontal-tabs ] allow horizontal tabs\n'
        printf '  [ -cr | --windows-line-endings ] expect windows line endings\n'
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
      '-cr' | '--windows-line-endings')
        c_return='\x0D'
        # would like to handle line endings with \x0A rather than $, but perl's
        # (?ms) modification doesn't seem to work in grep
        not_cr_lf='|([\x0D][^\x0A])|([^\x0D]$)|(^$)'
        shift 1
      ;;
      '-n' | '--line-numbers')
        print_line_numbers='-n'
        shift 1
      ;;
      *)
        break
      ;;
    esac
  done
  local regex="${chars_start}${h_tab}${newline}${c_return}${chars_end}${not_cr_lf}"
  #printf -- '  perl-regexp: %s\n' "$regex"
  
  for in_file in "$@"; do
    if [ ! -e "${in_file}" ]; then
      printf -- '%s: file does not exist\n' "${in_file}"
      continue
    fi
    
    local total_lines="$(grep --color='auto' -c --binary --perl-regexp "$regex" -- "${in_file}")"
    
    if [ "$total_lines" -gt 0 ]; then
      printf -- '\e[0;31m%s: %s\e[0m' "${in_file}" "$total_lines"
    else
      printf -- '%s: %s' "${in_file}" "$total_lines"
    fi
    
    if [ -s "${in_file}" ] && [ ! -z "$(tail --bytes=1 "${in_file}")" ]; then
      printf ' \e[0;31m(missing newline at end of file)\e[0m'
    fi
    
    printf '\n'
    
    if [ "$total_lines" -gt 0 ] && [ "$print_line_numbers" = '-n' ]; then
      printf -- '\e[0;36m%s\e[0m\n' \
        "$(grep --color='auto' -n --binary --perl-regexp "$regex" -- "${in_file}" | \
             cut --fields=1 --delimiter=':' -- | tr '\n' ' ' )"
    fi
  done
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
  local in_file=''
  for in_file in "$@"; do
    if [ ! -e "${in_file}" ]; then
      printf -- '\e[0;31m==== Error:\e[0m File does not exist:\n%s\n' "${in_file}" 1>&2
      exit 1
    fi
    
    local ffmpeg_output=''
    ffmpeg_output="$(ffmpeg -loglevel quiet -i "${in_file}" -map 0:a -f hash -hash SHA256 - )"
    if [ "$?" -ne 0 ]; then
      printf -- '\e[0;31m==== Error:\e[0m Could not calculate sha256 of decoded audio streams in file:\n%s\n' "${in_file}" 1>&2
      exit 1
    fi
    local audio_sha256="$(printf -- '%s\n' "$ffmpeg_output" | cut -d '=' --fields='2-' -- )"
    
    if contains_nl_or_bs "${in_file}"; then
      local escaped_filename="$(printf -- '%s' "${in_file}" | sed -z -e 's/\\/\\\\/g' -e 's/\n/\\n/g' -- - )"
      printf -- '\\%s  %s\n' "$audio_sha256" "$escaped_filename"
    else
      printf -- '%s  %s\n' "$audio_sha256" "$in_file"
    fi
  done
}

sha256video() {
  ffmpeg -loglevel error -i "$1" -map 0:v -f hash -
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

youtube_backup_video_only() {
  youtube_output --format 'bestvideo[ext=mp4],bestvideo[ext=webm]' "$@"
}

youtube_backup_audio_only() {
  youtube_output --format 'bestaudio[ext=m4a],bestaudio[acodec=opus]' "$@"
}

ff_cookies_print() {
  local host_where_clause=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Formats and prints a nestcape cookies file from a firefox cookies.sqlite db\n'
        printf 'Arguments:\n'
        printf '  [ -h | --help ] print this help message\n'
        printf '  [ --hosts HOST[,HOST]... only print cookies from the given domain(s)\n'
        printf '  [ path to cookies.sqlite file ]\n'
        printf '    (will find cookies.sqlite file automatically if omitted)\n'
        return 0
      ;;
      '--host' | '--hosts')
        if ! is_domain_list "$2"; then
          printf 'Error: Missing or invalid domain(s) for --hosts option\n' 1>&2
          return 1
        fi
        local hosts="${2%,}"
        local quoted_hosts="'${hosts//,/\',\'}'"
        host_where_clause=" where host in ($quoted_hosts)"
        shift 2
      ;;
      *)
        break
      ;;
    esac
  done
  
  local sql_db=''
  if [ -n "${1}" ] && [ -r "${1}" ]; then
    sql_db="${1}"
  else
    sql_db="$(find "${HOME}/.mozilla/firefox/" -mindepth 2 -maxdepth 2 -name 'cookies.sqlite' \
                -printf '%T@ %p\0' | sort -nrz -- | cut -d ' ' -f '2-' -z -- | \
                head --lines=1 --zero-terminated -- | tr --delete '\0' )"
  fi
  # session cookies are stored elsewhere, in recovery.jsonlz4
  local json_mozlz4="$(dirname "${sql_db}")"'/sessionstore-backups/recovery.jsonlz4'
  
  # make temporary copies of cookies.sqlite and recovery.jsonlz4 in case firefox is using them
  local temp_sql_db=''
  temp_sql_db="$(mktemp --tmpdir="${PWD}" -t 'cookies.sqlite.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not copy firefox cookies.sqlite file to a temp file\n' 1>&2
    return 1
  fi
  cat "${sql_db}" >| "${temp_sql_db}"
  
  local temp_json_mozlz4=''
  temp_json_mozlz4="$(mktemp --tmpdir="${PWD}" -t 'recovery.jsonlz4.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not copy firefox recovery.jsonlz4 file to a temp file\n' 1>&2
    return 1
  fi
  dd status=none bs=12 skip=1 "if=${json_mozlz4}" "of=${temp_json_mozlz4}"
  
  local netscape_header='# Netscape HTTP Cookie File'
  local sql_cookies=''
  sql_cookies="$(sqlite3 -noheader -separator $'\t' "${temp_sql_db}" \
          "select host, case substr(host,1,1)='.' when 0 then 'FALSE' else 'TRUE' end, path, case isSecure when 0 then 'FALSE' else 'TRUE' end, expiry, name, value from moz_cookies${host_where_clause};")"
  local ret_sql="$?"
  
  rm -f -- "${temp_sql_db}"
  if [ "$ret_sql" -ne 0 ]; then
    printf 'Error: An error occurred reading the sqlite cookies database\n' 1>&2
    return 1
  fi
  
  # construct a properly formatted lz4 file from recovery.jsonlz4
  local temp_lz4=''
  temp_lz4="$(mktemp --tmpdir="${PWD}" -t 'recovery.json.lz4.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not create a valid lz4 archive from recovery.jsonlz4\n' 1>&2
    return 1
  fi
  local json_decompressed=''
  json_decompressed="$(mktemp --tmpdir="${PWD}" -t 'recovery.json.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not create uncompressed recovery.json temp flie\n' 1>&2
    return 1
  fi
  
  # all kinds of terrible things happening here
  # should really be using python or some library that can decompress arbitrary lz4 blocks
  local block_size="$(stat -c '%s' "${temp_json_mozlz4}")"
  local block_hex="$(printf -- '%08x' "$(("$block_size" & 2147483647))")"
  local hex_3="${block_hex:0:2}"
  local hex_2="${block_hex:2:2}"
  local hex_1="${block_hex:4:2}"
  local hex_0="${block_hex:6:2}"
  printf -- '\x04\x22\x4D\x18\x60\x60\x51' >> "${temp_lz4}"
  printf -- "\x${hex_0}\x${hex_1}\x${hex_2}\x${hex_3}" >> "${temp_lz4}"
  cat "${temp_json_mozlz4}" >> "${temp_lz4}"
  printf -- '\x00\x00\x00\x00' >> "${temp_lz4}"
  lz4 -q -q -d -f "${temp_lz4}" "${json_decompressed}"
  local session_cookies=''
  session_cookies="$(python3 <<EOF
import json

domains=[${quoted_hosts}]

with open('${json_decompressed}', 'r') as f:
  g=f.read()
j=json.loads(g)

for cookie in j['cookies']:
  if not domains or cookie['host'] in domains:
    flag='TRUE' if cookie['host'].startswith('.') else 'FALSE'
    print(cookie['host'], flag, cookie['path'], 'TRUE', '2147483647', cookie['name'], cookie['value'], sep='\t')
EOF
  )"
  rm -f -- "${temp_json_mozlz4}" "${temp_lz4}" "${json_decompressed}"
  
  if [ -z "$sql_cookies" ] && [ -z "$session_cookies" ]; then
    printf 'No cookies found\n' 1>&2
    return 0
  fi
  printf -- '%s\n%s\n%s\n' "$netscape_header" "$sql_cookies" "$session_cookies"
}

# ease-of-use function to write a netscape cookies.txt file with only the
# cookies from the given domain(s)
ff_cookies_txt() {
  local domains="$1"
  local output_file='cookies.txt'
  if [ -e "${output_file}" ]; then
    printf 'Error: Output file already exists\n' 1>&2
    return 1
  fi
  local output=''
  output="$(ff_cookies_print '--hosts' "$domains")"
  if [ "$?" -ne 0 ]; then
    return 1
  fi
  if [ -z "$output" ]; then
    return 0
  fi
  printf -- '%s\n' "$output" > "${output_file}"
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
