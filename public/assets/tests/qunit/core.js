QUnit.test( "ajax get 200", assert => {
  App.Config.set('api_path', '/api/v1')
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Ajax.request({
      type:  'GET',
      url:   '/assets/tests/ajax-test.json',
      success: resolve,
      error: reject
    });
  }).then( function(data) {
    assert.ok( true, "File found!")
    assert.equal(data.success, true, "content parsable and assert.ok!")
    assert.equal(data.success2, undefined, "content parsable and assert.ok!")
  }, function(data) {
    assert.ok( false, "Failed!")
  })
  .finally(done)
});

QUnit.test( "ajax - queue - ajax get 200 1/2", assert => {
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Ajax.request({
      type:  'GET',
      url:   '/tests/wait/2',
      queue: true,
      success: resolve,
      error: reject
    });
  }).then( function(data) {
    assert.ok( !window.testAjax, 'ajax - queue - check queue')
    window.testAjax = true;
    assert.equal(data.success, true, "ajax - queue - content parsable and assert.ok!")
    assert.equal(data.success2, undefined, "ajax - queue - content parsable and assert.ok!")
  }, function(data) {
    assert.ok( false, "Failed!")
  })
  .finally(done)
});

QUnit.test( "ajax - queue - ajax get 200 2/2", assert => {
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Ajax.request({
      type:  'GET',
      url:   '/tests/wait/1',
      queue: true,
      success: resolve,
      error: reject
    });
  }).then( function(data) {

    // check queue
    assert.ok( window.testAjax, 'ajax - queue - check queue')
    window.testAjax = undefined;

    assert.equal(data.success, true, "content parsable and assert.ok!")
    assert.equal(data.success2, undefined, "content parsable and assert.ok!")
  }, function(data) {
    assert.ok( false, "Failed!")
  })
  .finally(done)
});

QUnit.test( "ajax - parallel - ajax get 200", assert => {
  var done = assert.async(2)

  new Promise( (resolve, reject) => {
    App.Ajax.request({
      type:  'GET',
      url:   '/tests/wait/3',
      success: resolve,
      error: reject
    });

    new Promise( (resolve, reject) => {
      App.Ajax.request({
        type:  'GET',
        url:   '/tests/wait/1',
        success: resolve,
        error: reject
      });
    }).then( function(data) {

      // check queue
      assert.ok( !window.testAjaxQ, 'ajax - parallel - check queue')
      window.testAjaxQ = true;

      assert.equal(data.success, true, "content parsable and assert.ok!")
      assert.equal(data.success2, undefined, "content parsable and assert.ok!")
    }, function(data) {
      assert.ok( false, "Failed!")
    })
    .finally(done)
  }).then( function(data) {

    // check queue
    assert.ok( window.testAjaxQ, 'ajax - parallel - check queue')
    window.testAjaxQ = undefined;
    assert.equal(data.success, true, "ajax - parallel - content parsable and assert.ok!")
    assert.equal(data.success2, undefined, "ajax - parallel - content parsable and assert.ok!")
    done()
  }, function(data) {
    assert.ok( false, "Failed!")
  })
});

QUnit.test('delay - test', assert => {
  var done = assert.async(1)

  window.testDelay1 = false
  new Promise( (resolve, reject) => {
    App.Delay.set(resolve, 1000, 'delay-test1', 'level');

    new Promise( (resolve, reject) => {
      App.Delay.set(resolve, 2000, 'delay-test1', 'level');
    }).then( function() {
      assert.ok(!window.testDelay1, 'delay - 1/2')
      window.testDelay1 = 1;
    })

    new Promise( (resolve, reject) => {
      App.Delay.set(resolve, 3000, 'delay-test1-verify', 'level');
    }).then( function() {
      assert.ok(window.testDelay1, 'delay - 2/2')
      window.testDelay1 = false;
    })
    .finally(done)
  }).then( function() {
    assert.ok(false, 'delay - 1/2 - FAILED - should not be executed, will be reset by next set()')
    window.testDelay1 = true;
  })
});

QUnit.test('delay - test 2', assert => {
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Delay.set(resolve, 2000);

    new Promise( (resolve, reject) => {
      App.Delay.set(resolve, 1000);
    }).then( function() {
      assert.ok(!window.testDelay2, 'delay - test 2 - 1/3')
    })

    new Promise( (resolve, reject) => {
      App.Delay.set(resolve, 3000);
    }).then( function() {
      assert.ok(window.testDelay2, 'delay - test 2 - 3/3')
    })
    .finally(done)
  }).then( function() {
    assert.ok(!window.testDelay2, 'delay - test 2 - 2/3')
    window.testDelay2 = 1;
  })
});

QUnit.test('delay - test 3', assert => {
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Delay.set(resolve, 1000, 'delay3');
    App.Delay.clear('delay3')
    assert.ok(true, 'delay - test 3 - 1/1')
    done()
  }).then( function() {
    assert.ok(false, 'delay - test 3 - 1/1 - FAILED')
  })
});

QUnit.test('delay - test 4', assert => {
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Delay.set(resolve, 1000, undefined, 'Page');
    App.Delay.clearLevel('Page')
    assert.ok(true, 'delay - test 4 - 1/1')
    done()
  }).then( function() {
    assert.ok(false, 'delay - test 4 - 1/1 - FAILED')
  })
});

QUnit.test('interval - test 1', assert => {
  var done = assert.async(1)

  window.testInterval1 = 1
  App.Interval.set(function() {
      window.testInterval1 += 1;
    },
    100,
    'interval-test1'
  );

  new Promise( (resolve, reject) => {
    App.Delay.set(resolve, 1000);

    new Promise( (resolve, reject) => {
      App.Delay.set(resolve, 2000);
    }).then( function() {
      assert.equal(window.testInterval1, window.testInterval1Backup, 'interval - did not change after clear interval')
    })
    .finally(done)
  }).then( function() {
    assert.notEqual(window.testInterval1, 1, 'interval - interval moved up')
    App.Interval.clear('interval-test1')
    window.testInterval1Backup = window.testInterval1;
  })
})

QUnit.test('interval - test 2', assert => {
  var done = assert.async(1)

  window.testInterval1 = 1
  App.Interval.set(function() {
      window.testInterval1 += 1;
    },
    100,
    undefined,
    'someLevel'
  );

  new Promise( (resolve, reject) => {
    App.Delay.set(resolve, 1000);

    new Promise( (resolve, reject) => {
      App.Delay.set(resolve, 2000);
    }).then( function() {
      assert.equal(window.testInterval1, window.testInterval1Backup, 'interval - did not change after clear interval')
    })
    .finally(done)
  }).then( function() {
    assert.notEqual(window.testInterval1, 1, 'interval - interval moved up')
    App.Interval.clearLevel('someLevel')
    window.testInterval1Backup = window.testInterval1;
  })
})

// events
QUnit.test('events simple', assert => {

  // single bind
  App.Event.bind('test1', function(data) {
    assert.ok(true, 'event received - single bind')
    assert.equal(data.success, true, 'event received - data assert.ok - single bind')
  });
  App.Event.bind('test2', function(data) {
    assert.ok(false, 'should not be triggered - single bind')
  });
  App.Event.trigger('test1', { success: true })

  App.Event.unbind('test1')
  App.Event.bind('test1', function(data) {
    assert.ok(false, 'should not be triggered - single bind')
  });
  App.Event.unbind('test1')
  App.Event.trigger('test1', { success: true })

  // multi bind
  App.Event.bind('test1-1 test1-2', function(data) {
    assert.ok(true, 'event received - multi bind')
    assert.equal(data.success, true, 'event received - data assert.ok - multi bind')
  });
  App.Event.bind('test1-3', function(data) {
    assert.ok(false, 'should not be triggered - multi bind')
  });
  App.Event.trigger('test1-2', { success: true })

  App.Event.unbind('test1-1')
  App.Event.bind('test1-1', function(data) {
    assert.ok(false, 'should not be triggered - multi bind')
  });
  App.Event.trigger('test1-2', { success: true })
});

QUnit.test('events level', assert => {

  // bind with level
  App.Event.bind('test3', function(data) {
    assert.ok(false, 'should not be triggered!')
  }, 'test-level')

  // unbind with level
  App.Event.unbindLevel( 'test-level')

  // bind with level
  App.Event.bind('test3', function(data) {
    assert.ok(true, 'event received')
    assert.equal(data.success, true, 'event received - data assert.ok - level bind')
  }, 'test-level')
  App.Event.trigger('test3', { success: true})

});

// session store
QUnit.test('session store', assert => {

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
    assert.deepEqual(test, item, 'write/get - compare stored and actual data')
  });

  // undefined/get
  App.SessionStorage.clear()
  _.each(tests, function(test) {
    var item = App.SessionStorage.get('test1')
    assert.deepEqual(undefined, item, 'undefined/get - compare not existing data and actual data')
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
    assert.deepEqual(test.value, item, 'write/get/delete - compare stored and actual data')
    App.SessionStorage.delete( test.key)
    item = App.SessionStorage.get(test.key)
    assert.deepEqual(undefined, item, 'write/get/delete - compare deleted data')
  });

});

// config
QUnit.test('config', assert => {

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
    assert.deepEqual(item, test.value, 'set/get tests')
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
  assert.deepEqual(item, group, 'group - verify group hash')

  // verify each setting
  _.each(test_groups, function(test) {
    var item = App.Config.get(test.key, 'group1')
    assert.deepEqual(item, test.value, 'group set/get tests')
  });
});


// clone
QUnit.test('clone', assert => {

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
    assert.deepEqual(item, test, 'clone')
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

  assert.deepEqual(result, reference, 'clone')

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

  assert.deepEqual(result[0], reference[0], 'clone full')
  assert.deepEqual(result[1], reference[1], 'clone full')

  assert.equal(typeof reference[2].fn, 'function')
  assert.equal(typeof result[2].fn, 'function')

  assert.equal(reference[2].fn(), 'test')
  assert.equal(result[2].fn(), 'test')

});

 // diff
QUnit.test('difference', assert => {

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
  assert.deepEqual(item, result)

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
  assert.deepEqual(item, result)

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
  assert.deepEqual(item, result)

  object1 = {
    key1: 123,
    key2: [1,3,5]
  }
  object2 = {
    key1: 123,
  }
  result = {
    key2: undefined
  }
  item = difference(object1, object2)
  assert.deepEqual(item, result)

  object1 = {
    key1: 123,
  }
  object2 = {
    key1: 123,
    key2: 124
  }
  result = {
    key2: 124
  }
  item = difference(object1, object2)
  assert.deepEqual(item, result)

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
  assert.deepEqual(item, result)

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
  assert.deepEqual(item, result)

  object1 = {
    customer_id: 1,
    preferences: { resolved: true },
  }
  object2 = {
    customer_id: 1,
    preferences: {},
  }
  result = {
    preferences: { resolved: undefined }
  }
  item = difference(object1, object2)
  assert.deepEqual(item, result)

  object1 = {
    customer_id: 1,
  }
  object2 = {
    customer_id: 1,
    preferences: { resolved: true },
  }
  result = {
    preferences: { resolved: true }
  }
  item = difference(object1, object2)
  assert.deepEqual(item, result)

  object1 = {
    customer_id: 1,
    preferences: {},
  }
  object2 = {
    customer_id: 1,
    preferences: { resolved: true },
  }
  result = {
    preferences: { resolved: true }
  }
  item = difference(object1, object2)
  assert.deepEqual(item, result)

  object1 = {
    customer_id: 1,
    preferences: { resolved: false },
  }
  object2 = {
    customer_id: 1,
    preferences: { resolved: true },
  }
  result = {
    preferences: { resolved: true }
  }
  item = difference(object1, object2)
  assert.deepEqual(item, result)

  object1 = {
    customer_id: 1,
    preferences: { resolved: true },
  }
  object2 = {
    customer_id: 1,
    preferences: { resolved: true },
  }
  result = {}
  item = difference(object1, object2)
  assert.deepEqual(item, result)

  item = difference({}, undefined)
  assert.deepEqual(item, {})

  item = difference(undefined, {})
  assert.deepEqual(item, {})
});

QUnit.test('auth - not existing user', assert => {
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Auth.login({
      data: {
        username: 'not_existing',
        password: 'not_existing',
      },
      success: resolve,
      error: reject
    });
  }).then( function(data) {
    assert.ok(false, 'ok')
  }, function() {
    assert.ok(true, 'ok')
  })
  .finally(done)
})

QUnit.test('auth - existing user', assert => {
  App.Config.set('api_path', '/api/v1')
  var done = assert.async(1)

  new Promise( (resolve, reject) => {
    App.Auth.login({
      data: {
        username: 'admin@example.com',
        password: 'test',
      },
      success: resolve,
      error: reject
    });
  }).then( function(data) {
    assert.ok(true, 'authenticated')
    var user = App.Session.get('login')
    assert.equal('admin@example.com', user, 'session login')
  }, function() {
    assert.ok(false, 'failed')
  })
  .finally(done)
})
