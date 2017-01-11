alias srm="rm -I"

alias md5r="find . -type f -exec md5sum {} +"
alias sha256r="find . -type f -exec sha256sum {} +"

alias md5c="md5sum -c --quiet"
alias sha256c="sha256sum -c --quiet"

alias pngoptim="optipng -strip all -o7"

alias aadebug="apparmor_parser -Q --debug"

alias youtube-music-dl="youtube-dl --output '%(uploader)s_%(title)s_%(id)s.%(ext)s' --no-continue --no-mtime --no-call-home --extract-audio"

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
  formatted=${l1//> <param />$'\n'<param }
  echo "$formatted" > "$1.txt"
}

function kppwrite() {
  text=$(<"$2")
  unformatted=${text//>$'\n'<param /> <param }
  convert "$1" -set 'preset' "$unformatted" out.png
}

if [ -f ~/.bash_aliases_extra ]; then
  . ~/.bash_aliases_extra
fi
