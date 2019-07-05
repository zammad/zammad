window.onload = function() {

// ajax
App.Ajax.request({
  type:  'GET',
  url:   '/assets/tests/ajax-test.json',
  success: function (data) {
    test( "ajax get 200", function() {
      ok( true, "File found!")
      equal(data.success, true, "content parsable and ok!")
      equal(data.success2, undefined, "content parsable and ok!")
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!")
    });
  }
});

// ajax queueing
App.Ajax.request({
  type:  'GET',
  url:   '/tests/wait/2',
  queue: true,
  success: function (data) {
    test( "ajax - queue - ajax get 200 1/2", function() {

      // check queue
      ok( !window.testAjax, 'ajax - queue - check queue')
      window.testAjax = true;
      equal(data.success, true, "ajax - queue - content parsable and ok!")
      equal(data.success2, undefined, "ajax - queue - content parsable and ok!")
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!")
    });
  }
});
App.Ajax.request({
  type:  'GET',
  url:   '/tests/wait/1',
  queue: true,
  success: function (data) {
    test( "ajax - queue - ajax get 200 2/2", function() {
      // check queue
      ok( window.testAjax, 'ajax - queue - check queue')
      window.testAjax = undefined;

      equal(data.success, true, "content parsable and ok!")
      equal(data.success2, undefined, "content parsable and ok!")
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!")
    });
  }
});

// ajax parallel
App.Ajax.request({
  type:  'GET',
  url:   '/tests/wait/3',
  success: function (data) {
    test( "ajax - parallel - ajax get 200 1/2", function() {

      // check queue
      ok( window.testAjaxQ, 'ajax - parallel - check queue')
      window.testAjaxQ = undefined;
      equal(data.success, true, "ajax - parallel - content parsable and ok!")
      equal(data.success2, undefined, "ajax - parallel - content parsable and ok!")
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!")
    });
  }
});
App.Ajax.request({
  type:  'GET',
  url:   '/tests/wait/1',
  success: function (data) {
    test( "ajax - parallel - ajax get 200 2/2", function() {
      // check queue
      ok( !window.testAjaxQ, 'ajax - parallel - check queue')
      window.testAjaxQ = true;

      equal(data.success, true, "content parsable and ok!")
      equal(data.success2, undefined, "content parsable and ok!")
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!")
    });
  }
});

// delay
window.testDelay1 = false
App.Delay.set(function() {
    test('delay - test 1 - 1/3 - should not be executed, will be reset by next set()', function() {

      // check
      ok(false, 'delay - test 1 - 1/3 - should not be executed, will be reset by next set()')
      window.testDelay1 = true;
    });
  },
  1000,
  'delay-test1',
  'level'
);
App.Delay.set(function() {
    test('delay - test 1 - 2/3', function() {

      // check
      ok(!window.testDelay1, 'delay - test 1 - 2/3')
      window.testDelay1 = 1;
    });
  },
  2000,
  'delay-test1',
  'level'
);
App.Delay.set(function() {
    test('delay - test 1 - 2/3', function() {

      // check
      ok(window.testDelay1, 'delay - test 1 - 2/3')
      window.testDelay1 = false;
    });
  },
  3000,
  'delay-test1-verify',
  'level'
);

App.Delay.set(function() {
    test('delay - test 2 - 1/3', function() {

      // check
      ok(!window.testDelay2, 'delay - test 2 - 1/3')
      window.testDelay2 = 1;
    });
  },
  2000
);
App.Delay.set(function() {
    test('delay - test 2 - 2/3', function() {

      // check
      ok(!window.testDelay2, 'delay - test 2 - 2/3')
    });
  },
  1000
);
App.Delay.set(function() {
    test('delay - test 2 - 3/3', function() {

      // check
      ok(window.testDelay2, 'delay - test 2 - 3/3')
    });
  },
  3000
);

window.testDelay3 = 1;
App.Delay.set(function() {
    test('delay - test 3 - 1/1', function() {

      // check
      ok(false, 'delay - test 3 - 1/1')
    });
  },
  1000,
  'delay3'
);
App.Delay.clear('delay3')

App.Delay.set(function() {
    test('delay - test 4 - 1/1', function() {

      // check
      ok(false, 'delay - test 4 - 1/1')
    });
  },
  1000,
  undefined,
  'Page'
);
App.Delay.clearLevel('Page')


// interval 1
window.testInterval1 = 1
App.Interval.set(function() {
    window.testInterval1 += 1;
  },
  2000,
  'interval-test1'
);
App.Delay.set(function() {
    test('interval - test 1 - 1/2', function() {

      // check
      equal(window.testInterval1, 4, 'interval - test 1')
      App.Interval.clear('interval-test1')
    });
  },
  5200
);
App.Delay.set(function() {
    test('interval - test 1 - 2/2', function() {

      // check
      equal(window.testInterval1, 4, 'interval - test after clear')
    });
  },
  6500
);


// interval 2
window.testInterval2 = 1
App.Interval.set(function() {
    window.testInterval2 += 1;
  },
  2000,
  undefined,
  'someLevel'
);
App.Delay.set(function() {
    test('interval - test 2 - 1/2', function() {

      // check
      equal(window.testInterval2, 4, 'interval - test 2')
      App.Interval.clearLevel('someLevel')
    });
  },
  5200
);
App.Delay.set(function() {
    test('interval - test 2 - 2/2', function() {

      // check
      equal(window.testInterval2, 4, 'interval - test 2 - after clear')
    });
  },
  6900
);


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

// events
test('events simple', function() {

  // single bind
  App.Event.bind('test1', function(data) {
    ok(true, 'event received - single bind')
    equal(data.success, true, 'event received - data ok - single bind')
  });
  App.Event.bind('test2', function(data) {
    ok(false, 'should not be triggered - single bind')
  });
  App.Event.trigger('test1', { success: true })

  App.Event.unbind('test1')
  App.Event.bind('test1', function(data) {
    ok(false, 'should not be triggered - single bind')
  });
  App.Event.unbind('test1')
  App.Event.trigger('test1', { success: true })

  // multi bind
  App.Event.bind('test1-1 test1-2', function(data) {
    ok(true, 'event received - multi bind')
    equal(data.success, true, 'event received - data ok - multi bind')
  });
  App.Event.bind('test1-3', function(data) {
    ok(false, 'should not be triggered - multi bind')
  });
  App.Event.trigger('test1-2', { success: true })

  App.Event.unbind('test1-1')
  App.Event.bind('test1-1', function(data) {
    ok(false, 'should not be triggered - multi bind')
  });
  App.Event.trigger('test1-2', { success: true })
});

test('events level', function() {

  // bind with level
  App.Event.bind('test3', function(data) {
    ok(false, 'should not be triggered!')
  }, 'test-level')

  // unbind with level
  App.Event.unbindLevel( 'test-level')

  // bind with level
  App.Event.bind('test3', function(data) {
    ok(true, 'event received')
    equal(data.success, true, 'event received - data ok - level bind')
  }, 'test-level')
  App.Event.trigger('test3', { success: true})

});

// session store
test('session store', function() {

  var tests = [
    'some 123äöüßadajsdaiosjdiaoidj',
    { key: 123 },
    { key1: { key1: [1,2,3,4] }, key2: [1,2,'äöüß'] },
  ];

  // write/get
  App.SessionStorage.clear()
  _.each(tests, function(test) {
    App.SessionStorage.set('test1', test)
    var item = App.SessionStorage.get('test1')
    deepEqual(test, item, 'write/get - compare stored and actual data')
  });

  // undefined/get
  App.SessionStorage.clear()
  _.each(tests, function(test) {
    var item = App.SessionStorage.get('test1')
    deepEqual(undefined, item, 'undefined/get - compare not existing data and actual data')
  });

  // write/get/delete
  var tests = [
    { key: 'test1', value: 'some 123äöüßadajsdaiosjdiaoidj' },
    { key: 123, value: { a: 123, b: 'sdaad' } },
    { key: '123äöüß', value: { key1: [1,2,3,4] }, key2: [1,2,'äöüß'] },
  ];

  App.SessionStorage.clear()
  _.each(tests, function(test) {
    App.SessionStorage.set(test.key, test.value)
  });

  _.each(tests, function(test) {
    var item = App.SessionStorage.get(test.key)
    deepEqual(test.value, item, 'write/get/delete - compare stored and actual data')
    App.SessionStorage.delete( test.key)
    item = App.SessionStorage.get(test.key)
    deepEqual(undefined, item, 'write/get/delete - compare deleted data')
  });

});

// config
test('config', function() {

  // simple
  var tests = [
    { key: 'test1', value: 'some 123äöüßadajsdaiosjdiaoidj' },
    { key: 123, value: { a: 123, b: 'sdaad' } },
    { key: '123äöüß', value: { key1: [1,2,3,4] }, key2: [1,2,'äöüß'] },
  ];

  _.each(tests, function(test) {
    App.Config.set(test.key, test.value )
  });

  _.each(tests, function(test) {
    var item = App.Config.get(test.key )
    deepEqual(item, test.value, 'set/get tests')
  });

  // group
  var test_groups = [
    { key: 'test2', value: [ 'some 123äöüßadajsdaiosjdiaoidj' ] },
    { key: 1234, value: { a: 123, b: 'sdaad' } },
    { key: '123äöüß', value: { key1: [1,2,3,4,5,6] }, key2: [1,2,'äöüß'] },
  ];
  var group = {};
  _.each(test_groups, function(test) {
    App.Config.set(test.key, test.value, 'group1')
    group[test.key] = test.value
  });

  // verify whole group
  var item = App.Config.get('group1')
  deepEqual(item, group, 'group - verify group hash')

  // verify each setting
  _.each(test_groups, function(test) {
    var item = App.Config.get(test.key, 'group1')
    deepEqual(item, test.value, 'group set/get tests')
  });
});


// clone
test('clone', function() {

  // simple
  var tests = [
    {
      key1: 123,
      key2: 1234
    },
    {
      key1: 123,
      key2: '1234'
    },
    [1,2,4,5,6],
    'some string äöü',
    {
      key1: 123,
      key2: null,
    },
    {
      key1: 123,
      key2: undefined,
    },
    {
      key1: 123,
      key2: undefined,
      key3: {
        keya: 'some',
        keyb: undefined,
      },
      key4: ['a', 'b', null, false, true, undefined],
    },
    undefined,
    false,
    true,
    null,
    {
      key1: 123,
      key2: undefined,
      key3: {
        keya: 'some',
        keyb: undefined,
      },
      key4: ['a', 'b', {
        a: 123,
        b: [1,5,7,8,1213,1231321]
      }],
    },
  ];

  _.each(tests, function(test) {
    var item = clone( test )
    deepEqual(item, test, 'clone')
  });

  // complex test
  var source = [
    { name: 'some name' },
    { name: 'some name2' },
    { fn: function() { return 'test' } },
  ]
  var reference = [
    { name: 'some name' },
    { name: 'some name2' },
    { fn: undefined },
  ]
  var result = clone( source )

  // modify source later, should not have any result
  source[0].name = 'some new name'

  deepEqual(result, reference, 'clone')

  // full test
  var source = [
    { name: 'some name' },
    { name: 'some name2' },
    { fn: function a() { return 'test' } },
  ]
  var reference = [
    { name: 'some name' },
    { name: 'some name2' },
    { fn: function a() { return 'test' } },
  ]
  var result = clone( source, true )

  // modify source later, should not have any result
  source[0].name = 'some new name'
  source[2].fn   = 'some new name'

  deepEqual(result[0], reference[0], 'clone full')
  deepEqual(result[1], reference[1], 'clone full')

  equal(typeof reference[2].fn, 'function')
  equal(typeof result[2].fn, 'function')

  equal(reference[2].fn(), 'test')
  equal(result[2].fn(), 'test')

});

// diff
test('difference', function() {

  // simple
  var object1 = {
    key1: 123,
    key2: 1234
  }
  var object2 = {
    key1: 123,
    key2: 1235
  }
  var result = {
    key2: 1235
  }
  var item = difference(object1, object2)
  deepEqual(item, result)

  object1 = {
    key1: 123,
    key2: 123
  }
  object2 = {
    key1: 123,
    key2: 123
  }
  result = {}
  item = difference(object1, object2)
  deepEqual(item, result)

  object1 = {
    key1: 123,
    key2: [1,3,5]
  }
  object2 = {
    key1: 123,
    key2: 123
  }
  result = {
    key2: 123
  }
  item = difference(object1, object2)
  deepEqual(item, result)

  object1 = {
    key1: 123,
    key2: [1,3,5]
  }
  object2 = {
    key1: 123,
  }
  result = {}
  item = difference(object1, object2)
  deepEqual(item, result)

  object1 = {
    key1: 123,
  }
  object2 = {
    key1: 123,
    key2: 124
  }
  result = {}
  item = difference(object1, object2)
  deepEqual(item, result)

  object1 = {
    customer_id: 1,
    organization_id: 2,
  }
  object2 = {
    customer_id: 1,
    organization_id: null,
  }
  result = {
    organization_id: null,
  }
  item = difference(object1, object2)
  deepEqual(item, result)

  object1 = {
    customer_id: 1,
    organization_id: null,
  }
  object2 = {
    customer_id: 1,
    organization_id: 2,
  }
  result = {
    organization_id: 2,
  }
  item = difference(object1, object2)
  deepEqual(item, result)

});

// auth
App.Auth.login({
  data: {
    username: 'not_existing',
    password: 'not_existing',
  },
  success: function(data) {
    test('auth - not existing user', function() {
      ok(false, 'ok')
    })
  },
  error: function() {
    test('auth - not existing user', function() {
      ok(true, 'ok')
      authWithSession()
    })
  }
});

var authWithSession = function() {
  App.Auth.login({
    data: {
      username: 'nicole.braun@zammad.org',
      password: 'test',
    },
    success: function(data) {
      test('auth - existing user', function() {
        ok(true, 'authenticated')
        var user = App.Session.get('login')
        equal('nicole.braun@zammad.org', user, 'session login')
      })
    },
    error: function() {
      test('auth - existing user', function() {
        ok(false, 'not authenticated')
      })
    }
  });
}

}