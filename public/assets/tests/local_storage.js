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

}
