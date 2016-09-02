alias md5r="find . -type f -exec md5sum {} +"
alias sha256r="find . -type f -exec sha256sum {} +"

alias md5c="md5sum -c --quiet"
alias sha256c="sha256sum -c --quiet"

alias pngoptim="optipng -strip all -o7"

alias aadebug="apparmor_parser -Q --debug"

function cmpimg() {
  compare -metric AE "$1" "$2" "${3:-/dev/null}"
  echo
}

function stripaudio() {
  ffmpeg -i "$1" -id3v2_version 3 -c copy -map 0:0 "$2"
}

function md5audio() {
  ffmpeg -i "$1" -map 0:a -f md5 - 2>/dev/null
}

function jpgoptim() {
  if [ ! -z "$2" ] && [ -e "$2" ]; then
    echo "Output file already exists. Exiting."
    echo
    return 1
  fi
  
  in_size=$(stat -c %s "$1")
  echo "Input file size = $in_size bytes"
  echo
  
  if [ -z "$2" ]; then
    temp=$(mktemp "$1.XXXXXX")
    $HOME/binaries/mozjpeg/inst/bin/jpegtran -copy none -optimize "$1" > "$temp"
    rm "$1"
    mv "$temp" "$1"
    out_size=$(stat -c %s "$1")
  else
    $HOME/binaries/mozjpeg/inst/bin/jpegtran -copy none -optimize "$1" > "$2"
    out_size=$(stat -c %s "$2")
  fi
  
  size_diff=$(($in_size - $out_size))
  percent_diff=$(echo "100 * $size_diff / $in_size" | bc -l)
  echo "Output file size = $out_size bytes ($size_diff bytes = $percent_diff% decrease)"
  echo
}
