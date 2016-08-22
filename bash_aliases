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
