#!/bin/bash

# make bash stricter about errors
#set -e
#set -o pipefail

is_positive_integer() {
  local LC_ALL=C
  export LC_ALL
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

contains_nl_or_bs() {
  [[ "$1" =~ $'\n' ]] || [[ "$1" =~ $'\\' ]]
}

sha256audio() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Like sha256sum, but decodes and computes checksum of only audio streams\n'
        printf 'Will fail for raw audio data, but sha256sum can be used for that\n'
        exit 0
      ;;
      '--') shift 1 ; break ;;
      *) break ;;
    esac
  done
  
  local in_file=''
  for in_file in "$@"; do
    if [ ! -e "${in_file}" ]; then
      printf -- '\e[0;31m==== Error:\e[0m File does not exist:\n%s\n' "${in_file}" 1>&2
      exit 1
    fi
    
    local ffmpeg_output=''
    ffmpeg_output="$(ffmpeg -loglevel quiet -i "${in_file}" -map '0:a' -f hash -hash SHA256 -)"
    if [ "$?" -ne 0 ]; then
      printf -- '\e[0;31m==== Error:\e[0m Could not calculate sha256 of decoded audio streams in file:\n%s\n' "${in_file}" 1>&2
      exit 1
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

sha256audior() {
  # i'm not confident enough that the export/bash/xargs thing is safe, soooo
  #printf -- '\e[0;31m==== Error:\e[0m should avoid using this for now...\n' 1>&2
  #exit 1
  #gonna use it anyway though i guess
  if [ -n "${1}" ]; then
    local output="$(sha256r)"
    if [ -e "${1}" ]; then
      printf -- '\e[0;31mError:\e[0m Output file already exists\n' 1>&2
      return 1
    fi
    printf -- '%s\n' "$output" > "${1}"
  else
    (
    export -f contains_nl_or_bs sha256audio
    # ??????
    find . -type f \( -iname '*.flac' -o -iname '*.wav' -o -iname '*.raw' \) -printf '%P\0' | \
        sort -z -- | xargs -0 --no-run-if-empty -I '{}' -- bash -c 'sha256audio "$@"' _ '{}'
    )
  fi
}

temp_raw_s16le() {
  local temp_file=''
  temp_file="$(mktemp "--suffix=.raw" "raw_audio_temp_XXXXXX")"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m Could not create temp file\n\n' 1>&2
    exit 2
  fi
  ffmpeg -loglevel quiet -i "${1}" -y -map '0:a' -f s16le '-c:a' pcm_s16le "${temp_file}"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m Could not convert to raw s16le data\n\n' 1>&2
    rm -f -- "${temp_file}"
    exit 2
  fi
  printf -- '%s' "${temp_file}"
}

s16le_audio_is_zero() {
  local temp_file=''
  temp_file="$(temp_raw_s16le "${1}")"
  local num_bytes="$(stat -c '%s' "${temp_file}")"
  cmp --silent -n "$num_bytes" -- /dev/zero "${temp_file}"
  local ret="$?"
  rm -f -- "${temp_file}"
  if [ "$ret" -eq 2 ]; then
    printf '\e[0;31m==== Error:\e[0m Could not check if raw audio data is all zero\n\n' 1>&2
    exit 2
  fi
  printf -- '%s\n' "$ret" 1>&2
  exit "$ret"
}

zero_samples_at_beginning() {
  local temp_file=''
  temp_file="$(temp_raw_s16le "${1}")"
  local num_bytes="$(stat -c '%s' "${temp_file}")"
  if cmp --silent -n "$num_bytes" -- /dev/zero "${temp_file}"; then
    printf '==== Audio file is all zeros\n'
    rm -f -- "${temp_file}"
    exit 0
  fi
  local byte=''
  byte="$(cmp --verbose -n "$num_bytes" -- /dev/zero "${temp_file}" | sed --quiet -e '1s/^ *\([0-9]\+\) *[0-9]\+ *[0-9]\+$/\1/p' -- -)"
  local ret="$?"
  rm -f -- "${temp_file}"
  if [ "$ret" -eq 2 ] || ! is_positive_integer "$byte"; then
    printf '\e[0;31m==== Error:\e[0m Could not check for zero audio data\n\n' 1>&2
    exit 2
  fi
  printf -- '%s\n' "$(( ( "$byte" - 1 ) / 4 ))"
}

zero_samples_at_end() {
  local temp_file=''
  temp_file="$(temp_raw_s16le "${1}")"
  local num_bytes="$(stat -c '%s' "${temp_file}")"
  if cmp --silent -n "$num_bytes" -- /dev/zero "${temp_file}"; then
    printf '==== Audio file is all zeros\n'
    rm -f -- "${temp_file}"
    exit 0
  fi
  local byte=''
  byte="$(cmp --verbose -n "$num_bytes" -- /dev/zero "${temp_file}" | sed --quiet -e '$s/^ *\([0-9]\+\) *[0-9]\+ *[0-9]\+$/\1/p' -- -)"
  local ret="$?"
  rm -f -- "${temp_file}"
  if [ "$ret" -eq 2 ] || ! is_positive_integer "$byte"; then
    printf '\e[0;31m==== Error:\e[0m Could not check for zero audio data\n\n' 1>&2
    exit 2
  fi
  printf -- '%s\n' "$(( ( "$num_bytes" - "$byte" ) / 4 ))"
}

rip_cyanrip() {
  local info="$(cyanrip -d /dev/cdrom -s 6 -p 1=track -o flac \
                        -D '{album}_{barcode}' \
                        -F '{if #totaldiscs# > #1#disc_|disc|_}track_{track}' \
                        -L '{album}_{barcode}' \
                        -T simple \
                        -I \
                        "$@" )"
  
  local logfile="${PWD}/""$(printf -- '%s' "$info" | sed --quiet -e 's/^ *\(.*\.log\)$/\1/p' -- -)"
  local rip_dir="$(dirname -- "$logfile")"
  local release_id="$(printf -- '%s' "$info" | sed --quiet -e 's/^Release ID: *\([0-9a-fA-F-]\+\)$/\1/p' -- -)"
  local -a tracks=()
  readarray -t tracks < \
      <(printf -- '%s' "$info" | sed --quiet -e 's/^ *[^\/]*\/\(.*\.flac\)$/\1/p' -- -)
  #if grep --ignore-case -e 'HDCD detected: yes' -- "${logfile}" || ! grep -e '^HDCD detected: no' -- "${logfile}"; then
  printf -- 'Rip Directory: %s\nLogfile: %s\nRelease ID: %s\n  Tracks:\n' "${rip_dir}" "${logfile}" "${release_id}"
  printf -- '%s\n' "${tracks[@]}"
  printf '\n'
  
  if [ -z "${logfile}" ] || [ -z "${rip_dir}" ] || [ -z "${release_id}" ] || [ "${#tracks[@]}" -eq 0 ]; then
    printf '\e[0;31mError:\e[0m Could not parse one or more cyanrip info fields,\n' 1>&2
    printf '       or cyanrip could not obtain disc info\n\n' 1>&2
    exit 1
  fi
  
  sleep 15s
  
  cyanrip -d /dev/cdrom -s 6 -p 1=track -o flac \
          -D '{album}_{barcode}' \
          -F '{if #totaldiscs# > #1#disc_|disc|_}track_{track}' \
          -L '{album}_{barcode}' \
          -T simple \
          "$@"
  
  cd -- "${rip_dir}"
  if [ -e "${1}" ]; then
    printf '==== Appending raw audio sha256sums to existing checksums in\n'
    printf '     [rip_dir]/raw_audio_sha256sums.txt\n'
  else
    printf '==== Saving raw audio sha256sums to [rip_dir]/raw_audio_sha256sums.txt\n'
  fi
  sha256audio -- "${tracks[@]}" >> "${rip_dir}/raw_audio_sha256sums.txt"
}

test_function() {
  temp_raw_s16le "$@"
}

if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  printf '  operation [ sha256audio | sha256audior | \n'
  printf '              s16le-audio-is-zero | zero-samples-at-beginning | zero-samples-at-end | \n'
  printf '              disc-info | rip-cyanrip ]\n'
  printf '    (see (operation) --help for operation arguments)\n'
  exit 0
fi

declare operation="$1"
shift 1
case "$operation" in
  'sha256audio')
    sha256audio "$@"
  ;;
  'sha256audior')
    sha256audior "$@"
  ;;
  's16le-audio-is-zero' | 's16le_audio_is_zero')
    s16le_audio_is_zero "$@"
  ;;
  'zero-samples-at-beginning' | 'zero_samples_at_beginning')
    zero_samples_at_beginning "$@"
  ;;
  'zero-samples-at-end' | 'zero_samples_at_end')
    zero_samples_at_end "$@"
  ;;
  'disc_info' | 'disc-info')
    disc_info "$@"
  ;;
  'rip_cyanrip' | 'rip-cyanrip')
    rip_cyanrip "$@"
  ;;
  'test' | 'test-function' | 'test_function')
    test_function "$@"
  ;;
  *)
    printf '\nError: Invalid operation\n'
    exit 1
  ;;
esac

exit 0
