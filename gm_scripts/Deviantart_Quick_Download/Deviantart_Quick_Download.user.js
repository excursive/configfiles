// ==UserScript==
// @name        Deviantart Quick Download
// @namespace   http://excursiveart.deviantart.com/
// @description Provides a link on deviation thumbnails to download the highest resolution image and the html page of the deviation.
// @include     http://*.deviantart.com/*
// @include     https://*.deviantart.com/*
// @version     1
// @grant       GM_xmlhttpRequest
// @grant       GM_openInTab
// @require     https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js
// ==/UserScript==

var thumbs = document.evaluate('//div[contains(@class, "zones-container")]//a[@class="thumb"]',
                               document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);

// get the html of the deviation page
// we need to do this first because it provides the download token that
// deviantart requires to download the original image
function downloadDeviationPage(pageURL) {
  GM_xmlhttpRequest({
    method: "GET",
    url: pageURL,
    onload: function(response) {
      downloadDeviation(response.responseText, pageURL);
    }
  });
}

// download the largest resolution image available given the deviation page html
function downloadDeviation(pageHTML, pageURL) {
  var parsedHTML = $(pageHTML);
  var url;
  
  var dlOrigLink = parsedHTML.find('a[data-download_url]');
  if (dlOrigLink.length === 1) {
    // allows downloading of original file
    url = dlOrigLink.attr('href');
  } else {
    // does not allow downloading of original, so get the largest view size
    var largestView = parsedHTML.find('.dev-content-full');
    if (largestView.length === 1) {
      url = largestView.attr('src');
    }
  }
  
  if (!url) {
    alert('an error occurred');
    return false;
  }
  
  GM_openInTab(url);
  
  // download html page
  var tempLink = document.createElement('a');
  tempLink.download = pageURL;
  tempLink.href = window.URL.createObjectURL(new Blob([pageHTML], {type: 'text/html'}));
  //tempLink.type = 'text/html';
  document.body.appendChild(tempLink);
  tempLink.click();
  document.body.removeChild(tempLink);
}

for (var i = 0; i < thumbs.snapshotLength; i++) {
  var thumb = thumbs.snapshotItem(i);
  var dlink = document.createElement('a');
  dlink.href = thumb.href;
  dlink.onclick = function(e) {e.stopPropagation(); downloadDeviationPage(this.href); return false;};
  dlink.style.position = 'absolute';
  dlink.style.top = '0px';
  dlink.style.left = '8px';
  dlink.style.color = 'white';
  dlink.style.fontSize = '20px';
  dlink.style.textShadow = '0px 0px 1px black';
  dlink.innerHTML = '(\u25BC)';
  thumb.appendChild(dlink);
}