// ==UserScript==
// @name        Tumblr High Res Image Download
// @namespace   http://excursiveart.deviantart.com/
// @description Shows a link to the highest res version of an image on tumblr
// @include     http://*.tumblr.com/*
// @include     http://tumblr.com/*
// @include     https://*.tumblr.com/*
// @include     https://tumblr.com/*
// @exclude     http://media.tumblr.com/*
// @exclude     http://*.media.tumblr.com/*
// @exclude     https://media.tumblr.com/*
// @exclude     https://*.media.tumblr.com/*
// @version     1
// @grant       none
// ==/UserScript==

var images = document.getElementsByTagName('img');
for (var i = 0; i < images.length; i++) {
  var image = images[i];
  if (isPostImage(image.src)) {
    var imgBox = document.createElement('div');
    imgBox.style.display = image.style.display;
    imgBox.style.position = 'relative';
    imgBox.style.width = image.style.width;
    imgBox.style.height = image.style.height;
    imgBox.style.minWidth = '50px';
    imgBox.style.minHeight = '50px';
    image.parentNode.replaceChild(imgBox, image);
    image.style.display = 'block';
    image.style.position = 'static';
    imgBox.appendChild(image);
    var highResLink = document.createElement('a');
    highResLink.href = getHighResLink(image.src);
    highResLink.onclick = function(e) {e.stopPropagation();};
    highResLink.target = '_blank';
    highResLink.innerHTML = '\u25BC';
    highResLink.style.position = 'absolute';
    highResLink.style.top = '8px';
    highResLink.style.left = '8px';
    highResLink.style.color = 'white';
    highResLink.style.fontFamily = 'Helvetica, Arial, sans-serif';
    highResLink.style.fontSize = '24px';
    highResLink.style.fontWeight = 'normal';
    highResLink.style.textDecoration = 'none';
    highResLink.style.lineHeight = 'initial';
    highResLink.style.textShadow = '0px 0px 1px black';
    highResLink.style.backgroundColor = 'rgba(0, 0, 0, 0.25)';
    highResLink.style.padding = '0em 0.15em';
    highResLink.style.border = '1px solid rgba(255, 255, 255, 0.5)';
    imgBox.appendChild(highResLink);
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
         endsWith(url, '_1280.jpg') ||
    
         endsWith(url, '_75sq.png') ||
         endsWith(url, '_100.png') ||
         endsWith(url, '_250.png') ||
         endsWith(url, '_400.png') ||
         endsWith(url, '_500.png') ||
         endsWith(url, '_540.png') ||
         endsWith(url, '_1280.png')/* ||
    
         endsWith(url, '_75sq.gif') ||
         endsWith(url, '_100.gif') ||
         endsWith(url, '_250.gif') ||
         endsWith(url, '_400.gif') ||
         endsWith(url, '_500.gif')*/;
}

function endsWith(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
}