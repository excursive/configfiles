alias srm="rm -I"

alias md5c="md5sum -c --quiet"
alias sha256c="sha256sum -c --quiet"

alias grep-non-ascii="grep --colors='auto' -n --perl-regexp '[^\x00-\x7F]'"

alias pngoptim="optipng -strip all -o7"

alias mozjpegoptim="${HOME}/binaries/mozjpeg/jpegtran -copy none -optimize -perfect"

alias aadebug="apparmor_parser -Q --debug"

alias ytdl="python3 ${HOME}/binaries/youtube-dl/youtube_dl/__main__.py --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --no-post-overwrites"

alias ytdl-video-backup="python3 ${HOME}/binaries/youtube-dl/youtube_dl/__main__.py --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --format 'bestvideo[ext=mp4],bestvideo[ext=webm]' --postprocessor-args '-c copy -c:v copy -c:a copy' --no-post-overwrites --fixup never"

alias ytdl-music-backup="python3 ${HOME}/binaries/youtube-dl/youtube_dl/__main__.py --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --format 'bestaudio[ext=m4a],bestaudio[acodec=opus]' --postprocessor-args '-c copy -c:v copy -c:a copy' --no-post-overwrites --fixup never"

alias ytdl-backup="python3 ${HOME}/binaries/youtube-dl/youtube_dl/__main__.py --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --format 'bestvideo[ext=mp4],bestaudio[ext=m4a],bestvideo[ext=webm],bestaudio[acodec=opus]' --postprocessor-args '-c copy -c:v copy -c:a copy' --no-post-overwrites --fixup never"

alias ytdl-strip="python3 ${HOME}/binaries/youtube-dl/youtube_dl/__main__.py --output '%(uploader)s-%(title)s-%(id)s-%(format_id)s.%(ext)s' --no-overwrites --no-continue --no-mtime --no-call-home --postprocessor-args '-map_metadata -1 -c copy -c:v copy -c:a copy -flags bitexact -flags:v bitexact -flags:a bitexact -fflags bitexact' --no-post-overwrites"

alias screenrec720panim="ffmpeg -f x11grab -framerate 30 -video_size 1280x720 -draw_mouse 0 -show_region 0 -i :0.0+640,254 -f pulse -channels 2 -ac 2 -thread_queue_size 512 -i alsa_output.pci-0000_00_1f.3.analog-stereo.monitor -c:v libx264 -threads 2 -pix_fmt yuv420p -preset veryfast -crf 17 -tune animation -c:a flac -map 0:v:0 -map 1:a:0 -flags bitexact recording.mkv"

alias enc24fpsanim="ffmpeg -i recording.mkv -ss -to -vf "decimate=cycle=5,setpts=N/24/TB" -c:v libx264 -threads 1 -crf 23 -preset veryfast -tune animation -c:a aac -map_metadata -1 -map 0:v:0 -map 0:a:0 -strict -2 -flags bitexact encoded.mp4"

#alias protonrun="STEAM_COMPAT_DATA_PATH=~/PREFIX_LOCATION/ ~/.steam/ubuntu12_32/steam-runtime/run.sh ~/.steam/steam/steamapps/common/Proton\ 3.7/proton run ~/PROGRAM_LOCATION"

#wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post,/tagged/tag+name/page" 'https://staff.tumblr.com/tagged/tag+name'

md5r() {
  if [ -n "$1" ]; then
    local output="$(md5r)"
    if [ -e "$1" ]; then
      printf 'Error: Output file already exists\n'
      exit 1
    fi
    printf '%s' "$output" > "$1"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty md5sum
  fi
}

sha256r() {
  if [ -n "$1" ]; then
    local output="$(sha256r)"
    if [ -e "$1" ]; then
      printf 'Error: Output file already exists\n'
      exit 1
    fi
    printf '%s' "$output" > "$1"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty sha256sum
  fi
}

# TODO: functions below have been edited but need testing

cmpimg() {
  local output_file=''
  if [ -z "${3}" ]; then
    output_file='null:'
  elif [ -e "${3}" ]; then
    printf 'Error: Output file already exists\n'
    return 1
  else
    output_file="${3}"
  fi
  
  compare -metric AE "${1}" "${2}" "${output_file}"
  
  printf '\n'
}

cmpgif() {
  local output_file=''
  if [ -z "${3}" ]; then
    output_file='null:'
  elif [ -e "${3}" ]; then
    printf 'Error: Output file already exists\n'
    return 1
  else
    output_file="${3}"
  fi
  
  convert \( "${1}" -coalesce -append \) \
          \( "${2}" -coalesce -append \) +depth miff:- | \
  compare -metric AE - "${output_file}"
  
  printf '\n'
}

stripmp3() {
  ffmpeg -i "$1" -id3v2_version 3 -c copy -map 0:a:0 "$2"
}

sha256audio() {
  ffmpeg -loglevel error -i "$1" -map 0:a -f hash -
}

sha256video() {
  ffmpeg -loglevel error -i "$1" -map 0:v -f hash -
}

tumblrbackuptag() {
  wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post,/tagged/$2/page" "https://$1.tumblr.com/tagged/$2"
}

tumblrbackuppost() {
  wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post/$2" "https://$1.tumblr.com/post/$2"
}

# arguments:
# 1 = [ jpeg | video | audio ]
# 2... = files to process
batch_optimize_files() {
  local filetype="$1"
  shift
  for in_file in "$@"; do
    printf '\n** Processing: %s\n' "$in_file"
    local in_size="$(stat -c %s "$in_file")"
    printf 'Input file size = %s bytes\n\n' "$in_size"
    
    case "$filetype" in
      'jpg' | 'jpeg')
        local temp="$(mktemp "$in_file.XXXXXX")"
        ${HOME}/binaries/mozjpeg/jpegtran -copy none -optimize -perfect "$in_file" > "$temp"
      ;;
      'video')
        # TODO: use actual file extension instead of assuming mp4
        local temp="$(mktemp "$in_file.XXXXXX.mp4")"
        ffmpeg -y -i "$in_file" -map_metadata -1 -c copy -c:v copy -c:a copy \
               -flags bitexact -flags:v bitexact -flags:a bitexact -fflags bitexact \
               -map 0:v:0 -map 0:a:0 "$temp"
      ;;
      'audio')
        printf 'Error: Not implemented\n'
        exit 1
      ;;
      *)
        printf 'Error: Must specify [ jpeg | video | audio ] as first argument\n'
        exit 1
      ;;
    esac
    
    local ret="$?"
    printf '\n'
    if [ "$ret" -ne 0 ]; then
      rm -f -- "$temp"
      printf 'Error, Skipping %s\n\n' "$in_file"
      continue
    fi
    
    rm "$in_file"
    mv "$temp" "$in_file"
    local out_size="$(stat -c %s "$in_file")"
    
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

kppextract() {
  local line="$(identify -verbose "$1" | grep "preset:")"
  local l1="${line#*preset: }"
  printf '%s\n' "$l1"
}

kpptotxt() {
  local preset="$(kppextract "$1")"
  local formatted="${preset//> <param />$'\n'<param }"
  printf '%s\n' "$formatted" > "$1.txt"
}

kppdiff() {
  local preset1="$(kppextract "$1" | xmllint --c14n - | xmllint --format -)"
  local preset2="$(kppextract "$2" | xmllint --c14n - | xmllint --format -)"
  diff <(printf '%s' "$preset1") <(printf '%s' "$preset2")
}

kppwrite() {
  local text="$(<"$2")"
  local unformatted="${text//>$'\n'<param /> <param }"
  convert "$1" -set 'preset' "$unformatted" out.png
}

if [ -f ~/.bash_aliases_extra ]; then
  . ~/.bash_aliases_extra
fi
