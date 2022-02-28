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

mkdir_or_exit() {
  if contains_nl_or_bs "${1}" || ! mkdir "${1}"; then
    printf -- '\e[0;31m==== Error:\e[0m Could not create directory:\n%s\n\n' "${1}" 1>&2
    exit 1
  fi
}



num_samples() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Can pass multiple files, samples for each will be listed separated by newlines\n'
    printf -- 'Arguments: [input1.flac] [input2.flac] [input3.flac]... [output.flac]\n'
    exit 0
  fi
  sox --info -s -- "$@"
}

concatenate() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [input1.flac] [input2.flac] [input3.flac]... [output.flac]\n'
    exit 0
  fi
  #ffmpeg -i 'concat:track1.wav|track2.wav|track3.wav' -c copy out.wav
  sox --no-clobber --show-progress --combine concatenate -- "$@"
}

split_by_samples() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [input.flac] [output.flac] [length 1] [length 2] [length 3]...\n'
    exit 0
  fi
  
  local -a args=()
  args+=( "${1}" "${2}" )
  shift 2
  
  if ! is_positive_integer "$1"; then
    printf -- '\e[0;31m==== Error:\e[0m Samples must be positive integers\n' 1>&2
    exit 1
  fi
  args+=( 'trim' '0' "${1}s" )
  shift 1
  while [ "$#" -gt 0 ]; do
    if ! is_positive_integer "$1"; then
      printf -- '\e[0;31m==== Error:\e[0m Samples must be positive integers\n' 1>&2
      exit 1
    fi
    args+=( ':' 'newfile' ':' 'trim' '0' "${1}s" )
    shift 1
  done
  sox --no-clobber --show-progress -- "${args[@]}"
}

audio_to_raw() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [input.___] [output.raw]\n'
    exit 0
  fi
  #ffmpeg -i "${1}" -f s16le -c:a pcm_s16le "${2}"
  sox --no-clobber --show-progress -- "${1}" --type raw "${2}"
}

raw_to_format() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [input.raw] [output.___]\n'
    exit 0
  fi
  #ffmpeg -f s16le -ar 44100 -ac 2 -i "${1}" -c:a copy "${2}"
  sox --no-clobber --show-progress --encoding signed-integer --endian little --bits 16 --channels 2 --rate 44100 -- "$@"
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
    printf 'audio is all zeros\n'
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



rip_whipper() {
  exit 1
  whipper --eject success cd --device /dev/cdrom rip --offset 6 --force-overread --unknown \
          --track-template 'disc_%N_track_%t.%x' \
          --disc-template '%d_%B' \
          --release-id 0000000
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m Ripping CD with whipper failed\n\n' 1>&2
    exit 1
  fi
}



read_toc() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [disc_audio_filename.wav] [output.toc]\n'
    exit 0
  fi
  cdrdao read-toc --source-device /dev/cdrom --datafile "${1}" "${2}"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m Reading CD toc with cdrdao failed\n\n' 1>&2
    exit 1
  fi
}


run_cyanrip() {
  cyanrip -d /dev/cdrom -s 6 -p 1=track -o flac \
          -D '{album}_{barcode}' \
          -F '{if #totaldiscs# > #1#d|disc|-}{track}' \
          -L '{album}_{barcode}' \
          -T simple \
          "$@"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m Ripping CD with cyanrip failed\n\n' 1>&2
    exit 1
  fi
}



rip_cyanrip() {
  local starting_dir="${PWD}"
  
  local info="$(run_cyanrip -I "$@")"
  
  local logfile="${PWD}/""$(printf -- '%s' "$info" | sed --quiet -e 's/^ *\(.*\.log\)$/\1/p' -- -)"
  local rip_dir="$(dirname -- "$logfile")"
  local release_id="$(printf -- '%s' "$info" | sed --quiet -e 's/^Release ID: *\([0-9a-fA-F-]\+\)$/\1/p' -- -)"
  local disc_num="$(printf -- '%s' "$info" | sed --quiet -e 's/^Disc number: *\([0-9]\+\)$/\1/p' -- -)"
  local total_discs="$(printf -- '%s' "$info" | sed --quiet -e 's/^Total discs: *\([0-9]\+\)$/\1/p' -- -)"
  local -a tracks=()
  readarray -t tracks < \
      <(printf -- '%s' "$info" | sed --quiet -e 's/^ *[^\/]*\/\(.*\.flac\)$/\1/p' -- -)
  #if grep --ignore-case -e 'HDCD detected: yes' -- "${logfile}" || ! grep -e '^HDCD detected: no' -- "${logfile}"; then
  printf -- 'Rip Directory: %s\n' "${rip_dir}"
  printf -- 'Logfile: %s\n' "${logfile}"
  printf -- 'Release ID: %s\n' "${release_id}"
  printf -- 'Disc number: %s\n' "${disc_num}"
  printf -- 'Total discs: %s\n' "${total_discs}"
  printf -- '  Tracks:\n'
  printf -- '%s\n' "${tracks[@]}"
  printf '\n'
  
  if [ -z "${logfile}" ] || [ -z "${rip_dir}" ] || [ -z "${release_id}" ] || \
      [ -z "${disc_num}" ] || [ -z "${total_discs}" ] || \
      [ "${#tracks[@]}" -eq 0 ]; then
    printf '\e[0;31m==== Error:\e[0m Could not parse one or more cyanrip info fields,\n' 1>&2
    printf '            or cyanrip could not obtain disc info\n\n' 1>&2
    exit 1
  fi
  
  sleep 3s
  mkdir_or_exit "${rip_dir}"
  read_toc "d${disc_num}.wav" "${rip_dir}/d${disc_num}.toc"
  
  sleep 3s
  run_cyanrip "$@"
  
  cd -- "${rip_dir}"
  
  printf '\n==== Saving raw audio sha256sums to raw_audio_sha256sums-d%s.txt\n' "$disc_num"
  sha256audio -- "${tracks[@]}" > "${rip_dir}/raw_audio_sha256sums-d${disc_num}.txt"
  
  printf '\n==== Checking beginning and end of rip\n'
  local pregap_zero_samples_at_beginning=''
  local t1_zero_samples_at_beginning=''
  local last_track_zero_samples_at_end=''
  case "${tracks[0]}" in
    *0.flac)
      pregap_zero_samples_at_beginning="$(zero_samples_at_beginning "${rip_dir}/${tracks[0]}")"
      t1_zero_samples_at_beginning="$(zero_samples_at_beginning "${rip_dir}/${tracks[1]}")"
    ;;
    *)
      t1_zero_samples_at_beginning="$(zero_samples_at_beginning "${rip_dir}/${tracks[0]}")"
    ;;
  esac
  local last_track_zero_samples_at_end="$(zero_samples_at_end "${rip_dir}/${tracks[-1]}")"
  if [ -n "$pregap_zero_samples_at_beginning" ]; then
    printf -- 'pregap zero samples at beginning  : %s\n' "$pregap_zero_samples_at_beginning"
  fi
  printf -- 'track 1 zero samples at beginning : %s\n' "$t1_zero_samples_at_beginning"
  printf -- 'last track zero samples at end    : %s\n\n' "$last_track_zero_samples_at_end"
  
  mv --no-target-directory -- "${logfile}" "${logfile%.log}-d${disc_num}.log"
  
  if [ "$disc_num" -eq "$total_discs" ]; then
    printf -- '\n==== All done, saving sha256sums of all files\n\n'
    sha256r sha256sums.txt
  else
    printf -- '\n==== All done with disc %s, run again with next disc\n\n' "$disc_num"
  fi
  cd -- "${starting_dir}"
}



test_function() {
  temp_raw_s16le "$@"
}



if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  printf '  operation [ sha256audio | sha256audior | \n'
  printf '              num-samples | contatenate | split-by-samples | \n'
  printf '              audio-to-raw | raw-to-format | \n'
  printf '              s16le-audio-is-zero | zero-samples-at-beginning | zero-samples-at-end | \n'
  printf '              read-toc | \n'
  printf '              run-cyanrip | rip-cyanrip ]\n'
  printf '    (see (operation) --help for operation arguments)\n'
  exit 0
fi

declare operation="$1"
shift 1
case "$operation" in
  'num-samples' | 'num_samples')
    num_samples "$@"
  ;;
  'concatenate')
    concatenate "$@"
  ;;
  'split-by-samples' | 'split_by_samples')
    split_by_samples "$@"
  ;;
  'audio-to-raw' | 'audio_to_raw')
    audio_to_raw "$@"
  ;;
  'raw-to-format' | 'raw_to_format')
    raw_to_format "$@"
  ;;
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
  'read-toc' | 'read_toc')
    read_toc "$@"
  ;;
  'run-cyanrip' | 'run_cyanrip')
    run_cyanrip "$@"
  ;;
  'rip-cyanrip' | 'rip_cyanrip')
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
