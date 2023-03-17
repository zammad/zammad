window.onload = function() {

QUnit.test("model bindings and rebinding", assert => {

  var callback_count1 = 0
  var callbacks = App.Template._callbacks
  Object.keys(callbacks).forEach(function(key) {
    callback_count1 = callback_count1 + callbacks[key].length
  });
  assert.equal(callback_count1, 2)

  assert.equal(App.Template.SUBSCRIPTION_COLLECTION, undefined)

  App.Template.clearInMemory()

  assert.equal(App.Template.SUBSCRIPTION_COLLECTION, undefined)

  var callback_count2 = 0
  callbacks = App.Template._callbacks
  Object.keys(callbacks).forEach(function(key) {
    callback_count2 = callback_count2 + callbacks[key].length
  });
  assert.equal(callback_count2, callback_count1)

  var render = function() {}
  var subscribe_id = App.Template.subscribe(render, {initFetch: true})

  assert.ok(_.isObject(App.Template.SUBSCRIPTION_COLLECTION))
  assert.ok(!_.isEmpty(App.Template.SUBSCRIPTION_COLLECTION))

  var callback_count3 = 0
  callbacks = App.Template._callbacks
  Object.keys(callbacks).forEach(function(key) {
    callback_count3 = callback_count3 + callbacks[key].length
  });
  assert.equal(callback_count3, 6)

  App.Template.clearInMemory()

  assert.ok(_.isObject(App.Template.SUBSCRIPTION_COLLECTION))
  assert.ok(_.isEmpty(App.Template.SUBSCRIPTION_COLLECTION))

  var callback_count4 = 0
  callbacks = App.Template._callbacks
  Object.keys(callbacks).forEach(function(key) {
    callback_count4 = callback_count4 + callbacks[key].length
  });
  assert.equal(callback_count4, callback_count3)

});

}
