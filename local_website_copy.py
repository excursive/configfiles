#!/usr/bin/python3

import sys
import os
import re
import urllib.request
import urllib.parse
import urllib.error
from lxml import etree
from pathlib import Path
from decimal import Decimal
from operator import itemgetter

try:
    assert sys.version_info >= (3, 10)
except AssertionError:
    print('Error: Python installation out of date')
    sys.exit(1)


skip_http_errors = False
if len(sys.argv) >= 4 and sys.argv[3] == '--skip-errors':
    skip_http_errors = True


url_scheme_regex = re.compile('^(http|https)://(.+)$')
def strip_url_scheme(url):
    url_match = url_scheme_regex.match(url)
    if url_match is None:
        print(f"Error: Invalid URL: {url}")
        sys.exit(2)
    return url_match.group(2)


# Need to escape ? and # in src/href so the browser doesn't try
# to treat them as query/fragment indicators for local images
# Also escape % so they aren't treated as escapes in filenames
def correct_link(url):
    return url.replace('%', '%25').replace('?', '%3F').replace('#', '%23')


opener = urllib.request.build_opener()
opener.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0')]
urllib.request.install_opener(opener)

def dl_if_not_exists(out_file, url):
    Path(os.path.dirname(out_file)).mkdir(parents=True, exist_ok=True)
    try:
        assert not os.path.exists(out_file)
    except AssertionError:
        #print(f"{out_file} already exists. Skipping.")
        return
    
    try:
        urllib.request.urlretrieve(url, out_file)
    except urllib.error.HTTPError as e:
        print(f"\n==== HTTP Error:\nCode: {e.code}\nURL: {e.url}\nReason: {e.reason}")
        if not skip_http_errors:
            sys.exit(4)


# could break on invalid urls that aren't quoted and contain an end parenthesis.
style_url_regex = re.compile("(url\\(['\"]?)([^'\")]*)(['\"]?\\))")
def replace_css_url(matchobj):
    url = matchobj.group(2)
    if url.startswith('data:'):
        return matchobj.group(0)
    url = urllib.parse.urljoin(stylesheet_url, url)
    out_file = strip_url_scheme(url)
    dl_if_not_exists(out_file, url)
    return f"{matchobj.group(1)}{out_file}{matchobj.group(3)}"



# TODO: Handle multiple pages
if sys.argv[1] and sys.argv[2]:
    f = sys.argv[1]
    current_url = sys.argv[2]
    relative_path_to_base_dir = os.path.relpath('.', strip_url_scheme(current_url))
    
    tree = etree.parse(f, parser=etree.HTMLParser())
    
    base_url_for_relative_links = current_url
    base_tags = tree.xpath('//base')
    if len(base_tags) > 0:
        base_tag = base_tags[0]
        base_url_for_relative_links = urllib.parse.urljoin(current_url, base_tag.get('href'))
    else:
        base_tag = etree.Element('base')
    base_tag.set('href', relative_path_to_base_dir)
    
    
    non_num_regex = re.compile('[^0-9.]')
    imgs_with_origs = tree.xpath('//img')
    for img in imgs_with_origs:
        # wordpress full size images
        data_orig_file = img.get('data-orig-file')
        srcset = img.get('srcset')
        if data_orig_file:
            url = data_orig_file
        elif srcset:
            tuples = [(s.rsplit(' ', 1)[0], Decimal(non_num_regex.sub('', s.rsplit(' ', 1)[1]))) \
                      for s in srcset.split(', ')]
            ascending = sorted(tuples, key=itemgetter(1))
            url = ascending[-1][0]
        else:
            url = img.get('src')
        
        url = urllib.parse.urljoin(base_url_for_relative_links, url)
        out_img = strip_url_scheme(url)
        
        img.set('src', correct_link(out_img))
        try:
            img.attrib.pop('srcset')
        except KeyError:
            pass
        
        links_to_img = tree.xpath(f"//a[@href='{url}']")
        for link in links_to_img:
            link.set('href', correct_link(out_img))
        
        dl_if_not_exists(out_img, url)
    
    
    stylesheet_url = base_url_for_relative_links
    styles = tree.xpath('//style')
    for style in styles:
        style.text = style_url_regex.sub(replace_css_url, style.text)
    
    
    links = tree.xpath('//link')
    for link in links:
        match link.get('rel'):
            case 'stylesheet' | 'icon':
                url = link.get('href')
                url = urllib.parse.urljoin(base_url_for_relative_links, url)
                out_file = strip_url_scheme(url)
                #TODO: Should # be escaped for local stylesheets and/or icons?
                link.set('href', correct_link(out_file))
                dl_if_not_exists(out_file, url)
                
                # Browser blocks reading external stylesheets with the error
                # "Cross-Origin Request Blocked", so convert to inline stylesheet
                if link.get('rel') == 'stylesheet':
                    with open(out_file, 'r') as stylesheet:
                        css = stylesheet.read()
                        style = etree.Element('style')
                        
                        link_id = link.get('id')
                        if link_id is not None:
                            style.set('id', link_id)
                        
                        link_media = link.get('media')
                        if link_media is not None:
                            style.set('media', link_media)
                        
                        link_title = link.get('title')
                        if link_title is not None:
                            style.set('title', link_title)
                        
                        stylesheet_url = url
                        style.text = style_url_regex.sub(replace_css_url, css)
                        link.getparent().replace(link, style)
            case _:
                link.getparent().remove(link)
    
    
    
    
    iframes = tree.xpath('//iframe')
    for iframe in iframes:
        iframe.getparent().remove(iframe)
#        url = iframe.get('src')
#        url = urllib.parse.urljoin(base_url_for_relative_links, url)
#        out_file = strip_url_scheme(url)
#        # I think we don't want to escape # for local iframe urls
#        iframe.set('src', out_file.replace('%', '%25').replace('?', '%3F'))
#        dl_if_not_exists(out_file, url)
    
    
    scripts = tree.xpath('//script')
    for script in scripts:
        script.getparent().remove(script)
    
    
    out_html_file = f"{f}-processed.html"
    try:
        assert not os.path.exists(out_html_file)
    except AssertionError:
        print(f"{out_html_file} already exists. Skipping.")
        sys.exit(0)
        #continue
    
    tree.write(out_html_file, encoding='utf-8', method='html', pretty_print=False)
    #lxml doesn't write a newline after last line
    with open(out_html_file, 'at') as out:
        out.write('\n')

sys.exit(0)



