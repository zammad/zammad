window.onload = function() {

test('Test item removal from local storage', function() {
  var key   = 'test_key_1'
  var value = 'test_value_1'

  App.LocalStorage.set(key, value)

  equal(App.LocalStorage.get(key), value)

  App.LocalStorage.delete(key)

  equal(App.LocalStorage.get(key), undefined)
});

test('Test user-specific item removal from local storage', function() {
  var key     = 'test_key_2'
  var value   = 'test_value_2'
  var user_id = 2

  App.LocalStorage.set(key, value, user_id)

  equal(App.LocalStorage.get(key, user_id), value)

  App.LocalStorage.delete(key, user_id)

  equal(App.LocalStorage.get(key, user_id), undefined)
});

test('Test key lookup', function() {
  App.LocalStorage.clear()

  var key     = 'test_key_3'
  var value   = 'test_value_3'
  var user_id = 2
  var alt_key = 'test_alt_key_3'

  // verify no keys initially
  equal(App.LocalStorage.keys().length, 0)

  App.LocalStorage.set(key, value, user_id)

  // has 1 key in total
  equal(App.LocalStorage.keys().length, 1)

  // doesn't return anything with wrong prefix
  equal(App.LocalStorage.keys('a').length, 0)

  // doesn't return anything since user id not given
  equal(App.LocalStorage.keys('test').length, 0)

  // correct
  equal(App.LocalStorage.keys('test', user_id).length, 1)

  // verify value
  equal(App.LocalStorage.keys('test', user_id)[0].match(key + '$'), key)

  App.LocalStorage.set(alt_key, value)

  // returns 1 key without user id
  equal(App.LocalStorage.keys('test').length, 1)
  equal(App.LocalStorage.keys('test')[0], alt_key)
});

}
