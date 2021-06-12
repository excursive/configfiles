#!/bin/bash

patch_steam_quake_2() {
  local LC_ALL=C
  export LC_ALL
  
  # make sure we have an unmodified steam quake2 version 3.20 exe
  local q2_exe="${HOME}/.steam/debian-installation/steamapps/common/Quake 2/quake2.exe"
  if [ ! -w "${q2_exe}" ]; then
    printf 'Error: Steam quake 2 v3.20 exe does not exist or is not writable\n' 1>&2
    exit 1
  fi
  printf '8c9d5a798055fbaed2718156108ae081877156311ae5fb159f64a778f02c2ade  %s\n' "${q2_exe}" | \
      sha256sum --check
  if [ "$?" -ne 0 ]; then
    if [ "$1" = 'modified' ]; then
      printf 'Warning: Steam quake 2 v3.20 exe checksum mismatch, but modifying anyway\n' 1>&2
    else
      printf 'Error: Steam quake 2 v3.20 exe checksum mismatch, exiting\n' 1>&2
      exit 1
    fi
  fi
  
  # replace 32 bit float max fov with gun value of 90 with 130 (big endian)
  printf '\x00\x00\x02\x43' | dd "of=${q2_exe}" bs=1 seek=293632 count=4 conv=notrunc
  # replace 32 bit integer 1600x1200 resolution (gl_mode 9)
  # 1920x1080 (big endian) = 80 07 00 00   38 04 00 00
  # 1848x1016 (big endian) = 38 07 00 00   F8 03 00 00
  printf '\x38\x07\x00\x00' | dd "of=${q2_exe}" bs=1 seek=345188 count=4 conv=notrunc
  printf '\xF8\x03\x00\x00' | dd "of=${q2_exe}" bs=1 seek=345192 count=4 conv=notrunc
}

patch_steam_quake_2 "$@"

exit 0
