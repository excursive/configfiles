#!/bin/bash

gif_reference() {
  printf 'gifski lossy is great, can increase number of colors\n'
  printf 'o4 is best ordered dither method\n'
  printf 'square halftone size 3-6 pixels is also good\n'
  printf 'halftone number of colors is 2+, no difference between 1 and 2,\n'
  printf '  very little difference beyond 4\n'
  printf '64 colors, squarehalftone,8,2 is cool\n'
  printf 'median-cut is always worth testing\n'
}

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

is_alphanumeric() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:alnum:]]+$'
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
  local max_colors="$(( $original_colors < $4 ? \
                        $original_colors : $4 ))"
  #printf 'number of colors in original image: %s\n' "$original_colors" >&2
  #printf 'target number of colors: %s\n' "$max_colors" >&2
  shift 5
  
  local low_guess=''
  low_guess="$max_colors"
  local guess="$low_guess"
  local high_guess=''
  local guess_result='0'
  while [ -z "$high_guess" ] || [ "$low_guess" -lt "$(( $high_guess - 1 ))" ]; do
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
      guess="$(( $low_guess * 2 ))"
    else
      guess="$(( $low_guess + ( ( $high_guess - $low_guess ) / 2 ) ))"
    fi
  done
  # don't accidentally delete this printf lol
  #printf '%s' "$low_guess"
}




process_frames() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments:\n'
    printf '  folder of frames named 1.png, 2.png, ...\n'
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
    end_frame='9999'
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
  while [ "$current_frame" -le "$end_frame" ]; do
    if [ -e "${frame_directory}/${current_frame}.png" ]; then
      printf '%s ' "$current_frame"
      if [ "$out_format" = 'gif' ]; then
        if [ -e "${frame_directory}/${current_frame}-out.gif" ]; then
          printf '\e[0;31mError:\e[0m File with frame output filename already exists\n\n' 1>&2
          exit 1
        fi
        edit_in_colorspace "${frame_directory}/${current_frame}.png" \
                           "${frame_directory}/${current_frame}-out.gif" \
                           "$working_colorspace" "$@" '-colors' '256'
      else
        if [ -e "${frame_directory}/${current_frame}-out.png" ]; then
          printf '\e[0;31mError:\e[0m File with frame output filename already exists\n\n' 1>&2
          exit 1
        fi
        edit_in_colorspace "${frame_directory}/${current_frame}.png" \
                           "${frame_directory}/${current_frame}-out.png" \
                           "$working_colorspace" "$@"
      fi
    fi
    current_frame="$(( $current_frame + 1 ))"
  done
  printf '\n\nAll done!\n'
}




process_gif() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'process-gif: Merges the input gif(s) into an optimized gif with gifsicle\n'
    printf 'Arguments: --color-method X [OPTIONS]... -- <OUTPUT.gif> <INPUT.gif>...\n'
    printf 'Options:\n'
    printf '  --resize-method [ default (catrom) | ... ]\n'
    printf '  --color-method [ median-cut | blend-diversity | ... ]\n'
    printf '  --dither [ default (ordered) | o4 | squarehalftone,4,4 | ... ]\n'
    printf '  --resize-colors [ default (256) | integer <= 256 ]\n'
    printf '    (when resizing images, add intermediate colors when image has fewer than\n'
    printf '     the given number of colors)\n'
    printf '  --colors global color table [ no-gct | integer <= 256 ]\n'
    printf '    (reduces the total number of colors to the given number to eliminate\n'
    printf '     any local color tables, reducing filesize)\n'
    printf '  --resize-fit  [ none | (maximum widthxheight) ]\n'
    printf '    (does not resize image if it already fits within dimensions)\n'
    printf '    (an underscore on one dimension leaves it unconstrained)\n'
    printf '  --lossy [ (positive integer) ]\n'
    printf '    (higher values = more artifacts and noise, but potentially smaller files)\n'
    printf '  --delay [ (positive integer; duration of each frame in 1/100ths of a second) ]\n'
    exit 0
  fi
  
  local resize_method='catrom'
  local color_method=''
  local dither='ordered'
  local resize_colors='256'
  
  local -a args=( '--no-app-extensions' '--no-names' '--no-comments' '--no-extensions' )
  args+=( '-O2' )
  
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '--resize-method')
        resize_method="$2"
      ;;
      '--color-method')
        color_method="$2"
      ;;
      '--dither')
        dither="$2"
      ;;
      '--resize-colors')
        resize_colors="$2"
      ;;
      '--colors')
        args+=( '--colors' "$2" )
      ;;
      '--resize-fit')
        args+=( '--resize-fit' "$2" )
      ;;
      '--lossy')
        args+=( "--lossy=${2}" )
      ;;
      '--delay')
        args+=( '--delay' "$2" )
      ;;
      '--')
        shift 1
        break
      ;;
      *)
        printf '\e[0;31mError:\e[0m Invalid option or did not denote end of options with --\n\n' 1>&2
        exit 1
      ;;
    esac
    shift 2
  done
  
  if [ -z "$color_method" ]; then
    printf '\e[0;31mError:\e[0m Must specify a --color-method\n\n' 1>&2
    exit 1
  fi
  
  args+=( '--resize-method' "$resize_method" )
  args+=( '--color-method' "$color_method" )
  args+=( "--dither=${dither}" )
  args+=( '--resize-colors' "$resize_colors" )
  args+=( '--merge' )
  
  local output_file="${1}"
  shift 1
  if [ -e "${output_file}" ]; then
    printf '\e[0;31mError:\e[0m Output file already exists\n\n' 1>&2
    exit 1
  fi
  
  gifsicle "${args[@]}" "$@" > "${output_file}"
}



if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  printf '  operation [ ref | frames | gif ]\n'
  printf '    (see (operation) --help for operation arguments)\n'
  exit 0
fi

declare operation="$1"
shift 1
case "$operation" in
  'ref' | 'reference' | 'hints')
    gif_reference
  ;;
  'frames')
    process_frames "$@"
  ;;
  'gif')
    process_gif "$@"
  ;;
  *)
    printf '\nError: Invalid operation\n'
    exit 1
  ;;
esac

printf '\n'
exit 0
