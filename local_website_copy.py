#!/usr/bin/python3

import sys
import os
import re
from lxml import etree
from lxml.html import soupparser
import urllib.request
from pathlib import Path
from pprint import pprint
from urllib.parse import urlparse
from decimal import Decimal
from operator import itemgetter

try:
    assert sys.version_info >= (3, 10)
except AssertionError:
    print('Error: Python installation out of date')
    sys.exit(1)


# Need to escape ? and # in src/href so the browser doesn't try
# to treat them as query/fragment indicators for local images
# Also escape % so they aren't treated as escapes in filenames
def correct_link(url):
    return url.replace('%', '%25').replace('?', '%3F').replace('#', '%23')


opener = urllib.request.build_opener()
opener.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0')]
urllib.request.install_opener(opener)

def dl_if_not_exists(url, out_file):
    #TODO: Determine if ' or others need to be escaped as well
    #out_file = out_file_no_char_escapes.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
    
    Path(os.path.dirname(out_file)).mkdir(parents=True, exist_ok=True)
    try:
        assert not os.path.exists(out_file)
    except AssertionError:
        print(f"{out_file} already exists. Skipping.")
        return
    
    urllib.request.urlretrieve(url, out_file)



for f in sys.argv[1:]:
    tree = etree.parse(f, parser=etree.HTMLParser())
    #tree = soupparser.parse(f)
    
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
        
        split_url = url.split('/', 3)
        out_img = f"{split_url[2]}/{split_url[3]}"
        
        img.set('src', correct_link(out_img))
        try:
            img.attrib.pop('srcset')
        except KeyError:
            pass
        
        links_to_img = tree.xpath(f"//a[@href='{url}']")
        for link in links_to_img:
            link.set('href', correct_link(out_img))
        
        dl_if_not_exists(url, out_img)
    
    
    links = tree.xpath('//link')
    for link in links:
        match link.get('rel'):
            case 'stylesheet' | 'icon':
                url = link.get('href')
                split_url = url.split('/', 3)
                out_file = f"{split_url[2]}/{split_url[3]}"
                #TODO: Should # be escaped for local stylesheets and/or icons?
                link.set('href', correct_link(out_file))
                dl_if_not_exists(url, out_file)
                
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
                        
                        style.text = css
                        link.getparent().replace(link, style)
            case _:
                link.getparent().remove(link)
    
    
    style_url_start_regex = re.compile("url\\('https?://")
    style_url_regex = re.compile("url\\('([^']*)'\\)")
    styles = tree.xpath('//style')
    for style in styles:
        for url in style_url_regex.findall(style.text):
            if url.startswith('data:'):
                continue
            split_url = url.split('/', 3)
            out_file = f"{split_url[2]}/{split_url[3]}"
            dl_if_not_exists(url, out_file)
        style.text = style_url_start_regex.sub("url('", style.text)
    
    
    iframes = tree.xpath('//iframe')
    for iframe in iframes:
        iframe.getparent().remove(iframe)
#        url = iframe.get('src')
#        split_url = url.split('/', 3)
#        out_file = f"{split_url[2]}/{split_url[3]}"
#        # I think we don't want to escape # for local iframe urls
#        iframe.set('src', out_file.replace('%', '%25').replace('?', '%3F'))
#        dl_if_not_exists(url, out_file)
    
    
    scripts = tree.xpath('//script')
    for script in scripts:
        script.getparent().remove(script)
    
    
    out_html_file = f"{f}-processed.html"
    try:
        assert not os.path.exists(out_html_file)
    except AssertionError:
        print(f"{out_html_file} already exists. Skipping.")
        continue
    
    tree.write(out_html_file, encoding='utf-8', method='html', pretty_print=False)
    #lxml doesn't write a newline after last line
    with open(out_html_file, 'at') as out:
        out.write('\n')

sys.exit(0)



