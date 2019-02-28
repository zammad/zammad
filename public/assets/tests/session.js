window.onload = function() {

test('test current user behaviour by updating session user via assets', function() {

  // Wenn App.User updated through asset and set as session user
  //   expect App.Session.get with new values
  App.User.refresh([{
    "login": "hh@example.com",
    "firstname": "Harald",
    "lastname": "Habebe",
    "email": "hh@example.com",
    "role_ids": [ 1, 2, 4 ],
    "group_ids": [ 1 ],
    "active": true,
    "updated_at": "2017-02-09T09:17:04.770Z",
    "address": "",
    "vip": false,
    "custom_key": undefined,
    "asdf": "",
    "id": 6
  }]);
  App.Session.set(6)
  equal(App.Session.get('id'), 6)
  equal(App.Session.get('login'), 'hh@example.com')
  equal(App.Session.get('vip'), false)
  equal(App.Session.get('custom_key'), undefined)
  equal(App.Session.get().id, 6)
  equal(App.Session.get().login, 'hh@example.com')
  equal(App.Session.get().custom_key, undefined)
  equal(App.Session.get().not_existing, undefined)

  // Wenn App.User updated through asset
  //   expect App.Session.get with new values
  App.User.refresh([{
    "login": "hh_new@example.com",
    "firstname": "Harald",
    "lastname": "Habebe",
    "email": "hh_new@example.com",
    "role_ids": [ 1, 2, 4 ],
    "group_ids": [ 1 ],
    "active": true,
    "updated_at": "2017-02-09T09:17:04.770Z",
    "address": "",
    "vip": false,
    "custom_key": undefined,
    "asdf": "",
    "id": 6
  }]);
  equal(App.Session.get('id'), 6)
  equal(App.Session.get('login'), 'hh_new@example.com')
  equal(App.Session.get('vip'), false)
  equal(App.Session.get('custom_key'), undefined)
  equal(App.Session.get().id, 6)
  equal(App.Session.get().login, 'hh_new@example.com')
  equal(App.Session.get().custom_key, undefined)
  equal(App.Session.get().not_existing, undefined)

  // Wenn App.Session is reseted to inital
  //   expect undefined for all
  App.Session.init()
  equal(App.Session.get(), undefined)
  equal(App.Session.get('id'), undefined)
  equal(App.Session.get('login'), undefined)
  equal(App.Session.get('vip'), undefined)
  equal(App.Session.get('custom_key'), undefined)

  // When App.Session is set and set to undefined or null,
  //   expect @current() to return null
  App.Session.set(6)
  App.Session.set(undefined)
  equal(App.User.current(), null, 'with no active session')
  App.Session.set(null)
  equal(App.User.current(), null, 'with no active session')

  // When App.Session is set with an invalid (not existing) user ID,
  //   expect @current() to return null
  App.Session.set(100)
  equal(App.User.current(), null, 'with invalid session user ID')

});

}