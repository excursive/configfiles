#!/bin/bash

is_positive_integer() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:digit:]]+$'
  [[ "$1" =~ $regex ]]
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
  local regex='[ -~]'
  [[ "$1" =~ $regex ]]
}



# edit a srgb image in the given colorspace using imagemagick
edit_in_colorspace() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  input image\n'
    printf '  output image\n'
    printf '  working colorspace: [ LAB | sRGB | (colorspace) ]\n'
    printf '    (LAB is almost always the best option)\n'
    printf '  ...arguments to pass to imagemagick after converting to the working\n'
    printf '     colorspace, and before converting back to srgb\n'
    exit 0
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



# generates a palette with as close as possible to but not more than the
# target max number of colors, and prints the final colors or levels used
# TODO: imagemagick doesn't have a good ordered-dither algorithm, so this
#       really shouldn't be used for that
reduce_colors() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  input image\n'
    printf '  output image (must be either a .png or .gif)\n'
    printf '  dither setting [ quantize ]\n'
    printf '  target max number of colors (1 <= n <= 256)\n'
    printf '  working colorspace: [ LAB | sRGB | (colorspace) ]\n'
    printf '    (LAB is almost always the best option)\n'
    printf '  ...arguments to pass to imagemagick after converting to the working\n'
    printf '     colorspace, and before color reduction\n'
    exit 0
  fi
  local input_file="${1}"
  local output_file="${2}"
  local output_format="${output_file##*.}"
  if [ "$output_format" != 'png' ] && [ "$output_format" != 'gif' ]; then
    printf 'Error: Invalid output format. Must be png or gif\n'
    exit 1
  fi
  local dither_setting='default'
  local working_colorspace="$5"
  local original_colors="$(identify -alpha Background -format '%k' "${input_file}")"
  # handle case where input image has less than specified max colors, otherwise
  # color quantization will never find more colors beyond what's in the image
  local max_colors="$(( "$original_colors" < "$4" ? \
                        "$original_colors" : "$4" ))"
  #printf 'number of colors in original image: %s\n' "$original_colors" >&2
  #printf 'target number of colors: %s\n' "$max_colors" >&2
  shift 5
  
  local low_guess=''
  low_guess="$max_colors"
  local guess="$low_guess"
  local high_guess=''
  local guess_result='0'
  while [ -z "$high_guess" ] || [ "$low_guess" -lt "$(( "$high_guess" - 1 ))" ]; do
    # important: for -quantize LAB we need to convert to 16 bit depth and LAB colorspace,
    # otherwise precision errors slightly shift the resulting palette, creating
    # very subtle dithering in solid blocks of color that look like random dead pixels
    local -a im_arguments=()
    im_arguments+=( "$@" '-colors' "$guess" )
    
    #printf 'trying %s: ' "$guess" >&2
    edit_in_colorspace "${input_file}" "${output_format}:${output_file}-test" \
                       "$working_colorspace" "${im_arguments[@]}"
            
    guess_result="$(identify -alpha Background -format '%k' \
                             "${output_format}:${output_file}-test")"
    #printf 'result is %s\n' "$guess_result" >&2
    
    if [ "$guess_result" -le "$max_colors" ]; then
      low_guess="$guess"
      rm -f -- "${output_file}"
      mv --no-target-directory "${output_file}-test" "${output_file}"
      #rm -f -- "${output_file}-test"
      if [ "$guess_result" -eq "$max_colors" ]; then
        break
      fi
    else
      high_guess="$guess"
      rm -f -- "${output_file}-test"
    fi
    if [ -z "$high_guess" ]; then
      guess="$(( "$low_guess" * 2 ))"
    else
      guess="$(( "$low_guess" + ( ( "$high_guess" - "$low_guess" ) / 2 ) ))"
    fi
  done
  # don't accidentally delete this printf lol
  #printf '%s' "$low_guess"
}



video_frames() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  input video\n'
    printf '  starting time\n'
    printf '  ending time\n'
    printf '    format: [-][HH:]MM:SS[.XX]\n'
    printf '                    [-]SS[.XX][s|ms|us]\n'
    printf '  name of directory to save frames to\n'
    exit 0
  fi
  local input="$1"
  local start="$2"
  local end="$3"
  local output_dir="$4"
  if [ -e "${output_dir}" ]; then
    printf 'Error: Output directory already exists\n'
    exit 1
  fi
  if ! mkdir "${output_dir}"; then
    printf 'Error: Could not create output directory\n'
    exit 1
  fi
  ffmpeg -i "${input}" -ss "$start" -to "$end" -map_metadata -1 \
         -flags bitexact -flags:v bitexact -flags:a bitexact -fflags bitexact \
         "${output_dir}/%01d.png"
}



process_frames() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  folder of frames\n'
    printf '  [ all | (range of frames, e.g. 23-52) | (single frame number) ]\n'
    printf '  output format: [ png | gif (for programs that only accept gifs as input) ]\n'
    printf '  working colorspace: [ LAB | sRGB | (colorspace) ]\n'
    printf '  ...arguments to pass to imagemagick after converting to the working\n'
    printf '     colorspace, and before color reduction\n'
    printf '    here are some good settings for increasing contrast and sharpening:\n'
    printf '    -channel 0 -sigmoidal-contrast 4.5,50%% +channel -unsharp 0x0.6+2.0\n'
    exit 0
  fi
  
  if [ ! -d "${1}" ]; then
    printf 'Error: Invalid frame directory\n'
    exit 1
  fi
  local frame_directory="${1}"
  
  local start_frame=''
  local end_frame=''
  if [ "$2" = 'all' ]; then
    start_frame='1'
    end_frame='999999'
  elif is_positive_integer "$2"; then
    start_frame="$2"
    end_frame="$2"
  elif is_positive_integer_range "$2"; then
    start_frame="${2%%-*}"
    end_frame="${2##*-}"
    if [ "$end_frame" -lt "$start_frame" ]; then
      printf 'Error: Ending frame number lower than starting frame number\n'
      exit 1
    fi
  else
    printf 'Error: Invalid frame numbers\n'
    exit 1
  fi
  
  local out_format=''
  if [ "$3" = 'png' ]; then
    out_format='png'
  elif [ "$3" = 'gif' ]; then
    out_format='gif'
  else
    printf 'Error: Invalid output format\n'
    exit 1
  fi
  
  local working_colorspace=''
  if ! is_alphanumeric "$4"; then
    printf 'Error: Invalid working colorspace\n'
    exit 1
  fi
  working_colorspace="$4"
  
  shift 4
  
  printf 'Processing frames: '
  local current_frame="$start_frame"
  while [ "$current_frame" -le "$end_frame" ] && \
        [ -e "${frame_directory}/${current_frame}.png" ]; do
    printf '%s ' "$current_frame"
    if [ "$out_format" = 'gif' ]; then
      edit_in_colorspace "${frame_directory}/${current_frame}.png" \
                         "${frame_directory}/${current_frame}-out.gif" \
                         "$working_colorspace" "$@" '-colors' '256'
    else
      edit_in_colorspace "${frame_directory}/${current_frame}.png" \
                         "${frame_directory}/${current_frame}-out.png" \
                         "$working_colorspace" "$@"
    fi
    current_frame="$(( "$current_frame" + 1 ))"
  done
  printf '\n\nAll done!\n'
}



create_gif_gifski() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  output file\n'
    printf '  folder of frames\n'
    printf '  [ all | (range of frames, e.g. 23-52) | (single frame number) ]\n'
    printf '  loopcount [ forever | once ]\n'
    printf '  max width   [ (maximum width)  | _ ]\n'
    printf '  max height  [ (maximum height) | _ ]\n'
    printf '    (an underscore on one dimension leaves it unconstrained)\n'
    printf '    (stretches if both width and height are set)\n'
    printf '  quality (integer 1-100)\n'
    printf '  fps\n'
    exit 0
  fi
  
  local output_file="${1}"
  if [ -e "${output_file}" ]; then
    printf 'Error: Output file already exists\n'
    exit 1
  fi
  
  if [ ! -d "${2}" ]; then
    printf 'Error: Invalid frame directory\n'
    exit 1
  fi
  local frame_directory="${2}"
  
  local start_frame=''
  local end_frame=''
  if [ "$3" = 'all' ]; then
    start_frame='1'
    end_frame='999999'
  elif is_positive_integer "$3"; then
    start_frame="$3"
    end_frame="$3"
  elif is_positive_integer_range "$3"; then
    start_frame="${3%%-*}"
    end_frame="${3##*-}"
    if [ "$end_frame" -lt "$start_frame" ]; then
      printf 'Error: Ending frame number lower than starting frame number\n'
      exit 1
    fi
  else
    printf 'Error: Invalid frame numbers\n'
    exit 1
  fi
  
  local -a args=()
  
  if [ "$4" = 'once' ]; then
    args+=( '--once' )
  elif [ "$4" != 'forever' ]; then
    printf 'Error: Invalid loopcount\n'
    exit 1
  fi
  
  if [ "$5" != '_' ]; then
    if is_positive_integer "$5"; then
      args+=( '--width' "$5" )
    else
      printf 'Error: Invalid maximum width\n'
      exit 1
    fi
  fi
  
  if [ "$6" != '_' ]; then
    if is_positive_integer "$6"; then
      args+=( '--height' "$6" )
    else
      printf 'Error: Invalid maximum height\n'
      exit 1
    fi
  fi
  
  if is_positive_integer "$7" && [ "$7" -ge 1 ] && [ "$7" -le 100 ]; then
    args+=( '--quality' "$7" )
  else
    printf 'Error: Quality must be an integer from 1 to 100\n'
    exit 1
  fi
  
  if is_positive_integer "$8" && [ "$8" -ge 1 ]; then
    args+=( '--fps' "$8" )
  else
    printf 'Error: FPS must be an integer greater than 0\n'
    exit 1
  fi
  
  shift 8
  
  local current_frame="$start_frame"
  while [ "$current_frame" -le "$end_frame" ] && \
        [ -e "${frame_directory}/${current_frame}-out.png" ]; do
    args+=( "${frame_directory}/${current_frame}-out.png" )
    current_frame="$(( "$current_frame" + 1 ))"
  done
  
  gifski "${args[@]}" --output "${output_file}"
}



create_gif_gifsicle() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  output file\n'
    printf '  folder of frames\n'
    printf '  [ all | (range of frames, e.g. 23-52) | (single frame number) ]\n'
    printf '  resize-method [ default (catrom) | (gifsicle resize-method) ]\n'
    printf '  color-method [ default (blend-diversity) | (gifsicle color-method) ]\n'
    printf '  loopcount [ forever | (positive integer) ]\n'
    printf '  dither method [ default (ordered) | (gifsicle dither method) ]\n'
    printf '  resize-colors [ default (256) | integer <= 256 ]\n'
    printf '    (when resizing images, add intermediate colors when image has fewer than\n'
    printf '     the given number of colors)\n'
    printf '  global color table [ no-gct | integer <= 256 ]\n'
    printf '    (reduces the total number of colors to the given number to eliminate\n'
    printf '     any local color tables, reducing filesize)\n'
    printf '  resize-fit  [ none | (maximum widthxheight) ]\n'
    printf '    (does not resize image if it already fits within dimensions)\n'
    printf '    (an underscore on one dimension leaves it unconstrained)\n'
    printf '  optimization level [ O1 (frame) | O2 (+transparency) | O3 (+try several) ]\n'
    printf '  lossy lzw compression [ no-lossy | lossy-default (20) | (positive integer) ]\n'
    printf '    (higher values = more artifacts and noise, but potentially smaller files)\n'
    printf '  delay [ (integer >= 0; duration of each frame in 1/100ths of a second) ]\n'
    printf '  operation [ (gifsicle mode option, listed below:) ]\n'
    printf '    merge: combine all gif inputs into one output\n'
    printf '    batch: modify each gif input in place, writing to the same filename\n'
    printf '    explode: create an output gif for each frame of input file\n'
    exit 0
  fi
  
  local output_file="${1}"
  if [ -e "${output_file}" ]; then
    printf 'Error: Output file already exists\n'
    exit 1
  fi
  
  if [ ! -d "${2}" ]; then
    printf 'Error: Invalid frame directory\n'
    exit 1
  fi
  local frame_directory="${2}"
  
  local start_frame=''
  local end_frame=''
  if [ "$3" = 'all' ]; then
    start_frame='1'
    end_frame='999999'
  elif is_positive_integer "$3"; then
    start_frame="$3"
    end_frame="$3"
  elif is_positive_integer_range "$3"; then
    start_frame="${3%%-*}"
    end_frame="${3##*-}"
    if [ "$end_frame" -lt "$start_frame" ]; then
      printf 'Error: Ending frame number lower than starting frame number\n'
      exit 1
    fi
  else
    printf 'Error: Invalid frame numbers\n'
    exit 1
  fi
  
  local -a args=( '--no-app-extensions' '--no-names' '--no-comments' '--no-extensions' )
  
  args+=( '--resize-method' )
  if [ "$4" = 'default' ]; then
    args+=( 'catrom' )
  elif is_printable_ascii "$4"; then
    args+=( "$4" )
  else
    printf 'Error: Invalid resize method\n'
    exit 1
  fi
  
  args+=( '--color-method' )
  if [ "$5" = 'default' ]; then
    args+=( 'blend-diversity' )
  elif is_printable_ascii "$5"; then
    args+=( "$5" )
  else
    printf 'Error: Invalid color method\n'
    exit 1
  fi
  
  if [ "$6" = 'forever' ]; then
    args+=( '--loopcount=forever' )
  elif is_positive_integer "$6"; then
    args+=( "--loopcount=${6}" )
  else
    printf 'Error: Invalid loopcount\n'
    exit 1
  fi
  
  if [ "$7" = 'default' ]; then
    args+=( '--dither=ordered' )
  elif is_printable_ascii "$7"; then
    args+=( "--dither=${7}" )
  else
    printf 'Error: Invalid dither method\n'
    exit 1
  fi
  
  args+=( '--resize-colors' )
  if [ "$8" = 'default' ]; then
    args+=( '256' )
  elif is_positive_integer "$8" && [ "$8" -le 256 ]; then
    args+=( "$8" )
  else
    printf 'Error: Invalid resize-colors value\n'
    exit 1
  fi
  
  if [ "$9" = 'no-gct' ]; then
    args+=()
  elif is_positive_integer "$9" && [ "$9" -ge 2 ] && [ "$9" -le 256 ]; then
    args+=( '--colors' "$9" )
  else
    printf 'Error: Invalid number of colors for global color table\n'
    exit 1
  fi
  
  if [ "${10}" = 'none' ]; then
    args+=()
  elif is_printable_ascii "${10}"; then
    args+=( '--resize-fit' "${10}" )
  else
    printf 'Error: Invalid maximum dimensions\n'
    exit 1
  fi
  
  if [ "${11}" = 'O1' ]; then
    args+=( '-O1' )
  elif [ "${11}" = 'O2' ]; then
    args+=( '-O2' )
  elif [ "${11}" = 'O3' ]; then
    args+=( '-O3' )
  else
    printf 'Error: Invalid optimization level\n'
    exit 1
  fi
  
  if [ "${12}" = 'no-lossy' ]; then
    args+=()
  elif [ "${12}" = 'lossy-default' ]; then
    args+=( '--lossy' )
  elif is_positive_integer "${12}"; then
    args+=( "--lossy=${12}" )
  else
    printf 'Error: Invalid lossiness\n'
    exit 1
  fi
  
  args+=( '--delay' )
  if is_positive_integer "${13}"; then
    args+=( "${13}" )
  else
    printf 'Error: Invalid frame duration\n'
    exit 1
  fi
  
  local operation="${14}"
  shift 14
  args+=( "$@" )
  if [ "$operation" = 'merge' ]; then
    args+=( '--merge' )
  elif [ "$operation" = 'batch' ]; then
    args+=( '--batch' )
  elif [ "$operation" = 'explode' ]; then
    args+=( '--explode' )
  else
    printf 'Error: Invalid operation\n'
    exit 1
  fi
  
  local current_frame="$start_frame"
  while [ "$current_frame" -le "$end_frame" ] && \
        [ -e "${frame_directory}/${current_frame}-out.gif" ]; do
    args+=( "${frame_directory}/${current_frame}-out.gif" )
    current_frame="$(( "$current_frame" + 1 ))"
  done
  
  gifsicle "${args[@]}" > "${output_file}"
}



if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  printf '  operation [ video-frames | process-frames | create-gif ]\n'
  printf '    (see operation --help for operation arguments)\n'
  exit 0
fi

declare operation="$1"
shift 1
case "$operation" in
  'video-frames')
    video_frames "$@"
  ;;
  'process-frames')
    process_frames "$@"
  ;;
  'create-gif-gifski')
    create_gif_gifski "$@"
  ;;
  'create-gif-gifsicle')
    create_gif_gifsicle "$@"
  ;;
  *)
    printf '\nError: Invalid operation\n'
    exit 1
  ;;
esac

exit 0
