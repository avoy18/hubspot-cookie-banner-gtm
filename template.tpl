// var log = require('logToConsole');
var callInWindow = require("callInWindow");
var createQueue = require("createQueue");
var setDefaultConsentState = require("setDefaultConsentState");
var gtagSet = require('gtagSet');
var updateConsentState = require("updateConsentState");
var getCookieValues = require("getCookieValues");
var defaultConsentSettings = data.defaultConsentSettings;
var consentModeEnabled = data.consentModeEnabled;

// Default consent state is set to denied for everything
var theConsentState = {
  ad_storage: "denied",
  analytics_storage: "denied",
  ad_user_data: "denied",
  personalization_storage: "denied",
  ad_personalization: "denied",
  functionality_storage: "granted",
  security_storage: "granted"
};

var dataLayerPush = createQueue('dataLayer');

/**
 * Splits the input in a correct way to parse the cookie data
 */
var splitCookieInput = function (input) {
  input = typeof input === "undefined" ? "" : input;
  return input
    .split("_")
    .map(function (entry) {
      return entry.trim().split(":")[1] || "false";
    })
    .filter(function (entry) {
      return entry.length !== 0;
    });
};

/**
 * Splits the input string using comma as a delimiter, returning an array of strings
 */
var splitInput = function (input) {
  return input.split(',')
      .map(entry => entry.trim())
      .filter(entry => entry.length !== 0);
};

var updateConsentObject = function () {
  var currentCookieValues = splitCookieInput(
    getCookieValues("__hs_cookie_cat_pref")[0]
  );

  theConsentState.analytics_storage =
    currentCookieValues[0] === "true" ? "granted" : theConsentState.analytics_storage;
  theConsentState.ad_user_data =
    currentCookieValues[0] === "true" ? "granted" : theConsentState.ad_user_data;
  theConsentState.personalization_storage =
    currentCookieValues[0] === "true" ? "granted" : theConsentState.personalization_storage;
  theConsentState.ad_personalization =
    currentCookieValues[0] === "true" ? "granted" : theConsentState.ad_personalization;
  theConsentState.ad_storage =
    currentCookieValues[1] === "true" ? "granted" : theConsentState.ad_storage;

  return {
    ad_storage: settings.ad_storage,
    ad_user_data: settings.ad_user_data,
    analytics_storage: settings.analytics_storage,
    personalization_storage: settings.personalization_storage,
    ad_personalization: settings.ad_personalization,
    functionality_storage: theConsentState.functionality_storage,
    security_storage: theConsentState.security_storage
  };
};

if (consentModeEnabled !== false) {

  // Set default consent state
  if(defaultConsentSettings){

    for(var i = 0; i < defaultConsentSettings.length; i++) {
      var settings = defaultConsentSettings[i];

      var defaultData = {
        ad_storage: settings.ad_storage,
        ad_user_data: settings.ad_user_data,
        analytics_storage: settings.analytics_storage,
        personalization_storage: settings.personalization_storage,
        ad_personalization: settings.ad_personalization,
        functionality_storage: theConsentState.functionality_storage,
        security_storage: theConsentState.security_storage,
      };

      if(typeof settings.region === 'string' && settings.region.trim().length > 0){
        defaultData.region = splitInput(settings.region);
      }else{
        theConsentState = defaultData; // only set default for no region
      }

      defaultData.wait_for_update = 500;

      setDefaultConsentState(defaultData);
    }
  }else{
    var defaultData = {
      ad_storage: theConsentState.ad_storage,
      analytics_storage: theConsentState.analytics_storage,
      ad_user_data: theConsentState.ad_user_data,
      personalization_storage: theConsentState.personalization_storage,
      ad_personalization: theConsentState.ad_personalization,
      functionality_storage: theConsentState.functionality_storage,
      security_storage: theConsentState.security_storage,
      wait_for_update: 500
    };
    setDefaultConsentState(defaultData);
  }

  if(data.ads_data_redaction){
    gtagSet('ads_data_redaction', data.ads_data_redaction);
  }

  if(data.url_passthrough){
    gtagSet('url_passthrough', data.url_passthrough);
  }

  // Add an event listener to HubSpot's consent change
  callInWindow("_hsp.push", [
    "addPrivacyConsentListener",
    function () {
      updateConsentState(updateConsentObject());
      
      dataLayerPush({'event': 'cookie_consent_update'});
    },
  ]);
}

// Call data.gtmOnSuccess when the tag is finished.
data.gtmOnSuccess();
