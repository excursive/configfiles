alias srm="rm -I"

alias md5c="md5sum -c --quiet"
alias sha256c="sha256sum -c --quiet"

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
    output="$(md5r)"
    if [ -e "$1" ]; then
      printf '%s\n' 'Error: Output file already exists'
      exit 1
    fi
    printf '%s' "$output" > "$1"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty md5sum
  fi
}

sha256r() {
  if [ -n "$1" ]; then
    output="$(sha256r)"
    if [ -e "$1" ]; then
      printf '%s\n' 'Error: Output file already exists'
      exit 1
    fi
    printf '%s' "$output" > "$1"
  else
    find . -type f -print0 | sort -z | xargs -0 --no-run-if-empty sha256sum
  fi
}

# TODO: functions below have been edited but need testing

function cmpimg() {
  compare -metric AE "$1" "$2" "${3:-/dev/null}"
  printf '\n'
}

function stripmp3() {
  ffmpeg -i "$1" -id3v2_version 3 -c copy -map 0:a:0 "$2"
}

function sha256audio() {
  ffmpeg -loglevel error -i "$1" -map 0:a -f hash -
}

function sha256video() {
  ffmpeg -loglevel error -i "$1" -map 0:v -f hash -
}

function tumblrbackuptag() {
  wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post,/tagged/$2/page" "https://$1.tumblr.com/tagged/$2"
}

function tumblrbackuppost() {
  wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post/$2" "https://$1.tumblr.com/post/$2"
}

function stripvideo() {
  for in_file in "$@"
  do
    printf '\n%s\n' "** Processing: $in_file"
    in_size="$(stat -c %s "$in_file")"
    printf '%s\n\n' "Input file size = ${in_size} bytes"
    
    temp="$(mkstemp "$in_file.XXXXXX.mp4")"
    ffmpeg -y -i "$in_file" -map_metadata -1 -c copy -map 0:v:0 -map 0:a:0 "$temp"
    
    ret="$?"
    printf '\n'
    if [ "$ret" -ne 0 ]; then
      rm "$temp"
      printf '\n%s\n\n' "Error. Skipping ${in_file}"
      continue
    fi
    
    rm "$in_file"
    mv "$temp" "$in_file"
    out_size="$(stat -c %s "$in_file")"
    
    size_diff="$(($in_size - $out_size))"
    percent_diff="$(printf '%s' "100 * $size_diff / $in_size" | bc -l)"
    printf '\n%s\n\n' "Output file size = ${out_size} bytes (${size_diff} bytes = ${percent_diff}% decrease)"
  done
}

function jpgoptim() {
  for in_file in "$@"
  do
    printf '\n%s\n' "** Processing: $in_file"
    in_size="$(stat -c %s "$in_file")"
    printf '%s\n\n' "Input file size = $in_size bytes"
    
    temp="$(mkstemp "$in_file.XXXXXX")"
    ${HOME}/binaries/mozjpeg/jpegtran -copy none -optimize -perfect "$in_file" > "$temp"
    
    ret="$?"
    printf '\n'
    if [ "$ret" -ne 0 ]; then
      rm "$temp"
      printf '\n%s\n\n' "Error. Skipping ${in_file}"
      continue
    fi
    
    rm "$in_file"
    mv "$temp" "$in_file"
    out_size="$(stat -c %s "$in_file")"
    
    size_diff="$(($in_size - $out_size))"
    percent_diff="$(printf '%s' "100 * $size_diff / $in_size" | bc -l)"
    printf '\n%s\n\n' "Output file size = ${out_size} bytes (${size_diff} bytes = ${percent_diff}% decrease)"
  done
}

function kppextract() {
  line="$(identify -verbose "$1" | grep "preset:")"
  l1="${line#*preset: }"
  printf '%s\n' "$l1"
}

function kpptotxt() {
  preset="$(kppextract "$1")"
  formatted="${preset//> <param />$'\n'<param }"
  printf '%s\n' "$formatted" > "$1.txt"
}

function kppdiff() {
  preset1="$(kppextract "$1" | xmllint --c14n - | xmllint --format -)"
  preset2="$(kppextract "$2" | xmllint --c14n - | xmllint --format -)"
  diff <(printf '%s' "$preset1") <(printf '%s' "$preset2")
}

function kppwrite() {
  text="$(<"$2")"
  unformatted="${text//>$'\n'<param /> <param }"
  convert "$1" -set 'preset' "$unformatted" out.png
}

if [ -f ~/.bash_aliases_extra ]; then
  . ~/.bash_aliases_extra
fi
