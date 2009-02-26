// Locatable - W3C Geolocation API for iPhone/iPod Touch
// Copyright (C) 2008 Wes Biggs <wes@tralfamadore.com>
// Version 0.2 - for latest see http://lbs.tralfamadore.com/w3c-api.js

 var Locatable = {
  'getCurrentPosition': function(successCallback, errorCallback, positionOptions) {
  // Note: options are ignored currently
  var lframe = document.getElementById('locatable');
  if (lframe != null) {
    document.body.removeChild(lframe);
  }

  // Load frame dynamically
  lframe = document.createElement('iframe');
  lframe.setAttribute('name', 'locatable');
  lframe.setAttribute('id', 'locatable');
  lframe.style.border='0px';
  lframe.style.width='0px';
  lframe.style.height='0px';
  lframe.setAttribute('src',
  'http://lbs.tralfamadore.com/i?u=' +
    encodeURIComponent(window.location.href));
  document.body.appendChild(lframe);
  Locatable._get(successCallback, errorCallback);
},
  '_get': function(successCallback, errorCallback) {
  // Wait for it to load
  var commframe = window.frames['locatable'].frames['commlink'];
  if (commframe == null) {
    // Wait for it
    setTimeout('Locatable._get(' + successCallback + ',' + errorCallback + ')', 50);
    return;
  }
  var result = null;
  try {
    result = commframe.location.hash;
  } catch (e) {
    // keep it null
  }
  if (result == null) {
    setTimeout('Locatable._get(' + successCallback + ',' + errorCallback + ')', 50);
    return;
  }
  result = result.substring(1).split(',');
  if (result[0] == 'E') {
    errorCallback({ "code": result[1], "message": result[2] });
  } else {
    var position = ({ 
    "latitude": result[0], 
    "longitude": result[1],
    "accuracy": result[2], 
    "altitude": null,
    "altitudeAccuracy": null,
    "heading": null,
    "velocity": null,
    "timestamp": new Date() // FIXME
    });
    Locatable.lastPosition = position;
    successCallback(position);
  }
},
  'lastPosition': null,
  // Note: watch functions do not generate more than one callback
  'watchPosition': function(successCallback, errorCallback, positionOptions) {
    Locatable.getCurrentPosition(successCallback, errorCallback, positionOptions);
    return 1;
  },
  'clearWatch': function(watchId) { },
  'isEnabled': function() {
    return (navigator.userAgent.indexOf('iPhone') != -1);
  }
 };
