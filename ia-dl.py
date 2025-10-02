#!/usr/bin/python3

import sys
import os
import argparse
import re
import zlib
import hashlib
import time
import random
from lxml import etree
from lxml.html import soupparser
import urllib.request
from pathlib import Path
from pprint import pprint
from urllib.parse import urlparse
from decimal import Decimal
from operator import itemgetter

try:
    assert sys.version_info >= (3, 11)
except AssertionError:
    print('Error: Python installation out of date')
    sys.exit(1)


def crc32_file(file_name):
    with open(file_name, 'rb') as file:
        value = 0
        while True:
            data = file.read(16777216)
            if not data:
                break
            value = zlib.crc32(data, value)
        return "%08x" % (value & 0xFFFFFFFF)

def md5_file(file_name):
    with open(file_name, 'rb', buffering=16777216) as file:
        return hashlib.file_digest(file, 'md5').hexdigest()

def sha1_file(file_name):
    with open(file_name, 'rb', buffering=16777216) as file:
        return hashlib.file_digest(file, 'sha1').hexdigest()

def sha256_file(file_name):
    with open(file_name, 'rb', buffering=16777216) as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()



opener = urllib.request.build_opener()
opener.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:143.0) Gecko/20100101 Firefox/143.0')]
urllib.request.install_opener(opener)

def dl_if_not_exists(url, out_file):
    Path(os.path.dirname(out_file)).mkdir(parents=True, exist_ok=True)
    try:
        assert not os.path.exists(out_file)
    except AssertionError:
        print(f"Skipping existing file: {out_file}")
        return

    time.sleep(random.uniform(3.0, 8.0))

    urllib.request.urlretrieve(url, out_file)



parser = argparse.ArgumentParser(allow_abbrev=False)
parser.add_argument('--no-download-missing', action='store_true')
parser.add_argument('archive_item', nargs='+')
args = parser.parse_args()



for item in args.archive_item:
    Path(item).mkdir(exist_ok=True)
    file_list = f"{item}_files.xml"
    dl_if_not_exists(f"https://archive.org/download/{item}/{file_list}", f"{item}/{file_list}")

    tree = etree.parse(f"{item}/{file_list}")

    files = tree.xpath('//file')
    for file in files:
        file_name = file.get('name')
        
        if not os.path.exists(f"{item}/{file_name}"):
            private_tag_list = file.xpath('./private')
            if len(private_tag_list) > 0 and private_tag_list[0].text == 'true':
                print(f"  Access Restricted File: {file_name}")
                continue
            
            if args.no_download_missing:
                print(f"            Missing File: {file_name}")
                continue
            
            file_name_escaped = urllib.parse.quote(file_name)

            dl_if_not_exists(f"https://archive.org/download/{item}/{file_name_escaped}", f"{item}/{file_name}")

        if file_name == file_list:
            continue

        crc32 = file.xpath('./crc32')[0].text
        md5 = file.xpath('./md5')[0].text
        sha1 = file.xpath('./sha1')[0].text

        calc_crc32 = crc32_file(f"{item}/{file_name}")
        if calc_crc32 != crc32:
            print(f"\n==== Error: {file_name} crc32 {calc_crc32} does not match IA record {crc32}")
            sys.exit(2)

        calc_md5 = md5_file(f"{item}/{file_name}")
        if calc_md5 != md5:
            print(f"\n==== Error: {file_name} md5 {calc_md5} does not match IA record {md5}")
            sys.exit(2)

        calc_sha1 = sha1_file(f"{item}/{file_name}")
        if calc_sha1 != sha1:
            print(f"\n==== Error: {file_name} sha1 {calc_sha1} does not match IA record {sha1}")
            sys.exit(2)

        print(f"OK: {file_name}")



sys.exit(0)



