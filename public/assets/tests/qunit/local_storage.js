window.onload = function() {

QUnit.test('Test item removal from local storage', assert => {
  var key   = 'test_key_1'
  var value = 'test_value_1'

  App.LocalStorage.set(key, value)

  assert.equal(App.LocalStorage.get(key), value)

  App.LocalStorage.delete(key)

  assert.equal(App.LocalStorage.get(key), undefined)
});

QUnit.test('Test user-specific item removal from local storage', assert => {
  var key     = 'test_key_2'
  var value   = 'test_value_2'
  var user_id = 2

  App.LocalStorage.set(key, value, user_id)

  assert.equal(App.LocalStorage.get(key, user_id), value)

  App.LocalStorage.delete(key, user_id)

  assert.equal(App.LocalStorage.get(key, user_id), undefined)
});

QUnit.test('Test key lookup', assert => {
  App.LocalStorage.clear()

  var key     = 'test_key_3'
  var value   = 'test_value_3'
  var user_id = 2
  var alt_key = 'test_alt_key_3'

  // verify no keys initially
  assert.equal(App.LocalStorage.keys().length, 0)

  App.LocalStorage.set(key, value, user_id)

  // has 1 key in total
  assert.equal(App.LocalStorage.keys().length, 1)

  // doesn't return anything with wrong prefix
  assert.equal(App.LocalStorage.keys('a').length, 0)

  // doesn't return anything since user id not given
  assert.equal(App.LocalStorage.keys('test').length, 0)

  // correct
  assert.equal(App.LocalStorage.keys('test', user_id).length, 1)

  // verify value
  assert.equal(App.LocalStorage.keys('test', user_id)[0].match(key + '$'), key)

  App.LocalStorage.set(alt_key, value)

  // returns 1 key without user id
  assert.equal(App.LocalStorage.keys('test').length, 1)
  assert.equal(App.LocalStorage.keys('test')[0], alt_key)
});

}
