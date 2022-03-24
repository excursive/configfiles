#!/bin/bash

is_domain() {
  local LC_ALL=C
  export LC_ALL
  local regex='^\.?([a-z0-9-]+\.)*[a-z0-9-]+\.[a-z0-9-]+$'
  [[ "$1" =~ $regex ]]
}

is_domain_list() {
  local LC_ALL=C
  export LC_ALL
  local regex='^(\.?([a-z0-9-]+\.)*[a-z0-9-]+\.[a-z0-9-]+,)*\.?([a-z0-9-]+\.)*[a-z0-9-]+\.[a-z0-9-]+,?$'
  [[ "$1" =~ $regex ]]
}

ff_cookies_print() {
  local host_where_clause=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'Formats and prints a nestcape cookies file from a firefox cookies.sqlite db\n'
        printf 'Arguments:\n'
        printf '  [ -h | --help ] print this help message\n'
        printf '  [ --hosts HOST[,HOST]... only print cookies from the given domain(s)\n'
        printf '  [ path to cookies.sqlite file ]\n'
        printf '    (will find cookies.sqlite file automatically if omitted)\n'
        return 0
      ;;
      '--host' | '--hosts')
        if ! is_domain_list "$2"; then
          printf 'Error: Missing or invalid domain(s) for --hosts option\n' 1>&2
          return 1
        fi
        local hosts="${2%,}"
        local quoted_hosts="'${hosts//,/\',\'}'"
        host_where_clause=" where host in ($quoted_hosts)"
        shift 2
      ;;
      *)
        break
      ;;
    esac
  done
  
  local sql_db=''
  if [ -n "${1}" ] && [ -r "${1}" ]; then
    sql_db="${1}"
  else
    sql_db="$(find "${HOME}/.mozilla/firefox/" -mindepth 2 -maxdepth 2 -name 'cookies.sqlite' \
                -printf '%T@ %p\0' | sort -nrz -- | cut -d ' ' -f '2-' -z -- | \
                head --lines=1 --zero-terminated -- | tr --delete '\0' )"
  fi
  # session cookies are stored elsewhere, in recovery.jsonlz4
  local json_mozlz4="$(dirname "${sql_db}")"'/sessionstore-backups/recovery.jsonlz4'
  
  # make temporary copies of cookies.sqlite and recovery.jsonlz4 in case firefox is using them
  local temp_sql_db=''
  temp_sql_db="$(mktemp --tmpdir="${PWD}" -t 'cookies.sqlite.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not copy firefox cookies.sqlite file to a temp file\n' 1>&2
    return 1
  fi
  cat "${sql_db}" >| "${temp_sql_db}"
  
  local temp_json_mozlz4=''
  temp_json_mozlz4="$(mktemp --tmpdir="${PWD}" -t 'recovery.jsonlz4.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not copy firefox recovery.jsonlz4 file to a temp file\n' 1>&2
    return 1
  fi
  dd status=none bs=12 skip=1 "if=${json_mozlz4}" "of=${temp_json_mozlz4}"
  
  local netscape_header='# Netscape HTTP Cookie File'
  local sql_cookies=''
  sql_cookies="$(sqlite3 -noheader -separator $'\t' "${temp_sql_db}" \
          "select host, case substr(host,1,1)='.' when 0 then 'FALSE' else 'TRUE' end, path, case isSecure when 0 then 'FALSE' else 'TRUE' end, expiry, name, value from moz_cookies${host_where_clause};")"
  local ret_sql="$?"
  
  rm -f -- "${temp_sql_db}"
  if [ "$ret_sql" -ne 0 ]; then
    printf 'Error: An error occurred reading the sqlite cookies database\n' 1>&2
    return 1
  fi
  
  # construct a properly formatted lz4 file from recovery.jsonlz4
  local temp_lz4=''
  temp_lz4="$(mktemp --tmpdir="${PWD}" -t 'recovery.json.lz4.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not create a valid lz4 archive from recovery.jsonlz4\n' 1>&2
    return 1
  fi
  local json_decompressed=''
  json_decompressed="$(mktemp --tmpdir="${PWD}" -t 'recovery.json.XXXXXXXXXX')"
  if [ "$?" -ne 0 ]; then
    printf 'Error: Could not create uncompressed recovery.json temp flie\n' 1>&2
    return 1
  fi
  
  # all kinds of terrible things happening here
  # should really be using python or some library that can decompress arbitrary lz4 blocks
  local block_size="$(stat -c '%s' "${temp_json_mozlz4}")"
  local block_hex="$(printf -- '%08x' "$(("$block_size" & 2147483647))")"
  local hex_3="${block_hex:0:2}"
  local hex_2="${block_hex:2:2}"
  local hex_1="${block_hex:4:2}"
  local hex_0="${block_hex:6:2}"
  printf -- '\x04\x22\x4D\x18\x60\x60\x51' >> "${temp_lz4}"
  printf -- "\x${hex_0}\x${hex_1}\x${hex_2}\x${hex_3}" >> "${temp_lz4}"
  cat "${temp_json_mozlz4}" >> "${temp_lz4}"
  printf -- '\x00\x00\x00\x00' >> "${temp_lz4}"
  lz4 -q -q -d -f "${temp_lz4}" "${json_decompressed}"
  local session_cookies=''
  session_cookies="$(python3 <<EOF
import json

domains=[${quoted_hosts}]

with open('${json_decompressed}', 'r') as f:
  g=f.read()
j=json.loads(g)

for cookie in j['cookies']:
  if not domains or cookie['host'] in domains:
    flag='TRUE' if cookie['host'].startswith('.') else 'FALSE'
    print(cookie['host'], flag, cookie['path'], 'TRUE', '2147483647', cookie['name'], cookie['value'], sep='\t')
EOF
  )"
  rm -f -- "${temp_json_mozlz4}" "${temp_lz4}" "${json_decompressed}"
  
  if [ -z "$sql_cookies" ] && [ -z "$session_cookies" ]; then
    printf 'No cookies found\n' 1>&2
    return 0
  fi
  printf -- '%s\n%s\n%s\n' "$netscape_header" "$sql_cookies" "$session_cookies"
}

ff_cookies_quick() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    printf 'Arguments: [ HOST[,HOST]... ]\n'
    printf '  Quick function to write a netscape cookies.txt file with only the\n'
    printf '  cookies from the given domain(s)\n'
    exit 0
  fi
  
  local domains="$1"
  local output_file='cookies.txt'
  if [ -e "${output_file}" ]; then
    printf 'Error: Output file already exists\n' 1>&2
    return 1
  fi
  local output=''
  output="$(ff_cookies_print '--hosts' "$domains")"
  if [ "$?" -ne 0 ]; then
    return 1
  fi
  if [ -z "$output" ]; then
    return 0
  fi
  printf -- '%s\n' "$output" > "${output_file}"
}

if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
  printf 'Operations:\n'
  printf '  print [ -h ] [ --hosts HOST[,HOST]... ] ( optional cookies.sqlite file )\n'
  printf '  quick [ -h ] [ HOST[,HOST]... ]\n'
  exit 0
fi

declare operation="$1"
shift 1
case "$operation" in
  'print')
    ff_cookies_print "$@"
  ;;
  'quick')
    ff_cookies_quick "$@"
  ;;
  *)
    printf '\nError: Invalid operation\n' 1>&2
    exit 1
  ;;
esac
