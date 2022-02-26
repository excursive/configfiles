#!/bin/bash

is_positive_integer() {
  local LC_ALL=C
  export LC_ALL
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

is_domain_part() {
  local LC_ALL=C
  export LC_ALL
  local regex='^[0-9a-z-]+$'
  [[ "$1" =~ $regex ]]
}

is_tumblr_tag() {
  local LC_ALL=C
  export LC_ALL
  local regex='^([0-9A-Za-z._?!()=+-]*(\%[0-9A-Fa-f]{2})*)*$'
  [[ "$1" =~ $regex ]]
}





tumblr_backup() {
  local LC_ALL=C
  export LC_ALL
  
  local wait='0'
  local levels='inf'
  local username=''
  local tag=''
  local post=''
  local start_page=''
  local end_page=''
  local chrono=''
  local pages=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      '-h' | '--help')
        printf 'tumblr_backup [OPTIONS]... -u <username> [ -t <tag> | -p <post id> ]\n'
        printf 'Arguments:\n'
        printf '  -w, --wait        <average random wait time in seconds> (default 0)\n'
        printf '  -u, --username    <tumblr username>\n'
        printf '  -p, --post        <tumblr post id>\n'
        printf '  -t, --tag         <tumblr tag>\n'
        printf '  -s, --start-page  <positive integer>\n'
        printf '  -e, --end-page    <positive integer>\n'
        printf '  -c, --chrono      download tagged/<tag>/chrono/(pages)\n'
        printf '  --include-posts (when downloading tag, download individual posts as well)\n'
        printf '    (however, a better solution for read-mores is to search the tag pages)\n'
        printf '     for read-more links afterwards and only download those)\n'
        return 0
      ;;
      '-w' | '--wait')
        wait="$2"
        if ! is_positive_integer "$wait"; then
          printf '\e[0;31mError:\e[0m Invalid wait time: %s\n\n' "$wait" 1>&2
          exit 1
        fi
      ;;
      '-u' | '--username')
        username="$2"
        if ! is_domain_part "$username"; then
          printf '\e[0;31mError:\e[0m Invalid username: %s\n\n' "$username" 1>&2
          exit 1
        fi
      ;;
      '-t' | '--tag')
        tag="$2"
        if ! is_tumblr_tag "$tag"; then
          printf '\e[0;31mError:\e[0m Invalid tag: %s\n\n' "$tag" 1>&2
          exit 1
        fi
      ;;
      '-p' | '--post')
        post="$2"
        if ! is_positive_integer "$post"; then
          printf '\e[0;31mError:\e[0m Invalid tumblr post id: %s\n\n' "$post" 1>&2
          exit 1
        fi
      ;;
      '-s' | '--start-page')
        start_page="$2"
        if ! is_positive_integer "$start_page"; then
          printf '\e[0;31mError:\e[0m Invalid starting page: %s\n\n' "$start_page" 1>&2
          exit 1
        fi
      ;;
      '-e' | '--end-page')
        end_page="$2"
        if ! is_positive_integer "$end_page"; then
          printf '\e[0;31mError:\e[0m Invalid ending page: %s\n\n' "$end_page" 1>&2
          exit 1
        fi
      ;;
      '-c' | '--chrono')
        chrono='chrono/'
        shift 1
        continue
      ;;
      *)
        printf '\e[0;31mError:\e[0m Invalid arument: %s\n\n' "$1" 1>&2
        exit 1
      ;;
    esac
    shift 2
  done
  if [ -z "$username" ]; then
    printf '\e[0;31mError:\e[0m No username specified\n\n' 1>&2
    exit 1
  fi
  if [ -n "$chrono" ] && [ -z "$tag" ]; then
    printf '\e[0;31mError:\e[0m Tumblr chrono option only works for tags\n\n' 1>&2
    exit 1
  fi
  
  local -a base_args=( '--execute' 'robots=off' '--execute' 'trust_server_names=off' )
  base_args+=( '--no-verbose' '--https-only' '--force-directories' )
  base_args+=( '--user-agent=Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0' )
  
  local -a args=( "--wait=${wait}" '--random-wait' )
  #args+=( '--recursive' '--level=inf' )
  args+=( '--span-hosts' )
  args+=( '--page-requisites' )
  args+=( '--domains=tumblr.com' )
  args+=( '--exclude-domains' 'media.tumblr.com,px.srvcs.tumblr.com' )
  #args+=( '--include-directories=/post,/tagged/tag+name/page' )
  args+=( '--timestamping' )
  #args+=( '--adjust-extension' )
  args+=( '--convert-links' )
  args+=( '--backups=0' )
  
  local -a urls=()
  if [ -n "$post" ]; then
    if [ -n "$tag" ]; then
      printf '\e[0;31mError:\e[0m Specified both a tag and individual post\n\n' 1>&2
      exit 1
    fi
    urls+=( "https://${username}.tumblr.com/post/${post}" )
  else
    if [ -z "$start_page" ] || [ -z "$end_page" ]; then
      printf '\e[0;31mError:\e[0m Must specify both a start and end page\n\n' 1>&2
      exit 1
    fi
    local page="$start_page"
    while [ "$page" -le "$end_page" ]; do
      if [ -n "$tag" ]; then
        urls+=( "https://${username}.tumblr.com/tagged/${tag}/${chrono}page/${page}" )
      else
        urls+=( "https://${username}.tumblr.com/page/${page}" )
      fi
      page="$(( $page + 1 ))"
    done
  fi
  wget "${base_args[@]}" "${args[@]}" -- "${urls[@]}"
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31mError:\e[0m Download failed\n\n' 1>&2
    exit 1
  fi
  
  printf '\n\n================ Download Complete ================\n\n'
  
  local manual_list='posts_'"$(date '+%Y-%m-%d___%H-%M-%S')"'.html'
  local manual_list_header='<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>posts to manually get images</title>
  </head>
  <body>
    <ol>'
  if [ -e "${manual_list}" ]; then
    printf '\e[0;31mError:\e[0m Cannot save log of posts to manually check\n\n' 1>&2
    exit 1
  fi
  printf '%s\n' "$manual_list_header" > "$manual_list"
  
  local -a failed=()
  local -a post_urls=()
  # image urls to be collected from /post/<id> pages and /image/<id> view pages
  local image_urls=''
  # images with tumblr new style urls that we couldn't get the max res for
  local low_res_image_count='0'
  
  local posts_list=''
  local url
  for url in "${urls[@]}"; do
    local page="${url#https://}"
    if [ ! -e "${page}" ]; then
      failed+=( "${url}" )
      continue
    fi
    
    posts_list="$posts_list""$(grep --only-matching --extended-regexp "https://${username}\.tumblr\.com/post/[0-9]+" -- "${page}")"$'\n'
  done
  
  readarray -t post_urls < <( printf '%s' "$posts_list" | sed -e '/^$/d' - -- | sort --unique - -- )
  
  if [ "${#post_urls[@]}" -gt 0 ]; then
    wget "${base_args[@]}" --adjust-extension "--referer=${url}" -- "${post_urls[@]}"
    wget "${base_args[@]}" "--referer=${url}" -- "${post_urls[@]/post\//image\/}"
  fi
  
  local post_url
  for post_url in "${post_urls[@]}"; do
    local post="${post_url#https://}.html"
    if [ ! -e "${post}" ]; then
      failed+=( "${post_url}" )
      continue
    fi
    
    # super old image urls with no resolution indicator
    image_urls="$image_urls""$(grep --invert-match 'post-thumbnail-container' -- "${post}" | grep --only-matching --extended-regexp \
        'https://([0-9]+\.)?media\.tumblr\.com/([0-9A-Za-z_-]+/)?tumblr_(inline_)?[0-9A-Za-z]+\.[0-9A-Za-z]+' - -- | sort --unique - --)"$'\n'
    # medium age image urls, from when 1280 was the max width
    image_urls="$image_urls""$(grep --invert-match 'post-thumbnail-container' -- "${post}" | grep --only-matching --extended-regexp \
        'https://([0-9]+\.)?media\.tumblr\.com/([0-9A-Za-z_-]+/)?tumblr_(inline_)?[0-9A-Za-z]+_[0-9A-Za-z_-]+\.[0-9A-Za-z_-]+' - -- | \
        sed --regexp-extended -e 's/_[0-9A-Za-z-]+\./_1280./' -- | sort --unique - --)"$'\n'
    
    # shitty new image urls, cannot get the max res url on many old blog themes
    local new_image_urls="$(grep --invert-match 'post-thumbnail-container' -- "${post}" | \
        grep --only-matching --extended-regexp \
        'https://([0-9]+\.)?media\.tumblr\.com/[0-9A-Za-z_-]+/[0-9A-Za-z_-]+/s[0-9]+x[0-9]+/[0-9A-Za-z_-]+\.[0-9A-Za-z_-]+' - -- | \
        sort --unique - --)"
    local -a unique_new_images=()
    readarray -t unique_new_images < <( printf '%s' "$new_image_urls" | \
        cut --delimiter='/' --fields=4-5 - -- | sort --unique - -- )
    
    # find out how many unique images with new urls there are by using the
    # 2 tokens preceeding the resolution that are unique for each image
    local -a only_low_res_unique_new_images=()
    local new_image
    for new_image in "${unique_new_images[@]}"; do
      local max_res_url="$(grep --max-count=1 --only-matching --extended-regexp \
          "https://([0-9]+\.)?media\.tumblr\.com/${new_image}/s2048x3072/[0-9A-Za-z_-]+\.[0-9A-Za-z_-]+" -- "${post}")"
      if [ -n "${max_res_url}" ]; then
        image_urls="${image_urls}${max_res_url}"$'\n'
      else
        only_low_res_unique_new_images+=( "$new_image" )
      fi
    done
    
    if [ "${#only_low_res_unique_new_images[@]}" -eq 0 ]; then
      continue
    fi
    
    # if there are new image urls, we can get the max res url for the first image
    # from the /image/<id> page, but are out of luck for posts with multiple images
    if [ "${#only_low_res_unique_new_images[@]}" -eq 1 ]; then
      local image_view="$(sed --regexp-extended -e 's_^https://__' -e 's_post/_image/_' - -- <<< "$post_url")"
      if [ -e "${image_view}" ]; then
        local image_view_url="$(grep --only-matching --extended-regexp \
            'https://([0-9]+\.)?media\.tumblr\.com/[0-9A-Za-z_-]+/[0-9A-Za-z_-]+/s[0-9]+x[0-9]+/[0-9A-Za-z_-]+\.[0-9A-Za-z_-]+' -- "${image_view}" | \
            tail --lines=1 --)"
        local image_view_unique="$(cut --delimiter='/' --fields=4-5 - -- <<< "${image_view_url}")"
        
        if [ "${only_low_res_unique_new_images[0]}" = "$image_view_unique" ]; then
          image_urls="${image_urls}${image_view_url}"$'\n'
          continue
        fi
      fi
    fi
    
    # multiple new images in post, write post link to log for high res urls to be collected manually
    local post_id="$(sed --regexp-extended -e 's_^https://[0-9a-z-]+.tumblr.com/post/__' \
                                           -e 's_[^0-9]*$__' - -- <<< "$post_url")"
    local post_dash_link="<li><a href=\"https://www.tumblr.com/blog/view/${username}/${post_id}\">${#only_low_res_unique_new_images[@]}</a></li>"
    printf '      %s\n' "$post_dash_link" >> "${manual_list}"
    low_res_image_count="$(( $low_res_image_count + ${#new_image_urls[@]} ))"
  done
  
  image_urls="$(printf '%s' "$image_urls" | sed -e '/^$/d' - -- | sort --unique - --)"
  
  printf '%s' "$image_urls" | xargs --no-run-if-empty -d '\n' \
      wget "${base_args[@]}" "--referer=https://${username}.tumblr.com/" --
  if [ "$?" -ne 0 ]; then
    printf '\e[0;31mError:\e[0m High-res image download failed\n\n' 1>&2
    exit 1
  fi
  
  local manual_list_sol='    </ol>
  <p>'
  local manual_list_footer='</p>
  </body>
</html>'
  printf '%sTotal low res images: %s%s\n' "$manual_list_sol" "$low_res_image_count" "$manual_list_footer" >> "$manual_list"
  
  if [ "${#failed[@]}" -ne 0 ]; then
    printf '\e[0;31mError:\e[0m Errors encountered while downloading the following:\n' 1>&2
    printf '%s\n' "${failed[@]}" 1>&2
  fi
}





tumblr_adjust_urls() {
}





operation="$1"
shift 1
case "$operation" in
  '' | '-h' | '--help')
    printf 'tumblr_backup [ backup | adjust-urls ] [ARGUMENTS]...\n'
    printf '  see backup --help or adjust-urls --help for operation arguments\n'
  ;;
  'backup')
    tumblr_backup "$@"
  ;;
  'adjust-urls')
    tumblr_adjust_urls "$@"
  ;;
  *)
    printf '\e[0;31mError:\e[0m Invalid arument: %s\n\n' "$1" 1>&2
    exit 1
  ;;
esac

exit 0
