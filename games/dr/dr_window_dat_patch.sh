#!/bin/bash

patch_danganronpa_window_dat() {
  local LC_ALL=C
  export LC_ALL
  
  local window_dat="${1}"
  if [ ! -w "${window_dat}" ] || [ "$(stat -c '%s' "${window_dat}")" -ne 28 ]; then
    printf 'Error: window.dat does not exist, is not writable, or is incorrect size\n' 1>&2
    exit 1
  fi
  
  # file is 28 bytes, consisting of 7 32-bit integers stored in little endian
  
  # Renderer: 00=Direct3D9, 01=OpenGL
  printf '\x01\x00\x00\x00' | dd status=none "of=${window_dat}" bs=1 seek=0 count=4 conv=notrunc
  
  # Width (1792 = 00 07 00 00)
  printf '\x00\x07\x00\x00' | dd status=none "of=${window_dat}" bs=1 seek=4 count=4 conv=notrunc
  
  # Height (1008 = F0 03 00 00)
  printf '\xF0\x03\x00\x00' | dd status=none "of=${window_dat}" bs=1 seek=8 count=4 conv=notrunc
  
  # VSync: 00=off, 01=on
  printf '\x01\x00\x00\x00' | dd status=none "of=${window_dat}" bs=1 seek=12 count=4 conv=notrunc
  
  # 00=windowed mode, 01=fullscreen, 02=borderless
  printf '\x00\x00\x00\x00' | dd status=none "of=${window_dat}" bs=1 seek=16 count=4 conv=notrunc
  
  # MSAA: 00=off, 01=2x, 02=4x, 03=8x, 04=16x
  printf '\x00\x00\x00\x00' | dd status=none "of=${window_dat}" bs=1 seek=20 count=4 conv=notrunc
  
  # Anisotropic Filtering: 00=off, 01=on
  printf '\x01\x00\x00\x00' | dd status=none "of=${window_dat}" bs=1 seek=24 count=4 conv=notrunc
}

game="$1"
shift
case "$game" in
  '1' | 'dr1')
    patch_danganronpa_window_dat "${HOME}/.local/share/Danganronpa/window.dat"
  ;;
  '2' | 'dr2')
    patch_danganronpa_window_dat "${HOME}/.local/share/Danganronpa2/window.dat"
  ;;
  *)
    printf 'Sets Danganronpa 1/2 graphics/window settings\n'
    printf 'Usage: dr_window_dat_patch [ dr1 | dr2 ]\n'
  ;;
esac

exit 0
