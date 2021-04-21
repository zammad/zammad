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

  // i18n
  test('i18n', function() {

    // de
    App.i18n.set('de-de')
    var translated = App.i18n.translateContent('yes')
    equal(translated, 'ja', 'de-de - yes / ja translated correctly')

    translated = App.i18n.translatePlain('yes')
    equal(translated, 'ja', 'de-de - yes / ja translated correctly')

    translated = App.i18n.translateInline('yes')
    equal(translated, 'ja', 'de-de - yes / ja translated correctly')

    translated = App.i18n.translateContent('%s ago', 123);
    equal(translated, 'vor 123', 'de-de - %s')

    translated = App.i18n.translateContent('%s ago', '<b>quote</b>')
    equal(translated, 'vor &lt;b&gt;quote&lt;/b&gt;', 'de-de - %s - quote')

    translated = App.i18n.translateContent('%s %s test', 123, 'xxx |B|')
    equal(translated, '123 xxx |B| test', 'de-de - %s %s')

    translated = App.i18n.translateContent('|%s| %s test', 123, 'xxx')
    equal(translated, '<b>123</b> xxx test', 'de-de - *%s* %s')

    translated = App.i18n.translateContent('||%s|| %s test', 123, 'xxx')
    equal(translated, '<i>123</i> xxx test', 'de-de - *%s* %s')

    translated = App.i18n.translateContent('_%s_ %s test', 123, 'xxx')
    equal(translated, '<u>123</u> xxx test', 'de-de - _%s_ %s')

    translated = App.i18n.translateContent('§%s§ %s test', 123, 'xxx')
    equal(translated, '<kbd>123</kbd> xxx test', 'de-de - §%s§ %s')

    translated = App.i18n.translateContent('//%s// %s test', 123, 'xxx')
    equal(translated, '<del>123</del> xxx test', 'de-de - //%s// %s')

    translated = App.i18n.translateContent('\'%s\' %s test', 123, 'xxx')
    equal(translated, '&#39;123&#39; xxx test', 'de-de - \'%s\' %s')

    translated = App.i18n.translateContent('<test&now>//*äöüß')
    equal(translated, '&lt;test&amp;now&gt;//*äöüß', 'de - <test&now>//*äöüß')

    translated = App.i18n.translateContent('some link [to what ever](http://lalala)')
    equal(translated, 'some link <a href="http://lalala" target="_blank">to what ever</a>', 'de-de - link')

    translated = App.i18n.translateContent('some link [to what ever](%s)', 'http://lalala')
    equal(translated, 'some link <a href="http://lalala" target="_blank">to what ever</a>', 'de-de - link')

    translated = App.i18n.translateContent('Enables user authentication via %s. Register your app first at [%s](%s).', 'XXX', 'YYY', 'http://lalala')
    equal(translated, 'Aktivieren der Benutzeranmeldung über XXX. Registriere Deine Anwendung zuerst über <a href="http://lalala" target="_blank">YYY</a>.', 'en-us - link')

    var time_local = new Date();
    var offset = time_local.getTimezoneOffset();
    var timestamp = App.i18n.translateTimestamp('2012-11-06T21:07:24Z', offset);
    equal(timestamp, '06.11.2012 21:07', 'de-de - timestamp translated correctly')

    var timestamp = App.i18n.translateTimestamp('2021-02-08 09:13:20 UTC', offset);
    equal(timestamp, '08.02.2021 09:13', 'de-de - timestamp translated correctly with UTC format')

    timestamp = App.i18n.translateTimestamp('', offset);
    equal(timestamp, '', 'de-de - timestamp translated correctly')

    timestamp = App.i18n.translateTimestamp(null, offset);
    equal(timestamp, null, 'de-de - timestamp translated correctly')

    timestamp = App.i18n.translateTimestamp(undefined, offset);
    equal(timestamp, undefined, 'de-de - timestamp translated correctly')

    var date = App.i18n.translateDate('2012-11-06', 0)
    equal(date, '06.11.2012', 'de-de - date translated correctly')

    date = App.i18n.translateDate('', 0)
    equal(date, '', 'de-de - date translated correctly')

    date = App.i18n.translateDate(null, 0)
    equal(date, null, 'de-de - date translated correctly')

    date = App.i18n.translateDate(undefined, 0)
    equal(date, undefined, 'de-de - date translated correctly')

    // en
    App.i18n.set('en-us')
    translated = App.i18n.translateContent('yes')
    equal(translated, 'yes', 'en-us - yes translated correctly')

    translated = App.i18n.translatePlain('yes')
    equal(translated, 'yes', 'en-us - yes translated correctly')

    translated = App.i18n.translateInline('yes')
    equal(translated, 'yes', 'en-us - yes translated correctly')

    translated = App.i18n.translateContent('%s ago', 123);
    equal(translated, '123 ago', 'en-us - %s')

    translated = App.i18n.translateContent('%s ago', '<b>quote</b>')
    equal(translated, '&lt;b&gt;quote&lt;/b&gt; ago', 'en-us - %s - qupte')

    translated = App.i18n.translateContent('%s %s test', 123, 'xxx')
    equal(translated, '123 xxx test', 'en-us - %s %s')

    translated = App.i18n.translateContent('|%s| %s test', 123, 'xxx |B|')
    equal(translated, '<b>123</b> xxx |B| test', 'en-us - *%s* %s')

    translated = App.i18n.translateContent('||%s|| %s test', 123, 'xxx')
    equal(translated, '<i>123</i> xxx test', 'en-us - *%s* %s')

    translated = App.i18n.translateContent('_%s_ %s test', 123, 'xxx')
    equal(translated, '<u>123</u> xxx test', 'en-us - _%s_ %s')

    translated = App.i18n.translateContent('§%s§ %s test', 123, 'xxx')
    equal(translated, '<kbd>123</kbd> xxx test', 'en-us - §%s§ %s')

    translated = App.i18n.translateContent('Here you can search for tickets, customers and organizations. Use the wildcard §*§ to find everything. E. g. §smi*§ or §rosent*l§. You also can use ||double quotes|| for searching phrases §"some phrase"§.')
    equal(translated, 'Here you can search for tickets, customers and organizations. Use the wildcard <kbd>*</kbd> to find everything. E. g. <kbd>smi*</kbd> or <kbd>rosent*l</kbd>. You also can use <i>double quotes</i> for searching phrases <kbd>&quot;some phrase&quot;</kbd>.', 'en-us - §§ §§ §§ || §§')

    translated = App.i18n.translateContent('//%s// %s test', 123, 'xxx')
    equal(translated, '<del>123</del> xxx test', 'en-us - //%s// %s')

    translated = App.i18n.translateContent('\'%s\' %s test', 123, 'xxx')
    equal(translated, '&#39;123&#39; xxx test', 'en-us - \'%s\' %s')

    translated = App.i18n.translateContent('<test&now>')
    equal(translated, '&lt;test&amp;now&gt;', 'en-us - <test&now>')

    translated = App.i18n.translateContent('some link [to what ever](http://lalala)')
    equal(translated, 'some link <a href="http://lalala" target="_blank">to what ever</a>', 'en-us - link')

    translated = App.i18n.translateContent('some link [to what ever](%s)', 'http://lalala')
    equal(translated, 'some link <a href="http://lalala" target="_blank">to what ever</a>', 'en-us - link')

    translated = App.i18n.translateContent('Enables user authentication via %s. Register your app first at [%s](%s).', 'XXX', 'YYY', 'http://lalala')
    equal(translated, 'Enables user authentication via XXX. Register your app first at <a href="http://lalala" target="_blank">YYY</a>.', 'en-us - link')

    timestamp = App.i18n.translateTimestamp('2012-11-06T21:07:24Z', offset)
    equal(timestamp, '11/06/2012 21:07', 'en - timestamp translated correctly')

    timestamp = App.i18n.translateTimestamp('', offset);
    equal(timestamp, '', 'en - timestamp translated correctly')

    timestamp = App.i18n.translateTimestamp(null, offset);
    equal(timestamp, null, 'en - timestamp translated correctly')

    timestamp = App.i18n.translateTimestamp(undefined, offset);
    equal(timestamp, undefined, 'en - timestamp translated correctly')

    date = App.i18n.translateDate('2012-11-06', 0)
    equal(date, '11/06/2012', 'en - date translated correctly')

    date = App.i18n.translateDate('', 0)
    equal(date, '', 'en - date translated correctly')

    date = App.i18n.translateDate(null, 0)
    equal(date, null, 'en - date translated correctly')

    date = App.i18n.translateDate(undefined, 0)
    equal(date, undefined, 'en - date translated correctly')

    // locale alias test
    // de
    App.i18n.set('de')
    var translated = App.i18n.translateContent('yes')
    equal(translated, 'ja', 'de - yes / ja translated correctly')

    // locale detection test
    // de-ch
    App.i18n.set('de-ch')
    var translated = App.i18n.translateContent('yes')
    equal(translated, 'ja', 'de - yes / ja translated correctly')
  });
})
