#!/bin/bash

# make bash stricter about errors
#set -e
#set -o pipefail


get_local_site() {
  local -a base_args=( '--execute' 'robots=off' '--execute' 'trust_server_names=off' )
  base_args+=( '--no-verbose' '--https-only' )
  base_args+=( '--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0' )
  
  local -a args=( "--wait=1" '--random-wait' )
  #args+=( '--recursive' '--level=inf' )
  args+=( '--span-hosts' )
  args+=( '--force-directories' )
  args+=( '--page-requisites' )
  #args+=( '--domains=' )
  #args+=( '--exclude-domains' '' )
  #args+=( '--include-directories=' )
  args+=( '--timestamping' )
  #args+=( '--adjust-extension' )
  args+=( '--convert-links' )
  args+=( '--backups=0' )
  
  local -a urls=()
  urls+=( "$1" )

  wget "${base_args[@]}" "${args[@]}" -- "${urls[@]}"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31mError:\e[0m Download failed\n\n' 1>&2
    exit 1
  fi
}



if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Arguments:\n'
  exit 0
fi

get_local "$@"

