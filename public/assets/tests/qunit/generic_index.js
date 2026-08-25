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
