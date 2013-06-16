
// ajax
App.Com.ajax({
  type:  'GET',
  url:   '/assets/tests/ajax-test.json',
  success: function (data) {
    test( "ajax get 200", function() {
      ok( true, "File found!" );
      equal( data.success, true, "content parsable and ok!" );
      equal( data.success2, undefined, "content parsable and ok!" );
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!" );
    });
  }
});

// ajax queueing
App.Com.ajax({
  type:  'GET',
  url:   '/test/wait/2',
  queue: true,
  success: function (data) {
    test( "ajax - queue - ajax get 200 1/2", function() {

      // check queue
      ok( !window.testAjax, 'ajax - queue - check queue' );
      window.testAjax = true;
      equal( data.success, true, "ajax - queue - content parsable and ok!" );
      equal( data.success2, undefined, "ajax - queue - content parsable and ok!" );
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!" );
    });
  }
});
App.Com.ajax({
  type:  'GET',
  url:   '/test/wait/1',
  queue: true,
  success: function (data) {
    test( "ajax - queue - ajax get 200 2/2", function() {
      // check queue
      ok( window.testAjax, 'ajax - queue - check queue' )
      window.testAjax = undefined;

      equal( data.success, true, "content parsable and ok!" );
      equal( data.success2, undefined, "content parsable and ok!" );
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!" );
    });
  }
});

// ajax parallel
App.Com.ajax({
  type:  'GET',
  url:   '/test/wait/2',
  success: function (data) {
    test( "ajax - parallel - ajax get 200 1/2", function() {

      // check queue
      ok( window.testAjaxQ, 'ajax - parallel - check queue' );
      window.testAjaxQ = undefined;
      equal( data.success, true, "ajax - parallel - content parsable and ok!" );
      equal( data.success2, undefined, "ajax - parallel - content parsable and ok!" );
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!" );
    });
  }
});
App.Com.ajax({
  type:  'GET',
  url:   '/test/wait/1',
  success: function (data) {
    test( "ajax - parallel - ajax get 200 2/2", function() {
      // check queue
      ok( !window.testAjaxQ, 'ajax - parallel - check queue' )
      window.testAjaxQ = true;

      equal( data.success, true, "content parsable and ok!" );
      equal( data.success2, undefined, "content parsable and ok!" );
    });
  },
  error: function (data) {
    test( "ajax", function() {
      ok( false, "Failed!" );
    });
  }
});

// delay
App.Delay.set( function() {
    test( "delay - test 1 - 1/2", function() {

      // check
      ok( !window.testDelay1, 'delay - test 1 - 1/2' );
      window.testDelay1 = true;
    });
  },
  1000,
  'delay-test1',
  'level'
);
App.Delay.set( function() {
    test( "delay - test 1 - 2/2", function() {

      // check
      ok( window.testDelay1, 'delay - test 1 - 2/2' );
      window.testDelay1 = 1;
    });
  },
  2000,
  'delay-test1',
  'level'
);

App.Delay.set( function() {
    test( "delay - test 2 - 1/3", function() {

      // check
      ok( !window.testDelay2, 'delay - test 2 - 1/3' );
      window.testDelay2 = 1;
    });
  },
  2000
);
App.Delay.set( function() {
    test( "delay - test 2 - 2/3", function() {

      // check
      ok( !window.testDelay2, 'delay - test 2 - 2/3' );
    });
  },
  1000
);
App.Delay.set( function() {
    test( "delay - test 2 - 3/3", function() {

      // check
      ok( window.testDelay2, 'delay - test 2 - 3/3' );
    });
  },
  3000
);

window.testDelay3 = 1;
App.Delay.set( function() {
    test( "delay - test 3 - 1/1", function() {

      // check
      ok( false, 'delay - test 3 - 1/1' );
    });
  },
  1000,
  'delay3'
);
App.Delay.clear('delay3')

App.Delay.set( function() {
    test( "delay - test 4 - 1/1", function() {

      // check
      ok( false, 'delay - test 4 - 1/1' );
    });
  },
  1000,
  undefined,
  'Page'
);
App.Delay.clearLevel('Page')


// interval 1
window.testInterval1 = 1
App.Interval.set( function() {
    window.testInterval1 += 1;
  },
  500,
  'interval-test1'
);
App.Delay.set( function() {
    test( "interval - test 1 - 1/1", function() {

      // check
      equal( window.testInterval1, 6, 'interval - test 1' );
      App.Interval.clear('interval-test1')
    });
  },
  2500
);
App.Delay.set( function() {
    test( "interval - test 1 - 1/1", function() {

      // check
      equal( window.testInterval1, 6, 'interval - test after clear' );
    });
  },
  3500
);


// interval 2
window.testInterval2 = 1
App.Interval.set( function() {
    window.testInterval2 += 1;
  },
  500,
  undefined,
  'page'
);
App.Delay.set( function() {
    test( "interval - test 2 - 1/1", function() {

      // check
      equal( window.testInterval2, 6, 'interval - test 2' );
      App.Interval.clearLevel('page')
    });
  },
  2500
);
App.Delay.set( function() {
    test( "interval - test 2 - 1/1", function() {

      // check
      equal( window.testInterval2, 6, 'interval - test 2 - after clear' );
    });
  },
  3500
);


// i18n
test( "i18n", function() {

  // de
  App.i18n.set('de');
  var translated = App.i18n.translateContent('yes');
  equal( translated, 'ja', 'de - yes / ja translated correctly' );

  translated = App.i18n.translateContent('<test&now>//*äöüß');
  equal( translated, '&lt;test&amp;now&gt;//*äöüß', 'de - <test&now>//*äöüß' );

  var timestamp = App.i18n.translateTimestamp('2012-11-06T21:07:24Z');
  equal( timestamp, '06.11.2012 22:07', 'de - timestamp translated correctly' );

  // en
  App.i18n.set('en');
  translated = App.i18n.translateContent('yes');
  equal( translated, 'yes', 'en - yes translated correctly' );

  translated = App.i18n.translateContent('<test&now>');
  equal( translated, '&lt;test&amp;now&gt;', 'en - <test&now>' );

  timestamp = App.i18n.translateTimestamp('2012-11-06T21:07:24Z');
  equal( timestamp, '2012-11-06 22:07', 'en - timestamp translated correctly' );
});

// events
test( "events simple", function() {

  // single bind
  App.Event.bind( 'test1', function(data) {
    ok( true, 'event received - single bind');
    equal( data.success, true, 'event received - data ok - single bind');
  });
  App.Event.bind( 'test2', function(data) {
    ok( false, 'should not be triggered - single bind');
  });
  App.Event.trigger( 'test1', { success: true } );

  App.Event.unbind( 'test1')
  App.Event.bind( 'test1', function(data) {
    ok( false, 'should not be triggered - single bind');
  });
  App.Event.unbind( 'test1');
  App.Event.trigger( 'test1', { success: true } );

  // multi bind
  App.Event.bind( 'test1-1 test1-2', function(data) {
    ok( true, 'event received - multi bind');
    equal( data.success, true, 'event received - data ok - multi bind');
  });
  App.Event.bind( 'test1-3', function(data) {
    ok( false, 'should not be triggered - multi bind');
  });
  App.Event.trigger( 'test1-2', { success: true } );

  App.Event.unbind( 'test1-1')
  App.Event.bind( 'test1-1', function(data) {
    ok( false, 'should not be triggered - multi bind');
  });
  App.Event.trigger( 'test1-2', { success: true } );
});

test( "events level", function() {

  // bind with level
  App.Event.bind( 'test3', function(data) {
    ok( false, 'should not be triggered!');
  }, 'test-level' );

  // unbind with level
  App.Event.unbindLevel( 'test-level' );

  // bind with level
  App.Event.bind( 'test3', function(data) {
    ok( true, 'event received');
    equal( data.success, true, 'event received - data ok - level bind');
  }, 'test-level' );
  App.Event.trigger( 'test3', { success: true} );

});

// local store
test( "local store", function() {

  var tests = [
    'some 123äöüßadajsdaiosjdiaoidj',
    { key: 123 },
    { key1: { key1: [1,2,3,4] }, key2: [1,2,'äöüß'] },
  ];

  // write/get
  App.Store.clear()
  _.each(tests, function(test) {
    App.Store.write( 'test1', test );
    var item = App.Store.get( 'test1' );
    deepEqual( test, item, 'write/get - compare stored and actual data' )
  });

  // undefined/get
  App.Store.clear()
  _.each(tests, function(test) {
    var item = App.Store.get( 'test1' );
    deepEqual( undefined, item, 'undefined/get - compare not existing data and actual data' )
  });

  // write/get/delete
  var tests = [
    { key: 'test1', value: 'some 123äöüßadajsdaiosjdiaoidj' },
    { key: 123, value: { a: 123, b: 'sdaad' } },
    { key: '123äöüß', value: { key1: [1,2,3,4] }, key2: [1,2,'äöüß'] },
  ];

  App.Store.clear()
  _.each(tests, function(test) {
    App.Store.write( test.key, test.value );
  });

  _.each(tests, function(test) {
    var item = App.Store.get( test.key );
    deepEqual( test.value, item, 'write/get/delete - compare stored and actual data' );
    App.Store.delete( test.key );
    item = App.Store.get( test.key );
    deepEqual( undefined, item, 'write/get/delete - compare deleted data' );
  });

});

// config
test( "config", function() {

  // simple
  var tests = [
    { key: 'test1', value: 'some 123äöüßadajsdaiosjdiaoidj' },
    { key: 123, value: { a: 123, b: 'sdaad' } },
    { key: '123äöüß', value: { key1: [1,2,3,4] }, key2: [1,2,'äöüß'] },
  ];

  _.each(tests, function(test) {
    App.Config.set( test.key, test.value )
  });

  _.each(tests, function(test) {
    var item = App.Config.get( test.key )
    deepEqual( item, test.value, 'set/get tests' );
  });

  // group
  var test_groups = [
    { key: 'test2', value: [ 'some 123äöüßadajsdaiosjdiaoidj' ] },
    { key: 1234, value: { a: 123, b: 'sdaad' } },
    { key: '123äöüß', value: { key1: [1,2,3,4,5,6] }, key2: [1,2,'äöüß'] },
  ];
  var group = {};
  _.each(test_groups, function(test) {
    App.Config.set( test.key, test.value, 'group1' );
    group[test.key] = test.value
  });

  // verify whole group
  var item = App.Config.get( 'group1' );
  deepEqual( item, group, 'group - verify group hash');

  // verify each setting
  _.each(test_groups, function(test) {
    var item = App.Config.get( test.key, 'group1' );
    deepEqual( item, test.value, 'group set/get tests' );
  });
});


// auth
App.Auth.login({
  data: {
    username: 'not_existing',
    password: 'not_existing'
  },
  success: function(data) {
    test( "auth - not existing user", function() {
      ok( false, 'ok')
    })
  },
  error: function() {
    test( "auth - not existing user", function() {
      ok( true, 'ok')
      authWithSession();
    })
  }
});

var authWithSession = function() {
  App.Auth.login({
    data: {
      username: 'nicole.braun@zammad.org',
      password: 'test'
    },
    success: function(data) {
      test( "auth - existing user", function() {
        ok( true, 'authenticated')
        var user = App.Session.get('login');
        equal( 'nicole.braun@zammad.org', user, 'session login')
      })
    },
    error: function() {
      test( "auth - existing user", function() {
        ok( false, 'not authenticated')
      })
    }
  });
}

// form
test( "form elements check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );
  $('#forms').append('<hr><h1>form elements check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    input2: '123abc',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select1: false,
    select2: true,
    selectmulti1: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
    selectmultioption2: [ false, true ]
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: defaults['input1'] },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: false, default: defaults['input2'] },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: true, default: defaults['password1'] },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false, default: defaults['password2'] },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: true, upload: true, default: defaults['textarea1']  },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true, default: defaults['textarea2']  },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: defaults['select1'] },
        { name: 'select2', display: 'Select2', tag: 'select', null: false, options: { true: 'internal', false: 'public' }, default: defaults['select2'] },
        { name: 'selectmulti1', display: 'SelectMulti1', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' }, default: defaults['selectmulti1'] },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' }, default: defaults['selectmulti2'] },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], default: defaults['selectmultioption1'] },
        { name: 'selectmultioption2', display: 'SelectMultiOption2', tag: 'select', null: false, multiple: true, options: [{ value: true, name: 'A' }, { value: 1, name: 'B'}, { value: false, name: 'C' }], default: defaults['selectmultioption2'] },

      ]
    },
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  equal( el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  equal( el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  equal( el.find('[name="password1"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  equal( el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal( el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal( el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal( el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  equal( el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  equal( el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal( el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal( el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal( el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'true', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  equal( el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  equal( el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

test( "form params check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );

  $('#forms').append('<hr><h1>form params check</h1><form id="form2"></form>')
  var el = $('#form2')
  var defaults = {
    input2: '123abc',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select1: false,
    select2: true,
    selectmulti1: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
    selectmultioption2: [ false, true ]
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: false },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: true },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: true, upload: true },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' } },
        { name: 'select2', display: 'Select2', tag: 'select', null: false, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti1', display: 'SelectMulti1', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }] },
        { name: 'selectmultioption2', display: 'SelectMultiOption2', tag: 'select', null: false, multiple: true, options: [{ value: true, name: 'A' }, { value: 1, name: 'B'}, { value: false, name: 'C' }] },

      ],
    },
    params: defaults,
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  equal( el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  equal( el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  equal( el.find('[name="password1"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  equal( el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal( el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal( el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal( el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  equal( el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  equal( el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal( el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal( el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal( el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'true', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  equal( el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  equal( el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

test( "form defaults + params check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#forms').append('<hr><h1>form defaults + params check</h1><form id="form3"></form>')
  var el = $('#form3')
  var defaults = {
    input1: '',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select2: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default' },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default' },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: false, default: 'some used pass' },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false, default: 'some not used pass' },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true, default: 'some used text' },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true, default: 'some not used text' },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: false},
        { name: 'select2', display: 'Select2', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: true },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' }, default: [] },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], default: true },
      ],
    },
    params: defaults,
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  equal( el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  equal( el.find('[name="password1"]').val(), 'some used pass', 'check password1 value')
  equal( el.find('[name="password1_confirm"]').val(), 'some used pass', 'check password1 value')
  equal( el.find('[name="password1"]').prop('required'), true, 'check password1 required')
  equal( el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal( el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal( el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal( el.find('[name="textarea1"]').val(), 'some used text', 'check textarea1 value')
  equal( el.find('[name="textarea1"]').prop('required'), true, 'check textarea1 required')
  equal( el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal( el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal( el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal( el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'false', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

test( "form dependend fields check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#forms').append('<hr><h1>form dependend fields check</h1><form id="form4"></form>')
  var el = $('#form4')
  var defaults = {
    input1: '',
    select2: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default' },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default' },
        { name: 'input3', display: 'Input3', tag: 'input', type: 'text', limit: 100, null: true, hide: true, default: 'some used default' },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: false},
        { name: 'select2', display: 'Select2', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: true },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' }, default: [] },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], default: true },
      ],
    },
    params: defaults,
    dependency: [
      {
        bind: {
          name: 'select1',
          value: ["true"]
        },
        change: {
          name: 'input2',
          action: 'hide'
        },
      },
      {
        bind: {
          name: 'select1',
          value: ["false"]
        },
        change: {
          name: 'input2',
          action: 'show'
        },
      },
      {
        bind: {
          name: 'select1',
          value: ["true"]
        },
        change: {
          name: 'input3',
          action: 'show'
        },
      },
      {
        bind: {
          name: 'select1',
          value: ["false"]
        },
        change: {
          name: 'input3',
          action: 'hide'
        },
      }
    ],
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  equal( el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  equal( el.find('[name="input3"]').val(), 'some used default', 'check input3 value')
  equal( el.find('[name="input3"]').prop('required'), false, 'check input3 required')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'false', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  var params = App.ControllerForm.params( el )
  var test_params = {
    input1: "",
    input2: "some used default",
    select1: "false",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: "false"
  }
  deepEqual( params, test_params, 'form param check' );
  el.find('[name="select1"]').val('true')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params( el )
  test_params = {
    input1: "",
    input3: "some used default",
    select1: "true",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: "false"
  }
  deepEqual( params, test_params, 'form param check' );
});

