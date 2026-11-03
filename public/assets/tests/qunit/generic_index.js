// Regression test for https://github.com/zammad/zammad/issues/6311
//
// ControllerGenericIndex#search() and #delayedRender() used to share the same
// App.Delay key ("#{controllerId}-render"). Any collection event that triggers
// delayedRender() (e.g. a websocket touch) within the 300ms debounce window of
// a search/shortcut click cancels the pending navigate() call, so the click
// silently does nothing.
QUnit.test('generic index: search navigation is not cancelled by a concurrent delayedRender (#6311)', assert => {
  var done = assert.async(1)

  var navigateCalls = 0
  var navigateArgs  = []
  var renderCalls   = 0

  var ctrl = {
    controllerId: 'genericIndexDelayTest',
    delay:        App.ControllerGenericIndex.prototype.delay,
    pageData:     { pagerBaseUrl: '#test/' },
    searchField:  { val: function() { return 'foo' } },
    navigate:     function(location) { navigateCalls++; navigateArgs.push(location) },
    render:       function() { renderCalls++ },
  }

  // simulate a shortcut/search click immediately followed by a background
  // re-render request (e.g. from a websocket model touch event)
  App.ControllerGenericIndex.prototype.search.call(ctrl)
  App.ControllerGenericIndex.prototype.delayedRender.call(ctrl)

  setTimeout(function() {
    assert.equal(navigateCalls, 1, 'search navigation must still fire even though a render was scheduled in between')
    assert.deepEqual(navigateArgs, ['#test/1/foo'], 'search navigates to the pager URL with the encoded query')
    assert.equal(renderCalls, 1, 'the background render must still fire as well')
    done()
  }, 1000)
})

// Regression tests for https://github.com/zammad/zammad/issues/6487
//
// After a save, the list only trusts the search index when the response
// confirmed the inline index update. A missing or negative header must never
// turn into the "hidden by the current search or filter" hint.
QUnit.module('generic index: search index state after save (#6487)', hooks => {
  var ctrl, notifications

  hooks.beforeEach(() => {
    notifications = []
    ctrl = {
      searchQuery:   'foo',
      pageData:      { pagerTotalCount: 1, pagerPerPage: 50 },
      $:             function() { return { length: 0 } },
      notify:        function(data) { notifications.push(data.msg) },
      delayedRender: function() {},
    }
  })

  QUnit.test('a missing response header counts as not updated', assert => {
    App.ControllerGenericIndex.prototype.afterSave.call(ctrl, { id: 1 }, undefined)

    assert.strictEqual(ctrl.searchIndexUpdated, false)
  })

  QUnit.test('a negative response header counts as not updated', assert => {
    var xhr = { getResponseHeader: function() { return 'false' } }
    App.ControllerGenericIndex.prototype.afterSave.call(ctrl, { id: 1 }, xhr)

    assert.strictEqual(ctrl.searchIndexUpdated, false)
  })

  QUnit.test('a positive response header counts as updated', assert => {
    var xhr = { getResponseHeader: function() { return 'true' } }
    App.ControllerGenericIndex.prototype.afterSave.call(ctrl, { id: 1 }, xhr)

    assert.strictEqual(ctrl.searchIndexUpdated, true)
  })

  QUnit.test('warns about an outdated list instead of the hidden hint when the index was not updated', assert => {
    App.ControllerGenericIndex.prototype.notifyAfterSave.call(ctrl, [], 1, false)

    assert.deepEqual(notifications, ['The search index could not be updated yet, the list may be outdated.'])
  })

  QUnit.test('shows the hidden hint when the index was updated and the new entry is not part of the result', assert => {
    App.ControllerGenericIndex.prototype.notifyAfterSave.call(ctrl, [{ id: 2 }], 1, true)

    assert.deepEqual(notifications, ['The entry was created, but it is hidden by the current search or filter.'])
  })

  QUnit.test('stays quiet when the new entry is part of the result', assert => {
    App.ControllerGenericIndex.prototype.notifyAfterSave.call(ctrl, [{ id: 1 }], 1, true)

    assert.deepEqual(notifications, [])
  })

  QUnit.test('stays quiet when the result spans more than one page', assert => {
    ctrl.pageData.pagerTotalCount = 51
    App.ControllerGenericIndex.prototype.notifyAfterSave.call(ctrl, [{ id: 2 }], 1, true)

    assert.deepEqual(notifications, [])
  })
})
