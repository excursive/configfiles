PATH="${PATH}:${HOME}/bin"

alias srm="rm -I"

alias md5c="md5sum -c --quiet"
alias sha256c="sha256sum -c --quiet"

alias pngoptim="optipng -strip all -o7"

alias mozjpegoptim="mozjpegtran -copy none -optimize -perfect"

alias aadebug="apparmor_parser -Q --debug"

alias ytdl="youtube-dl --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --no-post-overwrites"

alias ytdl-video-backup="youtube-dl --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --format 'bestvideo[ext=mp4],bestvideo[ext=webm]' --postprocessor-args '-c copy -c:v copy -c:a copy' --no-post-overwrites --fixup never"

alias ytdl-music-backup="youtube-dl --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --format 'bestaudio[ext=m4a],bestaudio[acodec=opus]' --postprocessor-args '-c copy -c:v copy -c:a copy' --no-post-overwrites --fixup never"

alias ytdl-backup="youtube-dl --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --format 'bestvideo[ext=mp4],bestaudio[ext=m4a],bestvideo[ext=webm],bestaudio[acodec=opus]' --postprocessor-args '-c copy -c:v copy -c:a copy' --no-post-overwrites --fixup never"

alias ytdl-strip="youtube-dl --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --postprocessor-args '-map_metadata -1 -c copy -c:v copy -c:a copy -flags bitexact -flags:v bitexact -flags:a bitexact -fflags bitexact' --no-post-overwrites"

alias screenrec720panim="ffmpeg -f x11grab -framerate 30 -video_size 1280x720 -draw_mouse 0 -show_region 0 -i :0.0+640,254 -f pulse -channels 2 -ac 2 -thread_queue_size 512 -i alsa_output.pci-0000_00_1f.3.analog-stereo.monitor -c:v libx264 -threads 2 -pix_fmt yuv420p -preset veryfast -crf 17 -tune animation -c:a flac -map 0:v:0 -map 1:a:0 -flags bitexact recording.mkv"

alias enc24fpsanim="ffmpeg -i recording.mkv -ss -to -vf "decimate=cycle=5,setpts=N/24/TB" -c:v libx264 -threads 1 -crf 23 -preset veryfast -tune animation -c:a aac -map_metadata -1 -map 0:v:0 -map 0:a:0 -strict -2 -flags bitexact encoded.mp4"

#alias protonrun="STEAM_COMPAT_DATA_PATH=~/PREFIX_LOCATION/ ~/.steam/ubuntu12_32/steam-runtime/run.sh ~/.steam/steam/steamapps/common/Proton\ 3.7/proton run ~/PROGRAM_LOCATION"

#wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post,/tagged/tag+name/page" 'https://staff.tumblr.com/tagged/tag+name'

is_positive_integer() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:digit:]]+$'
  [[ "$1" =~ $regex ]]
}

is_positive_integer_range() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[[:digit:]]+\-[[:digit:]]+$'
  [[ "$1" =~ $regex ]]
}

is_decimal() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[+\-]?(([[:digit:]]+[.[[:digit:]]*]?)|(.[[:digit:]]+))$'
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
  local regex='[^ -~]'
  ! [[ "$1" =~ $regex ]]
}

md5r() {
  if [ -n "${1}" ]; then
    local output="$(md5r)"
    if [ -e "${1}" ]; then
      printf 'Error: Output file already exists\n'
      return 1
    fi
    printf '%s' "$output" > "${1}"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty md5sum
  fi
}

sha256r() {
  if [ -n "${1}" ]; then
    local output="$(sha256r)"
    if [ -e "${1}" ]; then
      printf 'Error: Output file already exists\n'
      return 1
    fi
    printf '%s' "$output" > "${1}"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty sha256sum
  fi
}

grep-non-ascii() {
  local LC_ALL=C
  export LC_ALL
  
  local print_line_numbers=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Arguments:\n'
        printf '  [ -h | --help ]\n'
        printf '  [ -n | --line-numbers ] print line numbers in a space separated list\n'
        return 0
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
  
  for in_file in "$@"; do
    local total_lines="$(grep --color='auto' -c --perl-regexp '[^\x0A\x20-\x7E]' -- "${in_file}")"
    
    if [ "$total_lines" -gt 0 ]; then
      printf '\e[0;31m%s: %s\e[0m\n' "${in_file}" "$total_lines"
      
      if [ "$print_line_numbers" = '-n' ]; then
        printf '\e[0;36m%s\e[0m\n' \
          "$(grep --color='auto' -n --perl-regexp '[^\x0A\x20-\x7E]' -- "${in_file}" | \
               cut --fields=1 --delimiter=':' | tr '\n' ' ')"
      fi
    else
      printf '%s: %s\n' "${in_file}" "$total_lines"
    fi
  done
}

# TODO: functions below have been edited but need testing

cmpimg() {
  local out_file=''
  if [ -z "${3}" ]; then
    out_file='null:'
  elif [ -e "${3}" ]; then
    printf 'Error: Output file already exists\n'
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
    printf 'Error: Output file already exists\n'
    return 1
  else
    out_file="${3}"
  fi
  
  convert \( -alpha Set "${1}" -coalesce -append \) \
          \( -alpha Set "${2}" -coalesce -append \) +depth miff:- | \
  compare -metric AE - "${out_file}"
  
  printf '\n'
}

sha256audio() {
  ffmpeg -loglevel error -i "$1" -map 0:a -f hash -
}

sha256video() {
  ffmpeg -loglevel error -i "$1" -map 0:v -f hash -
}

ffmpeg_bitexact() {
  local in_file="${1}"
  local out_file="${2}"
  shift 2
  ffmpeg -i "${in_file}" \
         "$@" \
         -map_metadata -1 -flags bitexact -flags:v bitexact -flags:a bitexact -fflags bitexact \
         "${out_file}"
}

tumblrbackuptag() {
  wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:83.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post,/tagged/$2/page" "https://$1.tumblr.com/tagged/$2"
}

tumblrbackuppost() {
  wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:83.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post/$2" "https://$1.tumblr.com/post/$2"
}

# arguments:
# 1 = [ jpeg | audio | video | video-subtitled ]
# 2... = files to process
batch_optimize_files() {
  local filetype="$1"
  shift 1
  for in_file in "$@"; do
    printf '\n** Processing: %s\n' "$in_file"
    local in_size="$(stat -c '%s' "$in_file")"
    printf 'Input file size = %s bytes\n\n' "$in_size"
    
    # TODO: handle case where extension is missing or doesn't match container format
    local base_name="$(basename ${in_file})"
    local extension="${base_name##*.}"
    local suffix=''
    if [ -n "${extension}" ]; then
      suffix=".${extension}"
    fi
    local temp_file="$(mktemp "--suffix=${suffix}" "${in_file}.XXXXXX")"
    
    case "$filetype" in
      'jpg' | 'jpeg')
        mozjpegtran -copy none -optimize -perfect "${in_file}" > "${temp_file}"
      ;;
      'video-subtitled')
        ffmpeg_bitexact "${in_file}" "${temp_file}" -loglevel warning \
                        -y -c copy -c:v copy -c:a copy -c:s copy \
                        -map 0:v:0 -map 0:a:0 -map 0:s:0
      ;;
      'video')
        ffmpeg_bitexact "${in_file}" "${temp_file}" -loglevel warning \
                        -y -c copy -c:v copy -c:a copy \
                        -map 0:v:0 -map 0:a:0
      ;;
      'audio')
        ffmpeg_bitexact "${in_file}" "${temp_file}" -loglevel warning \
                        -y -c copy -c:a copy \
                        -map 0:a:0
      ;;
      *)
        printf 'Error: Invalid filetype. Valid filetypes are:\n'
        printf '       [ jpeg | audio | video | video-subtitled ]\n'
        return 1
      ;;
    esac
    
    local ret="$?"
    printf '\n'
    if [ "$ret" -ne 0 ]; then
      rm -f -- "${temp_file}"
      printf 'Error, Skipping %s\n\n' "${in_file}"
      continue
    fi
    
    rm "${in_file}"
    mv "${temp_file}" "${in_file}"
    local out_size="$(stat -c '%s' "${in_file}")"
    
    local size_diff="$(($in_size - $out_size))"
    local percent_diff="$(printf '100 * %s / %s\n' "$size_diff" "$in_size" | bc -l)"
    printf 'Output file size = %d bytes (%d bytes = %.2f%% decrease)\n\n' \
           "$out_size" "$size_diff" "$percent_diff"
  done
}

jpgoptim() {
  batch_optimize_files 'jpeg' "$@"
}

stripvideo() {
  batch_optimize_files 'video' "$@"
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

mouse-sensitivity-gnome() {
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
        printf 'Error: Invalid speed\n'
        return 1
      fi
      if ! [ "$2" = 'default' ] && ! [ "$2" = 'flat' ] && ! [ "$2" = 'adaptive' ]; then
        printf 'Error: Invalid accel-profile\n'
        return 1
      fi
      gsettings set org.gnome.desktop.peripherals.mouse speed "$1"
      gsettings set org.gnome.desktop.peripherals.mouse accel-profile "$2"
    ;;
  esac
}

kppextract() {
  local line="$(identify -verbose "$1" | grep 'preset:')"
  local l1="${line#*preset: }"
  printf '%s\n' "$l1"
}

kpptotxt() {
  if [ -e "${1}.txt" ]; then
    printf 'Error: Output file %s already exists\n' "${1}.txt"
    return 1
  fi
  local preset="$(kppextract "${1}")"
  local formatted="${preset//> <param />$'\n'<param }"
  printf '%s\n' "$formatted" > "${1}.txt"
}

kppdiff() {
  local preset1="$(kppextract "${1}" | xmllint --c14n - | xmllint --format -)"
  local preset2="$(kppextract "${2}" | xmllint --c14n - | xmllint --format -)"
  diff <(printf '%s' "$preset1") <(printf '%s' "$preset2")
}

kppwrite() {
  if [ -e "${2}" ]; then
    printf 'Error: Output file %s already exists\n' "${2}"
    return 1
  fi
  local text="$(<"${3}")"
  local unformatted="${text//>$'\n'<param /> <param }"
  convert "${1}" -set 'preset' "$unformatted" "${2}"
}

if [ -f ~/.bash_aliases_extra ]; then
  . ~/.bash_aliases_extra
fi
