window.onload = function() {

test('test current user behaviour by updating session user via assets', function() {

  // load user
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

  // set session user
  App.Session.set(6)

  // verify attributes
  equal(App.Session.get('id'), 6)
  equal(App.Session.get('login'), 'hh@example.com')
  equal(App.Session.get('vip'), false)
  equal(App.Session.get('custom_key'), undefined)
  equal(App.Session.get().id, 6)
  equal(App.Session.get().login, 'hh@example.com')
  equal(App.Session.get().custom_key, undefined)
  equal(App.Session.get().not_existing, undefined)

  // update session user via assets
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

  // verify attributes
  equal(App.Session.get('id'), 6)
  equal(App.Session.get('login'), 'hh_new@example.com')
  equal(App.Session.get('vip'), false)
  equal(App.Session.get('custom_key'), undefined)
  equal(App.Session.get().id, 6)
  equal(App.Session.get().login, 'hh_new@example.com')
  equal(App.Session.get().custom_key, undefined)
  equal(App.Session.get().not_existing, undefined)

  // clear session
  App.Session.init()
  equal(App.Session.get(), undefined)
  equal(App.Session.get('id'), undefined)
  equal(App.Session.get('login'), undefined)
  equal(App.Session.get('vip'), undefined)
  equal(App.Session.get('custom_key'), undefined)

});

}