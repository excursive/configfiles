#!/bin/bash

# for converting gbr, etc images unreadable by imagemagick to png using GIMP

gimp_png_batch_convert() {
  local in_file=''
  for in_file in "$@"; do
    local dir_name="$(dirname -- "${in_file}")"
    local base_name="$(basename -- "${in_file}")"
    local no_ext="${base_name%.*}"
    if ! [ -n "${no_ext}" ]; then
      printf -- '\e[0;31mError:\e[0m Empty filename\n' 1>&2
      return 1
    fi
    local out_file="${dir_name}/out/${no_ext}.png"
    if ! [ ! -e "${out_file}" ]; then
      printf -- '\e[0;31mError:\e[0m Output file already exists: %s\n' "${out_file}" 1>&2
      return 1
    fi
    mkdir --parents -- "${dir_name}/out"
    gimp --no-interface --no-data --no-fonts --no-splash \
         -b '
(define (pngconvert in_filename out_filename)
    (let* (
            (image (car (gimp-file-load RUN-NONINTERACTIVE in_filename in_filename)))
            (drawable (car (gimp-image-get-active-layer image)))
        )
        (file-png-save2 RUN-NONINTERACTIVE image drawable out_filename out_filename 0 5 0 0 0 0 0 0 0)
        (gimp-image-delete image)
    )
)
(pngconvert "'"${in_file}"'" "'"${out_file}"'")
(gimp-quit 0)'
  done
}

gimp_png_batch_convert "$@"
