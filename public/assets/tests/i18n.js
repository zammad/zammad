test('i18n .detectBrowserLocale', function() {
  var original_userLanguage = window.navigator.userLanguage
  var original_language     = window.navigator.language
  var original_languages    = window.navigator.languages

  var reset = function(){
    window.navigator.userLanguage = original_userLanguage
    window.navigator.language     = original_language
    window.navigator.languages    = original_languages
  }

  var mock = function(languages, language, userLanguage){
    Object.defineProperty(window.navigator, 'language', {value: language, configurable: true });
    Object.defineProperty(window.navigator, 'languages', {value: languages, configurable: true });
    Object.defineProperty(window.navigator, 'userLanguage', {value: userLanguage, configurable: true });
  }

  mock(undefined, undefined, undefined)
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(undefined, undefined, 'non-existant');
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(undefined, undefined, 'en');
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(undefined, undefined, 'lt');
  equal(App.i18n.detectBrowserLocale(), 'lt')

  mock(undefined, 'lt', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'lt')

  mock(undefined, 'en', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(['en'], 'lt', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(['en-us'], 'lt', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(['en-US'], 'lt', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(['lt', 'en-US'], 'lt', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'lt')

  mock(['en-GB', 'en-US'], 'lt', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'en-gb')

  mock(['en-XYZ'], 'lt', 'lv');
  equal(App.i18n.detectBrowserLocale(), 'en-us')

  mock(['xyz', 'lt'], 'lv', undefined);
  equal(App.i18n.detectBrowserLocale(), 'lt')

  reset()
})
