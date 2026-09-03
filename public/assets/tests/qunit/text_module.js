// text module
QUnit.test('test text module behaviour with group_ids', assert => {
  App.User.refresh([{
    "login": "hh@example.com",
    "firstname": "Harald",
    "lastname": "Habebe",
    "email": "hh@example.com",
    "role_ids": [ 1, 2, 4 ],
    "group_ids": [ 1, 2 ],
    "active": true,
    "updated_at": "2017-02-09T09:17:04.770Z",
    "address": "",
    "vip": false,
    "custom_key": undefined,
    "asdf": "",
    "id": 6
  }]);
  App.Session.set(6)

  // mock user methods
  App.Session.get().allGroupIds = () => ['1','2']
  App.Session.get().permission = () => true

  // active textmodule without group_ids
  App.TextModule.refresh([
    {
      id:       1,
      name:     'main',
      keywords: 'keywordsmain',
      content:  'contentmain',
      active:   true,
    },
    {
      id:       2,
      name:     'test2',
      keywords: 'keywords2',
      content:  'content2',
      active:   false,
    },
    {
      id:        3,
      name:      'test3',
      keywords:  'keywords3',
      content:   'content3',
      active:    true,
      group_ids: [1,2],
    },
    {
      id:        4,
      name:      'test4',
      keywords:  'keywords4',
      content:   'content4',
      active:    false,
      group_ids: [1,2],
    },
    {
      id:        5,
      name:      'test5',
      keywords:  'keywords5',
      content:   'content5',
      active:    false,
      group_ids: [3],
    },
  ])

  var textModule = new App.WidgetTextModule({
      el: $('.js-textarea').parent(),
      data:{
        user:   App.Session.get(),
        config: App.Config.all(),
      },
      taskKey: 'test1',
  })

  var currentCollection = textModule.currentCollection();

  assert.equal(currentCollection.length, 2, 'active textmodule')
  assert.equal(currentCollection[0].id, 1)
  assert.equal(currentCollection[1].id, 3)

  // trigered TextModulePreconditionUpdate with group_id

  var params = {
    group_id: 1
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test1', params: params })

  currentCollection = textModule.currentCollection();

  assert.equal(currentCollection.length, 2, 'trigered TextModulePreconditionUpdate with group_id')
  assert.equal(currentCollection[0].id, 1)
  assert.equal(currentCollection[1].id, 3)

  // trigered TextModulePreconditionUpdate with wrong group_id

  params = {
    group_id: 3
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test1', params: params })

  currentCollection = textModule.currentCollection();

  assert.equal(currentCollection.length, 1, 'trigered TextModulePreconditionUpdate with wrong group_id')
  assert.equal(currentCollection[0].id, 1)

  // trigered TextModulePreconditionUpdate with group_id but wrong taskKey

  params = {
    group_id: 3
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test2', params: params })

  currentCollection = textModule.currentCollection();

  assert.equal(currentCollection.length, 1, 'trigered TextModulePreconditionUpdate with group_id but wrong taskKey - nothing has changed')
  assert.equal(currentCollection[0].id, 1)

  // trigered TextModulePreconditionUpdate without group_id

  params = {
    owner_id: 2
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test1', params: params })

  currentCollection = textModule.currentCollection();

  assert.equal(currentCollection.length, 2, 'trigered TextModulePreconditionUpdate without group_id')
  assert.equal(currentCollection[0].id, 1)
  assert.equal(currentCollection[1].id, 3)

});

// Regex characters in text module names must be matched literally, not
//   interpreted as a regular expression (issue #6345).
QUnit.test('test text module search with regex characters in the name', assert => {
  App.User.refresh([{
    "login": "hh@example.com",
    "firstname": "Harald",
    "lastname": "Habebe",
    "email": "hh@example.com",
    "role_ids": [ 1, 2, 4 ],
    "group_ids": [ 1, 2 ],
    "active": true,
    "id": 6
  }]);
  App.Session.set(6)

  // mock user methods
  App.Session.get().allGroupIds = () => ['1','2']
  App.Session.get().permission = () => true

  App.TextModule.refresh([
    {
      id:       10,
      name:     '[category] Some product',
      keywords: 'bracketed',
      content:  'content10',
      active:   true,
    },
    {
      id:       11,
      name:     '[product] Some category',
      keywords: 'bracketed',
      content:  'content11',
      active:   true,
    },
  ], { clear: true })

  $('body').append('<div id="text-module-regex-chars"><div contenteditable="true"></div></div>')

  var el = $('#text-module-regex-chars [contenteditable]')

  var textModule = new App.WidgetTextModule({
    el:      el,
    data:    {
      user:   App.Session.get(),
      config: App.Config.all(),
    },
    taskKey: 'test-regex-chars',
  })

  var plugin = el.data('plugin_textmodule')

  // Run the search the way a keystroke would: the buffer holds the trigger
  //   plus the term the user typed after it.
  var search = (buffer) => {
    plugin.buffer = buffer
    plugin.result(plugin.findTrigger(buffer))

    return plugin.$widget.find('ul > li').map(function() {
      return $(this).attr('data-id')
    }).get().sort()
  }

  try {
    // An unterminated character class must not blow up the search.
    assert.deepEqual(search('::[category'), ['10'], 'unterminated bracket matches literally')

    // A complete character class must not match every entry.
    assert.deepEqual(search('::[category]'), ['10'], 'complete bracket matches literally')

    // Other regex metacharacters are literal too.
    assert.deepEqual(search('::product) Some'), [], 'unbalanced parenthesis matches nothing')

    // The term is taken literally, so the former escaping workaround now
    //   searches for a backslash and finds nothing.
    assert.deepEqual(search('::\\[category'), [], 'backslash is no longer an escape')

    // Terms without regex characters keep working.
    assert.deepEqual(search('::bracketed'), ['10', '11'], 'keyword matches both')

    assert.deepEqual(search('::category'), ['10', '11'], 'plain term matches both')
  }
  finally {
    // Keep the fixture self-contained: an assertion that throws must not leave
    //   a detached element subscribed to the text module collection.
    textModule.releaseController()
    textModule.release()
    $('#text-module-regex-chars').remove()
  }
});
