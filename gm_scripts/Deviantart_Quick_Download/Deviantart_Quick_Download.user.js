// ==UserScript==
// @name        Deviantart Quick Download
// @namespace   https://github.com/excursive
// @description Provides a link on deviation thumbnails to download the highest resolution image and the html page of the deviation.
// @include     http://*.deviantart.com/*
// @include     https://*.deviantart.com/*
// @version     1.1
// @grant       GM.xmlHttpRequest
// @grant       GM.openInTab
// @run-at      document-idle
// @require     https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js
// ==/UserScript==

var thumbs = document.evaluate('//div[contains(@class, "torpedo-container")]//a[contains(@class, "torpedo-thumb-link")]',
                               document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);

// get the html of the deviation page
// we need to do this first because it provides the download token that
// deviantart requires to download the original image
function downloadDeviationPage(pageURL) {
  GM.xmlHttpRequest({
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
  
  // get url of largest preview to determine image format and to download if downloading of original is not allowed
  var largestView = parsedHTML.find('img.dev-content-full');
  if (largestView.length !== 1) {
    alert('error: could not find large preview.');
    return false;
  }
  var largestViewURL = largestView.attr('src');
  
  var imgURL;
  var dlOrigLink = parsedHTML.find('a.dev-page-download, a[data-download_url]');
  if (dlOrigLink.length > 0) {
    // allows downloading of original file
    if (dlOrigLink.attr('data-download_url') && dlOrigLink.attr('data-download_url') === dlOrigLink.attr('href')) {
      imgURL = dlOrigLink.attr('data-download_url');
    } else {
      alert('error: download link mismatch');
    }
  } else {
    // does not allow downloading of original, so get the largest view size
    imgURL = largestViewURL;
  }
  
  if (!imgURL) {
    alert('error: could not get image url');
    return false;
  }
  
  var urlPart = pageURL.substring(pageURL.indexOf('deviantart.com/') + 15, pageURL.length);
  var deviant = urlPart.substring(0, urlPart.indexOf('/'));
  var deviationID = urlPart.substring(urlPart.lastIndexOf('-') + 1, urlPart.length);
  var deviationName = urlPart.substring(urlPart.lastIndexOf('/') + 1, urlPart.lastIndexOf('-'));
  var imgExt = largestViewURL.substring(largestViewURL.lastIndexOf('.'), largestViewURL.length);
  
  GM.openInTab(imgURL);
  
  // download html page
  var tempPageLink = document.createElement('a');
  tempPageLink.download = 'da_' + deviant + '_' + deviationID + '_' + deviationName + '.html';
  tempPageLink.href = window.URL.createObjectURL(new Blob([pageHTML], {type: 'text/html'}));
  document.body.appendChild(tempPageLink);
  tempPageLink.click();
  window.URL.revokeObjectURL(tempPageLink.href);
  document.body.removeChild(tempPageLink);
}
/*
function downloadDeviationImg(imgURL, deviant, deviationID, deviationName, imgExt) {
  GM.xmlHttpRequest({
    method: "GET",
    url: imgURL,
    //responseType: 'arraybuffer',
    //overrideMimeType: 'application/octet-stream',
    onload: function(response) {
      saveDeviationImg(response, deviant, deviationID, deviationName, imgExt);
    }
  });
}

function saveDeviationImg(response, deviant, deviationID, deviationName, imgExt) {
  var tempImgLink = document.createElement('a');
  tempImgLink.download = 'da_' + deviant + '_' + deviationID + '_' + deviationName + imgExt;
  alert('hi');
  tempImgLink.href = window.URL.createObjectURL(new Blob(response.responseText, {type: 'application/octet-stream'}));
  alert('no');
  document.body.appendChild(tempImgLink);
  tempImgLink.click();
  window.URL.revokeObjectURL(tempImgLink.href);
  document.body.removeChild(tempImgLink);
}
*/
for (var i = 0; i < thumbs.snapshotLength; i++) {
  var thumb = thumbs.snapshotItem(i);
  var dlink = document.createElement('a');
  dlink.href = thumb.href;
  dlink.onclick = function(e) {e.stopPropagation(); downloadDeviationPage(this.href); return false;};
  dlink.style.position = 'absolute';
  dlink.style.top = '0px';
  dlink.style.left = '0px';
  dlink.style.padding = '20px 12px 28px';
  dlink.style.backgroundColor = 'gray';
  dlink.style.color = 'white';
  dlink.style.fontSize = '28px';
  dlink.style.textShadow = '0px 0px 2px black';
  dlink.innerHTML = '\u25BC';
  thumb.appendChild(dlink);
}
