#!/bin/bash

# make bash stricter about errors
#set -e
#set -o pipefail

is_whole_number() {
  local LC_ALL=C
  export LC_ALL
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

is_positive_integer() {
  local LC_ALL=C
  export LC_ALL
  case "$1" in
    '0') return 1 ;;
    *) is_whole_number "$1" ;;
  esac
}

is_negative_integer() {
  local LC_ALL=C
  export LC_ALL
  case "$1" in
    '-0') return 1 ;;
    -*) is_whole_number "${1#-}" ;;
    *) return 1 ;;
  esac
}

is_integer() {
  is_whole_number "${1#-}"
}

contains_nl() {
  local newline='
'
  case "$1" in
    *"$newline"*) return 0 ;;
    *) return 1 ;;
  esac
}

contains_bs() {
  case "$1" in
    *'\'*) return 0 ;;
    *) return 1 ;;
  esac
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

is_listed_track() {
  local LC_ALL=C
  export LC_ALL
  printf -- '%s' "$1" | grep --binary-files=text -c --binary '^d[0-9]\+-[0-9]\{2\}\.\(wav\|flac\)$' -- >/dev/null
}

verify_cdda_wav() {
  local file=''
  for file in "$@"; do
    [ "$(sox --info -t -- "${file}")" = 'wav' ] && \
    [ "$(sox --info -r -- "${file}")" = '44100' ] && \
    [ "$(sox --info -c -- "${file}")" = '2' ] && \
    [ "$(sox --info -b -- "${file}")" = '16' ] && continue
    printf '\n\e[0;31m==== Error:\e[0m Not a s16le 2 channel wav: %s\n\n' "${file}" 1>&2
    exit 1
  done
}

is_valid_utf8() {
  iconv --silent --from-code=UTF-8 --to-code=UTF-8 --output=/dev/null -- "${1}" 2>/dev/null
}

mkdir_or_exit() {
  if contains_nl "${1}" || contains_bs "${1}" || [ ! -d "${1}" ] && ! mkdir -- "${1}"; then
    printf -- '\e[0;31mError:\e[0m Could not create directory:\n%s\n\n' "${1}" 1>&2
    exit 1
  fi
}





# arguments: [file to append to] [tag name] [contents]
output_vorbis_tag() {
  local LC_ALL=C
  export LC_ALL
  
  if [ -z "$3" ]; then
    printf -- '== Empty tag %s, not writing to %s\n' "$2" "${1}" 1>&2
    return 1
  fi
  
  if contains_nl "$3"; then
    printf '\n\e[0;31m==== Error:\e[0m Tag contains newline character(s)\n\n' 1>&2
    exit 1
  fi
  
  printf -- '%s' "$3" | grep --binary-files=text -c --binary --perl-regexp '[\x00-\x1F\x7F]|([\xC2][\x80-\x9F])' -- >/dev/null
  if [ "$?" -ne 1 ]; then
    printf '\n\e[0;31m==== Error:\e[0m Tag contains invalid characters\n\n' 1>&2
    exit 1
  fi
  
  printf -- '%s=%s\n' "$2" "$3" >> "${1}"
}

check_tag_file() {
  local LC_ALL=C
  export LC_ALL
  
  if ! is_valid_utf8 "${1}"; then
    printf '\n\e[0;31m==== Error:\e[0m Tag file is not valid UTF-8\n\n' 1>&2
    exit 1
  fi
  
  grep --binary-files=text -c --binary --perl-regexp '[\x00-\x1F\x7F]|([\xC2][\x80-\x9F])' -- "${1}" >/dev/null
  if [ "$?" -ne 1 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Tag file contains invalid characters: %s\n' "${1}" 1>&2
    exit 1
  fi
  
  grep --binary-files=text -c --binary --invert-match '^\(TITLE\|ALBUM\|ALBUMARTIST\|DISCNUMBER\|DISCSUBTITLE\|DISCTOTAL\|TRACKNUMBER\|TRACKTOTAL\|ARTIST\|DATE\)=.\+$' -- "${1}" >/dev/null
  if [ "$?" -ne 1 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Tag file is improperly formatted: %s\n' "${1}" 1>&2
    exit 1
  fi
}

parse_mb_request() {
  # xmllint doesn't like namespace in xml response, so remove it
  if ! is_valid_utf8 "${1}"; then
    printf '\n\e[0;31m==== Error:\e[0m XML file is not valid UTF-8\n\n' 1>&2
    exit 1
  fi
  local temp_file=''
  temp_file="$(mktemp "--suffix=.xml" "mb_request_xml_temp_XXXXXX")" || exit 1
  sed -e '2s/^<metadata xmlns="[^"]*"/<metadata/' -- "${1}" | xmllint --nonet --format - > "${temp_file}"
  if [ "$?" -ne 0 ]; then
    printf '\n\e[0;31m==== Error:\e[0m Could not create parse xml file\n\n' 1>&2
    exit 1
  fi
  rm -f -- "${1}"
  mv --no-clobber --no-target-directory -- "${temp_file}" "${1}"
  local xml="${1}"
  
  local release_title="$(xmllint --nonet --xpath 'string((/metadata/release/title)[1])' "${xml}")"
  
  local num_album_artists="$(xmllint --nonet --xpath 'count(/metadata/release/artist-credit/name-credit/artist/name)' "${xml}")"
  [ "$num_album_artists" -ne 0 ] || exit 1
  local -a album_artists=()
  local current_album_artist=1
  while [ "$current_album_artist" -le "$num_album_artists" ]; do
    album_artists+=( "$(xmllint --nonet --xpath "string((/metadata/release/artist-credit/name-credit/artist/name)[${current_album_artist}])" "${xml}")" )
    current_album_artist="$(( "$current_album_artist" + 1 ))"
  done
  
  local total_discs="$(xmllint --nonet --xpath 'string((/metadata/release/medium-list/@count)[1])' "${xml}")"
  [ "$total_discs" -ne 0 ] || exit 1
  local current_disc=1
  while [ "$current_disc" -le "$total_discs" ]; do
    
    local disc_subtitle="$(xmllint --nonet --xpath "string((/metadata/release/medium-list/medium[position=${current_disc}]/title)[1])" "${xml}")"
    
    local total_tracks="$(xmllint --nonet --xpath "string((/metadata/release/medium-list/medium[position=${current_disc}]/track-list/@count)[1])" "${xml}")"
    [ "$total_tracks" -ne 0 ] || exit 1
    local current_track=1
    while [ "$current_track" -le "$total_tracks" ]; do
      
      local track_title="$(xmllint --nonet --xpath "string((/metadata/release/medium-list/medium[position=${current_disc}]/track-list/track[position=${current_track}]/recording/title)[1])" "${xml}")"
      
      local num_track_artists="$(xmllint --nonet --xpath "count(/metadata/release/medium-list/medium[position=${current_disc}]/track-list/track[position=${current_track}]/recording/artist-credit/name-credit/artist/name)" "${xml}")"
      [ "$num_track_artists" -ne 0 ] || exit 1
      local -a track_artists=()
      local current_track_artist=1
      while [ "$current_track_artist" -le "$num_track_artists" ]; do
        track_artists+=( "$(xmllint --nonet --xpath "string((/metadata/release/medium-list/medium[position=${current_disc}]/track-list/track[position=${current_track}]/recording/artist-credit/name-credit/artist/name)[${current_track_artist}])" "${xml}")" )
        current_track_artist="$(( "$current_track_artist" + 1 ))"
      done
      
      local track_date="$(xmllint --nonet --xpath "string((/metadata/release/medium-list/medium[position=${current_disc}]/track-list/track[position=${current_track}]/recording/first-release-date)[1])" "${xml}")"
      
      # output vorbis style tags for this track to text file
      local track_num_02d="$(printf -- '%02d' "$current_track")"
      local track_out_file="d${current_disc}-${track_num_02d}-metadata.txt"
      if [ -e "${track_out_file}" ]; then
        printf -- '\e[0;31m==== Error:\e[0m Output file %s already exists\n\n' "${track_out_file}" 1>&2
        exit 1
      fi
      output_vorbis_tag "${track_out_file}" 'TITLE' "$track_title"
      output_vorbis_tag "${track_out_file}" 'ALBUM' "$release_title"
      local album_artist=''
      for album_artist in "${album_artists[@]}"; do
        output_vorbis_tag "${track_out_file}" 'ALBUMARTIST' "$album_artist"
      done
      output_vorbis_tag "${track_out_file}" 'DISCNUMBER' "$current_disc"
      output_vorbis_tag "${track_out_file}" 'DISCSUBTITLE' "$disc_subtitle"
      output_vorbis_tag "${track_out_file}" 'DISCTOTAL' "$total_discs"
      output_vorbis_tag "${track_out_file}" 'TRACKNUMBER' "$current_track"
      output_vorbis_tag "${track_out_file}" 'TRACKTOTAL' "$total_tracks"
      local track_artist=''
      for track_artist in "${track_artists[@]}"; do
        output_vorbis_tag "${track_out_file}" 'ARTIST' "$track_artist"
      done
      output_vorbis_tag "${track_out_file}" 'DATE' "$track_date"
      
      check_tag_file "${track_out_file}"
      
      current_track="$(( "$current_track" + 1 ))"
    done
    
    current_disc="$(( "$current_disc" + 1 ))"
  done
  
  rm -f -- "${xml}"
  printf '\n==== All done!\n\n'
}





# converts input audio file to headerless s16le 2 channel raw audio, and writes it
# to a temp file, and prints its name. exits with 0 if successful.
mktemp_raw() {
  local temp_file=''
  temp_file="$(mktemp "--suffix=.raw" "raw_audio_temp_XXXXXX")" || exit 1
  #if ! ffmpeg -loglevel quiet -i "${1}" -y -map '0:a' -f s16le '-c:a' pcm_s16le "${temp_file}"; then
  if ! sox -V0 -- "${1}" --type raw "${temp_file}"; then
    rm -f -- "${temp_file}"
    exit 2
  fi
  printf -- '%s' "${temp_file}"
}

# input file must be headerless s16le 2 channel raw audio data
# if extension is .wav, assume actual audio format is correct and header is 44 bytes
print_samples() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [ input ] [ start (1 based index) ] [ length ]\n'
    printf -- '  negative starting samples are relative to end of input\n\n'
    exit 0
  fi
  if ! [ -z "$2" ] && ! is_negative_integer "$2" && ! is_positive_integer "$2"; then
    printf -- '\e[0;31m==== Error:\e[0m Invalid start sample\n\n' 1>&2
    exit 1
  fi
  if ! [ -z "$3" ] && ! is_positive_integer "$3"; then
    printf -- '\e[0;31m==== Error:\e[0m Invalid length\n\n' 1>&2
    exit 1
  fi
  local input="${1}"
  local start='1'
  [ -n "$2" ] && start="$2"
  local length="$3"
  local wav_header='0'
  case "${input}" in
    *.wav)
      verify_cdda_wav "${input}"
      wav_header='44'
    ;;
  esac
  local num_bytes="$(stat -c '%s' "${input}")"
  local num_samples="$(( ( "${num_bytes}" - "$wav_header" ) / 4 ))"
  is_negative_integer "$start" && start="$(( "$num_samples" + "$start" + 1 ))"
  if ! is_positive_integer "$start" || [ "$start" -gt "$num_samples" ]; then
    printf -- '\e[0;31m==== Error:\e[0m Invalid start sample\n\n' 1>&2
    exit 1
  fi
  local -a args=( "--skip-bytes=$(( ( ( "$start" * 4 ) - 4 ) + "$wav_header" ))" )
  is_positive_integer "$length" && args+=( "--read-bytes=$(( "$length" * 4 ))" )
  od --output-duplicates --address-radix=n --endian=little --format=d2 --width=4 "${args[@]}" -- "${input}"
}

num_samples() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Can pass multiple files, samples for each will be listed separated by newlines\n'
    printf -- 'Arguments: [input1.flac] [input2.flac] [input3.flac]... [output.flac]\n\n'
    exit 0
  fi
  sox --info -s -- "$@"
}

concatenate() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [input1.flac] [input2.flac] [input3.flac]... [output.flac]\n\n'
    exit 0
  fi
  #ffmpeg -i 'concat:track1.wav|track2.wav|track3.wav' -c copy out.wav
  sox --no-clobber --show-progress --combine concatenate -- "$@"
}



# splits an audio file by lengths in samples, or sample timestamps in original file
split_by_samples() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [ lengths | timestamps ] [ input ] [ output ] [ samples ] ...\n\n'
    exit 0
  fi
  
  local method="$1"
  shift 1
  if [ "$method" != 'lengths' ] && [ "$method" != 'timestamps' ]; then
    printf -- '\e[0;31m==== Error:\e[0m Method must be lengths or timestamps\n\n' 1>&2
    exit 1
  fi
  
  local total_samples=''
  total_samples="$(num_samples "${1}")"
  if [ "$?" -ne 0 ] || ! is_positive_integer "$total_samples"; then
    printf -- '\e[0;31m==== Error:\e[0m Could not get total samples\n\n' 1>&2
    exit 1
  fi
  local split_samples='0'
  
  local -a args=()
  args+=( "${1}" "${2}" )
  shift 2
  
  if ! is_positive_integer "$1"; then
    printf -- '\e[0;31m==== Error:\e[0m Samples must be positive integers\n\n' 1>&2
    exit 1
  fi
  split_samples="$(( "$split_samples" + "$1" ))"
  args+=( 'trim' '0' "${1}s" )
  shift 1
  while [ "$#" -gt 0 ]; do
    if ! is_positive_integer "$1"; then
      printf -- '\e[0;31m==== Error:\e[0m Samples must be positive integers\n\n' 1>&2
      exit 1
    fi
    local length="$1"
    if [ "$method" = 'timestamps' ]; then
      length="$(( "$1" - "$split_samples" ))"
    fi
    split_samples="$(( "$split_samples" + "$length" ))"
    if [ "$split_samples" -gt "$total_samples" ]; then
      printf -- '\e[0;31m==== Error:\e[0m Requested samples beyond end of audio\n\n' 1>&2
      exit 1
    fi
    args+=( ':' 'newfile' ':' 'trim' '0' "${length}s" )
    shift 1
  done
  local samples_remaining="$(( "$total_samples" - "$split_samples" ))"
  if [ "$samples_remaining" -gt 0 ]; then
    args+=( ':' 'newfile' ':' 'trim' '0' "${samples_remaining}s" )
  fi
  sox --no-clobber --show-progress -- "${args[@]}"
  
  if [ "$?" -ne 0 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Could not split audio file\n\n' 1>&2
    exit 1
  fi
}



concat_wav_test() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [ input.wav ] [ part1.wav ] [ part2.wav ] ...\n\n'
    printf -- 'Checks if input matches the concatenation of part 1 + 2 + ...\n'
    exit 0
  fi
  verify_cdda_wav "$@"
  local input="${1}"
  shift 1
  
  local temp_concat=''
  temp_concat="$(mktemp --dry-run --suffix='.wav' 'concat-test-XXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Could not get temp file names\n\n' 1>&2
    exit 1
  fi
  
  sox --no-clobber --combine concatenate -- "$@" "${temp_concat}"
  
  cmp -- "${input}" "${temp_concat}"
  if [ "$?" -ne 0 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Concat test failed to produce original wav\n\n' 1>&2
    exit 1
  fi
  printf -- '\n==== sha256sums of input and concat test:\n'
  sha256sum -- "${input}" "${temp_concat}"
  delete_if_identical_to "${temp_concat}" "${input}"
  if [ "$?" -ne 0 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Concat test failed to produce original wav\n\n' 1>&2
    exit 1
  fi
  printf -- '\n==== Concat test passed\n\n'
}



to_raw() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [input.___] [output.raw]\n\n'
    exit 0
  fi
  local output="${2}"
  if [ -z "${output}" ]; then
    output="${1}.raw"
  fi
  #ffmpeg -loglevel quiet -i "${1}" -map '0:a' -f s16le '-c:a' pcm_s16le "${2}"
  sox --no-clobber --show-progress -- "${1}" --type raw "${output}"
}

raw_to_format() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [input.raw] [output.___]\n\n'
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
        printf 'Will fail for raw audio data, but sha256sum can be used for that\n\n'
        exit 0
      ;;
      '--') shift 1 ; break ;;
      *) break ;;
    esac
  done
  
  local in_file=''
  for in_file in "$@"; do
    if [ ! -e "${in_file}" ]; then
      printf -- '\e[0;31m==== Error:\e[0m File does not exist:\n%s\n\n' "${in_file}" 1>&2
      exit 1
    fi
    
    local ffmpeg_output=''
    ffmpeg_output="$(ffmpeg -loglevel quiet -i "${in_file}" -map '0:a' -f hash -hash SHA256 -)"
    if [ "$?" -ne 0 ]; then
      printf -- '\e[0;31m==== Error:\e[0m Could not calculate sha256 of decoded audio streams in file:\n%s\n\n' "${in_file}" 1>&2
      exit 1
    fi
    local audio_sha256="$(printf -- '%s\n' "$ffmpeg_output" | cut -d '=' --fields='2-' --)"
    
    if contains_nl "${in_file}" || contains_bs "${in_file}"; then
      local escaped_filename="$(printf -- '%s' "${in_file}" | sed -z -e 's/\\/\\\\/g' -e 's/\n/\\n/g' -- -)"
      printf -- '\\%s  %s\n' "$audio_sha256" "${escaped_filename%.*}.raw"
    else
      printf -- '%s  %s\n' "$audio_sha256" "${in_file%.*}.raw"
    fi
  done
}



sha256audior() {
  # i'm not confident enough that the export/bash/xargs thing is safe, soooo
  #printf -- '\e[0;31m==== Error:\e[0m should avoid using this for now...\n' 1>&2
  #exit 1
  #gonna use it anyway though i guess
  if [ -n "${1}" ]; then
    local output="$(sha256audior)"
    if [ -e "${1}" ]; then
      printf -- '\e[0;31mError:\e[0m Output file already exists\n\n' 1>&2
      return 1
    fi
    printf -- '%s\n' "$output" > "${1}"
  else
    (
    export -f contains_nl contains_bs sha256audio
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
      printf 'Error: Output file already exists\n\n' 1>&2
      return 1
    fi
    printf -- '%s\n' "$output" > "${1}"
  else
    find . -type f -print0 | sort -z -- | xargs -0 --no-run-if-empty sha256sum --
  fi
}



# arguments: [ all | beginning | end ] [input.raw|wav]
check_0_samples() {
  local num_bytes=''
  num_bytes="$(stat -c '%s' "${2}")"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m Could not get size of input file\n\n' 1>&2
    exit 2
  fi
  local skip='0'
  case "${2}" in
    *.wav)
      skip='0:44'
      num_bytes="$(( "$num_bytes" - 44 ))"
    ;;
  esac
  
  cmp --silent "--ignore-initial=${skip}" -n "$num_bytes" -- /dev/zero "${2}"
  case "$?" in
    '2')
      printf '\e[0;31m==== Error:\e[0m Could not check if raw audio data is all zero\n\n' 1>&2
      exit 2
    ;;
    '1')
      if [ "$1" = 'all' ]; then
        printf -- '1\n' 1>&2
        return 1
      fi
    ;;
    '0')
      printf -- 'audio is all zeros\n' 1>&2
      return 0
    ;;
  esac
  
  local byte=''
  case "$1" in
    'beginning')
      byte="$(cmp --verbose "--ignore-initial=${skip}" -n "$num_bytes" -- /dev/zero "${2}" | sed --quiet -e '1s/^ *\([0-9]\+\) *[0-9]\+ *[0-9]\+$/\1/p' -- -)"
    ;;
    'end')
      byte="$(cmp --verbose "--ignore-initial=${skip}" -n "$num_bytes" -- /dev/zero "${2}" | sed --quiet -e '$s/^ *\([0-9]\+\) *[0-9]\+ *[0-9]\+$/\1/p' -- -)"
    ;;
  esac
  if [ "$?" -eq 2 ] || ! is_positive_integer "$byte"; then
    printf '\e[0;31m==== Error:\e[0m Could not check for zero audio data\n\n' 1>&2
    exit 2
  fi
  
  case "$1" in
    'beginning') printf -- '%s\n' "$(( ( "$byte" - 1 ) / 4 ))" ;;
    'end') printf -- '%s\n' "$(( ( "$num_bytes" - "$byte" ) / 4 ))" ;;
  esac
}



test_raw() {
  local operation="$1"
  shift 1
  case "$operation" in
    'print-samples') print_samples "$@" ;;
    'a0s') check_0_samples 'all' "$@" ;;
    'b0s') check_0_samples 'beginning' "$@" ;;
    'e0s') check_0_samples 'end' "$@" ;;
  esac
}



# [operiation] [input file]
test_audio() {
  local audio="${2}"
  case "${audio}" in
    *.raw)
      printf -- '==== File extension is .raw, assuming input is raw s16le 2 channel audio\n\n' 1>&2
      test_raw "$@"
    ;;
    *.wav)
      printf -- '==== File extension is .wav, assuming input is raw s16le 2 channel\n' 1>&2
      printf -- '     uncompressed wav file with 44 byte header\n\n' 1>&2
      verify_cdda_wav "${2}"
      test_raw "$@"
    ;;
    *)
      local operation="$1"
      local temp_file=''
      temp_file="$(mktemp_raw "${2}")"
      if [ "$?" -ne 0 ]; then
        printf '\e[0;31m==== Error:\e[0m Could not convert to raw s16le data\n\n' 1>&2
        exit 1
      fi
      shift 2
      test_raw "$operation" "${temp_file}" "$@"
      local ret="$?"
      rm -f -- "${temp_file}"
      exit "$ret"
    ;;
  esac
}



trim_overreads() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [ disc number ]\n'
    printf -- '  Expects to find in current directory:\n'
    printf -- '    d#-overread-lead-in.wav\n'
    printf -- '      20 sectors (11760s) followed by 2981 sectors (1752828s) matching d#.wav\n'
    printf -- '    d#.wav\n'
    printf -- '    d#-overread-lead-out.wav\n'
    printf -- '      2982 sectors (1753416s) matching d#.wav followed by 19 sectors (11172s)\n'
    exit 0
  fi
  
  local lead_in="d${1}-overread-lead-in.wav"
  local disc="d${1}.wav"
  local lead_out="d${1}-overread-lead-out.wav"
  verify_cdda_wav "${lead_in}" "${disc}" "${lead_out}"
  
  local disc_samples="$(sox --info -s -- "${disc}")"
  local disc_bytes="$(stat -c '%s' "${disc}")"
  if [ "$(( ( "$disc_samples" * 4 ) + 44 ))" -ne "$disc_bytes" ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Disc not expected number of bytes\n\n' 1>&2
    exit 1
  fi
  
  local temp_base=''
  temp_base="$(mktemp --dry-run --suffix='.wav' 'split_temp_XXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Could not create temp file names\n\n' 1>&2
    exit 1
  fi
  local temp1="${temp_base%.wav}001.wav"
  local temp2="${temp_base%.wav}002.wav"
  local temp1_samples=''
  local temp2_samples=''
  local overlap_bytes=''
  
  # ======== lead-in ========
  
  split_by_samples 'lengths' "${lead_in}" "${temp_base}" 11760
  
  temp1_samples="$(sox --info -s -- "${temp1}")"
  if ! [ "$temp1_samples" -eq 11760 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Length of lead-in split 1 is not 11760 (20 sectors)\n\n' 1>&2
    exit 1
  fi
  temp2_samples="$(sox --info -s -- "${temp2}")"
  if ! [ "$temp2_samples" -eq 1752828 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Length of lead-in split 2 is not 1752828 (2981 sectors)\n\n' 1>&2
    exit 1
  fi
  printf -- '\n==== Sample count for lead-in split 1:\n'
  printf -- '%s - %s\n' "$temp1_samples" "${temp1}"
  
  concat_wav_test "${lead_in}" "${temp1}" "${temp2}"
  
  overlap_bytes="$(stat -c '%s' "${temp2}")"
  if [ "$?" -ne 0 ] || ! is_positive_integer "$overlap_bytes"; then
    printf -- '\n\e[0;31m==== Error:\e[0m Could not get filesize of lead-in split 2\n\n' 1>&2
    exit 1
  fi
  if [ "$(( ( "$temp2_samples" * 4 ) + 44 ))" -ne "$overlap_bytes" ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Lead-in split 2 not expected number of bytes\n\n' 1>&2
    exit 1
  fi
  cmp --ignore-initial=44 -n "$(( "$overlap_bytes" - 44 ))" -- "${temp2}" "${disc}"
  if [ "$?" -ne 0 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Lead-in overlap does not match disc image\n\n' 1>&2
    exit 1
  fi
  cmp --ignore-initial=44 -- "${temp2}" "${disc}"
  
  printf '\n==== All good, replacing lead-in with split 1\n\n'
  rm -f -- "${lead_in}" "${temp2}"
  mv --no-clobber --no-target-directory "${temp1}" "${lead_in}"
  
  # ======== lead-out ========
  
  split_by_samples 'lengths' "${lead_out}" "${temp_base}" 1753416
  
  temp1_samples="$(sox --info -s -- "${temp1}")"
  if ! [ "$temp1_samples" -eq 1753416 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Length of lead-out split 1 is not 1753416 (2982 sectors)\n\n' 1>&2
    exit 1
  fi
  temp2_samples="$(sox --info -s -- "${temp2}")"
  if ! [ "$temp2_samples" -eq 11172 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Length of lead-out split 2 is not 11172 (19 sectors)\n\n' 1>&2
    exit 1
  fi
  printf -- '\n==== Sample count for lead-out split 2:\n'
  printf -- '%s - %s\n' "$temp2_samples" "${temp2}"
  
  concat_wav_test "${lead_out}" "${temp1}" "${temp2}"
  
  overlap_bytes="$(stat -c '%s' "${temp1}")"
  if [ "$?" -ne 0 ] || ! is_positive_integer "$overlap_bytes"; then
    printf -- '\n\e[0;31m==== Error:\e[0m Could not get filesize of lead-out split 1\n\n' 1>&2
    exit 1
  fi
  if [ "$(( ( "$temp1_samples" * 4 ) + 44 ))" -ne "$overlap_bytes" ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Lead-out split 1 not expected number of bytes\n\n' 1>&2
    exit 1
  fi
  cmp --ignore-initial="$(( "$disc_bytes" - "$overlap_bytes" + 44 ))"':44' -- "${disc}" "${temp1}"
  if [ "$?" -ne 0 ]; then
    printf -- '\n\e[0;31m==== Error:\e[0m Lead-out overlap does not match disc image\n\n' 1>&2
    exit 1
  fi
  
  printf -- '==== All good, replacing lead-out with split 2\n\n'
  rm -f -- "${lead_out}" "${temp1}"
  mv --no-clobber --no-target-directory "${temp2}" "${lead_out}"
  
  printf -- '==== Appending sha256sums to sha256sums-wav.txt\n\n'
  printf -- '%s\n' "$(sha256sum "${lead_in}" "${disc}" "${lead_out}")" >> 'sha256sums-wav.txt'
}



cleanup_split_tracks() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [ disc number ]\n'
    printf -- '  run in directory with individual tracks after trimming overreads,\n'
    printf -- '  parsing metadata, and putting disc image to check against in same directory\n'
    exit 0
  fi
  
  local disc_number="$1"
  if ! is_positive_integer "$disc_number"; then
    printf -- '\e[0;31m==== Error:\e[0m Disc number must be a positive integer\n\n' 1>&2
    exit 1
  fi
  
  local -a tracks=()
  readarray -d '' -t tracks < \
      <(find . -type f -regextype posix-extended -regex "\./d${disc_number}-(0[123456789]|[123456789][0123456789]|00-pregap)?\.(wav|flac)" -printf '%P\0' | sort -z -- -)
  
  concat_wav_test "d${disc_number}.wav" "${tracks[@]}"
  
  if [ -e "d${disc_number}-overread-lead-in.wav" ]; then
    tracks=( "d${disc_number}-overread-lead-in.wav" "${tracks[@]}" )
  elif [ -e "d${disc_number}-overread-lead-in.flac" ]; then
    tracks=( "d${disc_number}-overread-lead-in.flac" "${tracks[@]}" )
  else
    printf '\n\e[0;31m==== Error:\e[0m Could not find d%s-overread-lead-in.wav\n\n' "${disc_number}" 1>&2
    exit 1
  fi
  if [ -e "d${disc_number}-overread-lead-out.wav" ]; then
    tracks+=( "d${disc_number}-overread-lead-out.wav" )
  elif [ -e "d${disc_number}-overread-lead-out.flac" ]; then
    tracks+=( "d${disc_number}-overread-lead-out.flac" )
  else
    printf '\n\e[0;31m==== Error:\e[0m Could not find d%s-overread-lead-out.wav\n\n' "${disc_number}" 1>&2
    exit 1
  fi
  
  printf '==== Appending track raw audio sha256sums to sha256sums-raw.txt\n\n'
  sha256audio "${tracks[@]}" >> 'sha256sums-raw.txt'
  
  printf -- '\n==== Processing tracks:\n'
  local track=''
  for track in "${tracks[@]}"; do
    local track_out_name=''
    local metadata=''
    case "${track}" in
      *'.wav')
        track_out_name="${track%.wav}.flac"
        metadata="${track%.wav}-metadata.txt"
      ;;
      *'.flac')
        track_out_name="${track}"
        metadata="${track%.flac}-metadata.txt"
        metaflac --remove-all -- "${track}"
      ;;
    esac
    printf '%s' "${track}"
    
    local track_temp=''
    track_temp="$(mktemp --dry-run "--suffix=.flac" "track_temp_XXXXXX")" || exit 1
    flac --silent --no-padding --warnings-as-errors --delete-input-file --verify \
         --compression-level-8 --exhaustive-model-search --qlp-coeff-precision-search \
         --output-name="${track_temp}" -- "${track}" || exit 1
    metaflac --dont-use-padding --remove-all -- "${track_temp}"
    
    if ! [ -e "${metadata}" ]; then
      if ! is_listed_track "${track}"; then
        printf ' (no metadata for pregap/lead-in/lead-out)'
      else
        printf ' \e[0;31m(warning: metadata not found for track)\e[0m'
      fi
      metaflac --dont-use-padding --add-seekpoint=1s --add-padding=1024 -- "${track_temp}" || exit 1
    else
      metaflac --dont-use-padding --add-seekpoint=1s --import-tags-from="${metadata}" --add-padding=1024 -- "${track_temp}" || exit 1
      rm -f -- "${metadata}"
    fi
    
    mv --no-clobber --no-target-directory "${track_temp}" "${track_out_name}"
    printf '\n'
  done
  
  rm -f -- "d${disc_number}.wav"
  printf '\n==== Disc %s complete!\n\n' "$disc_number"
}




process_rip() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [ disc number(s) ]...\n'
    printf -- '  Trims overreads, verifies split tracks, converts to flac, etc.\n'
    printf -- '  Run in rip folder after parsing mb data.\n'
    exit 0
  fi
  local disc=''
  for disc in "$@"; do
    printf -- '\n======== Trimming overreads: Disc %s\n\n' "$disc"
    trim_overreads "$disc"
  done
  printf -- '\n======================================\n'
  printf -- '==== Trimming overreads completed ====\n'
  printf -- '======================================\n\n'
  disc=''
  for disc in "$@"; do
    cleanup_split_tracks "$disc"
  done
  printf -- '\n==== Saving sha256sums of all files to sha256sums.txt\n\n'
  sha256r 'sha256sums.txt'
  printf -- '\n===========================\n'
  printf -- '======== All done! ========\n'
  printf -- '===========================\n\n'
}



rip_whipper() {
  exit 1
  whipper --eject success cd --device /dev/sr1 rip --offset 30 --force-overread --unknown \
          --track-template 'disc_%N_track_%t.%x' \
          --disc-template '%d_%B' \
          --release-id 0000000
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m whipper reported an error\n\n' 1>&2
    exit 1
  fi
}



read_toc() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf -- 'Arguments: [disc_audio_filename.wav] [output.toc]\n\n'
    exit 0
  fi
  cdrdao read-toc --source-device /dev/sr0 --datafile "${1}" "${2}"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m cdrdao reported an error\n\n' 1>&2
    exit 1
  fi
}


run_cd_paranoia() {
  cd-paranoia --verbose --output-wav --force-cdrom-device /dev/sr1 --abort-on-skip "$@"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m cd-paranoia reported an error\n\n' 1>&2
    exit 1
  fi
}


run_cyanrip() {
  cyanrip -d /dev/sr1 -s 30 -p 1=track -O -o flac \
          -D '{album}_{barcode}' \
          -F 'd{disc}-{track}' \
          -L 'log-cyanrip-d{disc}' \
          -T simple \
          "$@"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31m==== Error:\e[0m cyanrip reported an error\n\n' 1>&2
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
  
  sleep 5s
  mkdir_or_exit "${rip_dir}"
  read_toc "d${disc_num}.wav" "${rip_dir}/d${disc_num}.toc"
  printf '\n'
  
  sleep 5s
  run_cyanrip "$@"
  
  #sleep 5s
  #run_cd_paranoia --sample-offset '-11754' --force-overread \
  #                --log-summary "${rip_dir}/log-cd-paranoia-overread-lead_in-d${disc_num}.log" -- '-[40.00]' \
  #                              "${rip_dir}/d${disc_num}-00-overread-lead_in.wav"
  
  cd -- "${rip_dir}"
  
  printf '\n==== Saving raw audio sha256sums to raw_audio_sha256sums-d%s.txt\n' "$disc_num"
  #sha256audio -- "${rip_dir}/d${disc_num}-00-overread-lead_in.wav" > "${rip_dir}/d${disc_num}-raw_audio_sha256sums.txt"
  #sha256audio -- "${tracks[@]}" >> "${rip_dir}/d${disc_num}-raw_audio_sha256sums.txt"
  sha256audio -- "${tracks[@]}" > "${rip_dir}/d${disc_num}-raw_audio_sha256sums.txt"
  
  printf '\n==== Checking beginning and end of rip\n'
  local pregap_b0s=''
  local t1_b0s=''
  local last_track_e0s=''
  case "${tracks[0]}" in
    *0.flac)
      pregap_b0s="$(test_audio 'b0s' "${rip_dir}/${tracks[0]}")"
      t1_b0s="$(test_audio 'b0s' "${rip_dir}/${tracks[1]}")"
    ;;
    *)
      t1_b0s="$(test_audio 'b0s' "${rip_dir}/${tracks[0]}")"
    ;;
  esac
  local last_track_e0s="$(test_audio 'e0s' "${rip_dir}/${tracks[-1]}")"
  if [ -n "$pregap_b0s" ]; then
    printf -- 'pregap zero samples at beginning  : %s\n' "$pregap_b0s"
  fi
  printf -- 'track 1 zero samples at beginning : %s\n' "$t1_b0s"
  printf -- 'last track zero samples at end    : %s\n\n' "$last_track_e0s"
  
  if [ "$disc_num" -eq "$total_discs" ]; then
    printf -- '\n==== All done, saving sha256sums of all files\n\n'
    sha256r sha256sums.txt
  else
    printf -- '\n==== All done with disc %s, run again with next disc\n\n' "$disc_num"
  fi
  cd -- "${starting_dir}"
}



test_function() {
  verify_cdda_wav "$@"
}



if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  printf '  operation [ sha256audio | sha256audior | \n'
  printf '              print-samples | num-samples | contatenate | split-by-samples | \n'
  printf '              to-raw | raw-to-format | \n'
  printf '              all-0-samples | beginning-0-samples | end-0-samples | \n'
  printf '              trim-overreads | cleanup-split-tracks | \n'
  printf '              read-toc | run-cd-paranoia | \n'
  printf '              run-cyanrip | rip-cyanrip | \n'
  printf '              parse-mb-request | process_rip ]\n'
  printf '    (see (operation) --help for operation arguments)\n'
  exit 0
fi

declare operation="$1"
shift 1
case "$operation" in
  'print-samples' | 'print_samples')
    test_audio 'print-samples' "$@"
  ;;
  'num-samples' | 'num_samples')
    num_samples "$@"
  ;;
  'concatenate')
    concatenate "$@"
  ;;
  'split-by-samples' | 'split_by_samples' | 'split')
    split_by_samples "$@"
  ;;
  'to-raw' | 'to_raw')
    to_raw "$@"
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
  'all-0-samples' | 'all_0_samples' | 'a0s')
    test_audio 'a0s' "$@"
  ;;
  'beginning-0-samples' | 'beginning_0_samples' | 'b0s')
    test_audio 'b0s' "$@"
  ;;
  'end-0-samples' | 'end_0_samples' | 'e0s')
    test_audio 'e0s' "$@"
  ;;
  'trim-overreads' | 'trim_overreads')
    trim_overreads "$@"
  ;;
  'read-toc' | 'read_toc')
    read_toc "$@"
  ;;
  'run-cd-paranoia' | 'run_cd_paranoia')
    run_cd_paranoia "$@"
  ;;
  'run-cyanrip' | 'run_cyanrip')
    run_cyanrip "$@"
  ;;
  'rip-cyanrip' | 'rip_cyanrip')
    rip_cyanrip "$@"
  ;;
  'parse-mb-request' | 'parse_mb_request')
    parse_mb_request "$@"
  ;;
  'cleanup-split-tracks' | 'cleanup_split_tracks')
    cleanup_split_tracks "$@"
  ;;
  'process-rip' | 'process_rip')
    process_rip "$@"
  ;;
  'test' | 'test-function' | 'test_function')
    test_function "$@"
  ;;
  *)
    printf '\nError: Invalid operation\n'
    exit 1
  ;;
esac

