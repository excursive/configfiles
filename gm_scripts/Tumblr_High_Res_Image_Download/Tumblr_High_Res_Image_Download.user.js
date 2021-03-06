// ==UserScript==
// @name        Tumblr High Res Image Download
// @namespace   http://github.com/excursive
// @description Shows a link to the highest res version of an image on tumblr
// @include     http://*.tumblr.com/*
// @include     http://tumblr.com/*
// @include     https://*.tumblr.com/*
// @include     https://tumblr.com/*
// @exclude     http://media.tumblr.com/*
// @exclude     http://*.media.tumblr.com/*
// @exclude     https://media.tumblr.com/*
// @exclude     https://*.media.tumblr.com/*
// @version     1.1
// @run-at      document-idle
// ==/UserScript==

var linkcss = '.highresimglink:hover { opacity: 0.65; }';
var styleNode = document.createElement('style');
styleNode.innerHTML = linkcss;
document.head.appendChild(styleNode);

var images = document.getElementsByTagName('img');
for (var i = 0; i < images.length; i++) {
  var image = images[i];
  if (isPostImage(image.src)) {
    var link = document.createElement('a');
    var imgStyle = window.getComputedStyle(image);
    if (imgStyle.getPropertyValue('display') === 'block') {
      link.style.display = 'block';
    } else {
      link.style.display = 'inline-block';
    }
    link.style.position = imgStyle.getPropertyValue('position');
    if (image.style.width) {
      // preserve percentage width value if set
      link.style.width = image.style.width;
    } else {
      link.style.width = imgStyle.getPropertyValue('width');
    }
    link.style.height = image.style.height;
    link.style.minWidth = '75px';
    link.style.minHeight = '75px';
    link.href = getHighResLink(image.src);
    link.onclick = function(e) {e.stopPropagation();};
    link.target = '_blank';
    image.parentNode.replaceChild(link, image);
    image.style.display = 'block';
    image.style.position = 'static';
    image.style.width = '100%';
    image.style.height = 'auto';
    link.appendChild(image);
    link.className = 'highresimglink';
  }
}

function getHighResLink(url) {
  var start = url.lastIndexOf('_') + 1;
  var end = url.lastIndexOf('.');
  //if (endsWith(url, 'gif')) {
    //return url.substring(0, start) + '500' + url.substring(end);
  //} else {
    return url.substring(0, start) + '1280' + url.substring(end);
  //}
}

function isPostImage(url) {
  return endsWith(url, '_75sq.jpg') ||
         endsWith(url, '_100.jpg') ||
         endsWith(url, '_250.jpg') ||
         endsWith(url, '_400.jpg') ||
         endsWith(url, '_500.jpg') ||
         endsWith(url, '_540.jpg') ||
         endsWith(url, '_640.jpg') ||
         endsWith(url, '_1280.jpg') ||
    
         endsWith(url, '_75sq.png') ||
         endsWith(url, '_100.png') ||
         endsWith(url, '_250.png') ||
         endsWith(url, '_400.png') ||
         endsWith(url, '_500.png') ||
         endsWith(url, '_540.png') ||
         endsWith(url, '_640.png') ||
         endsWith(url, '_1280.png') ||
    
         endsWith(url, '_75sq.gif') ||
         endsWith(url, '_100.gif') ||
         endsWith(url, '_250.gif') ||
         endsWith(url, '_400.gif') ||
         endsWith(url, '_500.gif') ||
         endsWith(url, '_540.gif') ||
         endsWith(url, '_640.gif') ||
         endsWith(url, '_1280.gif');
}

function endsWith(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
}
