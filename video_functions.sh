#!/bin/bash

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
  printf 'avgcolors arguments:\n'
  printf '  output dir to create\n'
  printf '  directory with base frames (named 1.png, 2.png, ...)\n'
  printf '  directory with frames to avg color channels with\n'
  printf '  start frame\n'
  printf '  end frame\n'
  exit 0
fi

case "$1" in
  'avgcolors')
    average_color_channels "$2" "$3" "$4" "$5" "$6"
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
