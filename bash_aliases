alias srm="rm -I"

alias md5r="find . -type f -exec md5sum {} +"
alias sha256r="find . -type f -exec sha256sum {} +"

alias md5c="md5sum -c --quiet"
alias sha256c="sha256sum -c --quiet"

alias pngoptim="optipng -strip all -o7"

alias mozjpegoptim="$HOME/binaries/mozjpeg/inst/bin/jpegtran -copy none -optimize -perfect"

alias aadebug="apparmor_parser -Q --debug"

#alias ytdl="python ~/INSTALL_LOCATION/youtube-dl/youtube_dl/__main__.py --output '%(uploader)s_%(title)s_%(id)s.%(ext)s' --no-continue --no-mtime --no-call-home"

alias screenrec720panim="ffmpeg -f x11grab -framerate 30 -video_size 1280x720 -draw_mouse 0 -show_region 0 -i :0.0+640,254 -f pulse -channels 2 -ac 2 -thread_queue_size 512 -i alsa_output.pci-0000_00_1f.3.analog-stereo.monitor -c:v libx264 -threads 2 -pix_fmt yuv420p -preset veryfast -crf 17 -tune animation -c:a flac -map 0:v:0 -map 1:a:0 -flags bitexact recording.mkv"

alias enc24fpsanim="ffmpeg -i recording.mkv -ss -to -vf "decimate=cycle=5,setpts=N/24/TB" -c:v libx264 -threads 1 -crf 23 -preset veryfast -tune animation -c:a aac -map_metadata -1 -map 0:v:0 -map 0:a:0 -strict -2 -flags bitexact encoded.mp4"

#alias protonrun="STEAM_COMPAT_DATA_PATH=~/PREFIX_LOCATION/ ~/.steam/steam/steamapps/common/Proton\ 3.7/proton run ~/PROGRAM_LOCATION"

#wget --execute robots=off --adjust-extension --user-agent="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0" --recursive --level=inf --convert-links --backups=1 --backup-converted --page-requisites --include-directories="/post,/tagged/tag+name/page" https://staff.tumblr.com/tagged/tag+name

function cmpimg() {
  compare -metric AE "$1" "$2" "${3:-/dev/null}"
  echo
}

function stripmp3() {
  ffmpeg -i "$1" -id3v2_version 3 -c copy -map 0:a:0 "$2"
}

function md5audio() {
  ffmpeg -i "$1" -map 0:a -f md5 - 2>/dev/null
}

function md5video() {
  ffmpeg -i "$1" -map 0:v -f md5 - 2>/dev/null
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
    echo
    echo "** Processing: $in_file"
    in_size=$(stat -c %s "$in_file")
    echo "Input file size = $in_size bytes"
    echo
    
    temp=$(mktemp "$in_file.XXXXXX.mp4")
    ffmpeg -y -i "$in_file" -map_metadata -1 -c copy -map 0:v:0 -map 0:a:0 "$temp"
    
    ret=$?
    echo
    if [ "$ret" -ne 0 ]; then
      rm "$temp"
      echo "Error. Skipping $in_file"
      echo
      continue
    fi
    
    rm "$in_file"
    mv "$temp" "$in_file"
    out_size=$(stat -c %s "$in_file")
    
    size_diff=$(($in_size - $out_size))
    percent_diff=$(echo "100 * $size_diff / $in_size" | bc -l)
    echo "Output file size = $out_size bytes ($size_diff bytes = $percent_diff% decrease)"
    echo
  done
}

function jpgoptim() {
  for in_file in "$@"
  do
    echo
    echo "** Processing: $in_file"
    in_size=$(stat -c %s "$in_file")
    echo "Input file size = $in_size bytes"
    echo
    
    temp=$(mktemp "$in_file.XXXXXX")
    $HOME/binaries/mozjpeg/inst/bin/jpegtran -copy none -optimize -perfect "$in_file" > "$temp"
    
    ret=$?
    echo
    if [ "$ret" -ne 0 ]; then
      rm "$temp"
      echo "Error. Skipping $in_file"
      echo
      continue
    fi
    
    rm "$in_file"
    mv "$temp" "$in_file"
    out_size=$(stat -c %s "$in_file")
    
    size_diff=$(($in_size - $out_size))
    percent_diff=$(echo "100 * $size_diff / $in_size" | bc -l)
    echo "Output file size = $out_size bytes ($size_diff bytes = $percent_diff% decrease)"
    echo
  done
}

function kppextract() {
  line=$(identify -verbose "$1" | grep "preset:")
  l1=${line#*preset: }
  echo "$l1"
}

function kpptotxt() {
  preset=$(kppextract "$1")
  formatted=${preset//> <param />$'\n'<param }
  echo "$formatted" > "$1.txt"
}

function kppdiff() {
  preset1=$(kppextract "$1" | xmllint --c14n - | xmllint --format -)
  preset2=$(kppextract "$2" | xmllint --c14n - | xmllint --format -)
  diff <(echo "$preset1") <(echo "$preset2")
}

function kppwrite() {
  text=$(<"$2")
  unformatted=${text//>$'\n'<param /> <param }
  convert "$1" -set 'preset' "$unformatted" out.png
}

if [ -f ~/.bash_aliases_extra ]; then
  . ~/.bash_aliases_extra
fi
