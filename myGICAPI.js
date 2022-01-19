var _error="";
var _fname=null;

try {gICAPI} catch (msg) {
  gICAPI={};
}

onICHostReady =function(version) { 
  //alert("here");
  gICAPI.onFocus=function(focusIn) {
  }
                                
  gICAPI.onData=function(data) {
    //mylog("gICAPI.onData:"+data);
  }

  gICAPI.onProperty=function(p) { 
    //mylog("gICAPI.onProperty:"+p);
    //var props = eval('(' + p + ')');
  } 
}
document.addEventListener('webviewerloaded', function (document) {
  console.log('webviewerloaded');
  try { PDFViewerApplicationOptions.set("defaultUrl",_fname) } catch (err) {
   console.log("cant reset defaultUrl: "+err.message);
  }
}, false);
/*
document.addEventListener("pagesloaded", function(e){
  console.log("pagesloaded");
  gICAPI.Action("pagerendered");  
});

document.addEventListener("pagerendered", function(e){
  console.log("pagerendered");
  gICAPI.Action("pagerendered");  
});

document.addEventListener('textlayerrendered', function (e) {
  console.log("pagerendered");
  gICAPI.Action("pagerendered");  
}, true);
*/

function displayPDF(fname) {
  console.log("displayPDF "+fname);
  _fname=fname;
  setTimeout( function() {
  try {
    console.log("open "+fname);
    PDFViewerApplication.open(fname);
    return true;
  } catch(err) { 
    _error=_error + " displayPDF:" + err.message;
    setTimeout( function() {
      gICAPI.Action("error");
    }, 100);
    return false;
  }
  } , 50);
}

function getAuthor()
{
  if (!window.PDFViewerApplication || !PDFViewerApplication.documentInfo) {
    return "empty";
  }
  return PDFViewerApplication.documentInfo.Author;
}

function getCreator()
{
  if (!window.PDFViewerApplication || !PDFViewerApplication.documentInfo) {
    return "empty";
  }
  return PDFViewerApplication.documentInfo.Creator;
}

function getError() {
  return _error;
}

function getUrl() {
  return window.location.href;
}
