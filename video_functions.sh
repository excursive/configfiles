#!/bin/bash

video_reference() {
  printf "scaling: -filter:v 'scale=1280:720:flags=lanczos+bitexact:param0=3.0'\n"
  printf '                   param0: (float) width (alpha) of lanczos algorithm\n'
  printf '     (note ffmpeg does not convert to linear colorspace when scaling)\n'
}

ffmpeg_bitexact() {
  local out_file="${1}"
  shift 1
  ffmpeg "$@" \
         -map_metadata -1 -flags bitexact -flags:v bitexact -flags:a bitexact -fflags bitexact \
         "${out_file}"
}

ffmpeg_trim() {
  local out_file="${1}"
  local in_file="${2}"
  local start_time="$3"
  local end_time="$4"
  local seek_mode='-accurate_seek'
  if [ "$5" = '-noaccurate_seek' ]; then
    seek_mode='-noaccurate_seek'
  elif [ -n "$5" ] && [ "$5" != '-accurate_seek' ]; then
    printf 'Error: valid seek modes are: [ -accurate_seek (default) | -noaccurate_seek ]\n' 1>&2
    exit 1
  fi
  ffmpeg_bitexact "${out_file}" \
                  "${seek_mode}" -ss "$start_time" -to "$end_time" \
                  -i "${in_file}" \
                  -c copy -c:v copy -c:a copy \
                  -map 0:v:0 -map 0:a:0
}

average_color_channels() {
  local out_dir="${1}"
  if ! mkdir "${out_dir}"; then
    printf 'Error: Could not create output directory %s\n' "${out_dir}" 1>&2
    exit 1
  fi
  local base_frames_dir="${2}"
  local alt_frames_dir="${3}"
  local current_frame="$4"
  local end_frame="$5"
  while [ "$current_frame" -le "$end_frame" ]; do
    convert -respect-parenthesis \
            \( "${base_frames_dir}/${current_frame}.png" -depth 16 -colorspace LAB -write mpr:dest \
               -channel 0 -separate -write mpr:luma +delete \) \
            mpr:dest \
            \( "${alt_frames_dir}/${current_frame}.png" -background none -alpha Set \
               -channel A -evaluate Multiply 0.5 +channel -depth 16 -colorspace LAB \) \
            -depth 16 -colorspace LAB \
            -composite -channel 1,2 -separate \
            mpr:luma -insert 0 \
            -channel 0,1,2 -set colorspace LAB -combine \
            -colorspace sRGB -depth 8 -strip "${out_dir}/${current_frame}.png"
    current_frame="$(( $current_frame + 1 ))"
  done
}


if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'functions:\n'
  printf '  ref - examples of ffmpeg commands for reference\n'
  printf '  ffmpeg_bitexact - specify bitexact output when running ffmpeg\n'
  printf '  trim - trim video+audio streams without reencoding\n'
  printf '  avgcolors - average the color channels only of two folders of frames\n'
  exit 0
fi

function="$1"
shift 1

case "$function" in
  'ref' | 'reference' | 'hints')
    video_reference
  ;;
  'ffmpeg_bitexact')
    if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
      printf 'ffmpeg_bitexact arguments:\n'
      printf '  out_file\n'
      printf '  preceeding ffmpeg arguments\n'
      exit 0
    fi
    ffmpeg_bitexact "$@"
  ;;
  'trim')
    if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
      printf 'trim arguments:\n'
      printf '  out_file\n'
      printf '  in_file\n'
      printf '  start time\n'
      printf '  end time\n'
      printf '    format options: [-][HH:]MM:SS[.XX]\n'
      printf '                            [-]SS[.XX][s|ms|us]\n'
      printf '  seek_mode [ -accurate_seek (default) | -noaccurate_seek ]\n'
      exit 0
    fi
    ffmpeg_trim "$@"
  ;;
  'avgcolors')
    if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
      printf 'avgcolors arguments:\n'
      printf '  output dir to create\n'
      printf '  directory with base frames (named 1.png, 2.png, ...)\n'
      printf '  directory with frames to avg color channels with\n'
      printf '  start frame\n'
      printf '  end frame\n'
      exit 0
    fi
    average_color_channels "$@"
  ;;
  '')
    printf '\nError: No arguments supplied, see -h or --help\n'
    exit 1
  ;;
  *)
    printf '\nError: Invalid function name\n'
    exit 1
  ;;
esac

exit 0
