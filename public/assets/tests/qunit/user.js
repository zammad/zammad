window.onload = function() {

// .initials
QUnit.test('.initials', assert => {
  var user = new App.User({
    firstname: 'Bob',
    lastname: 'Smith Good',
  })
  assert.equal(user.initials(), 'BS')

  user = new App.User({
    firstname: 'Bob',
    lastname: '',
  })
  assert.equal(user.initials(), 'Bo')

  user = new App.User({
    firstname: '',
    lastname: 'Smith',
  })
  assert.equal(user.initials(), 'Sm')

  user = new App.User({
    phone: '000001234',
  })
  assert.equal(user.initials(), '34')

  user = new App.User({
    mobile: '000001235',
  })
  assert.equal(user.initials(), '35')

  user = new App.User({
    login: 'login1',
  })
  assert.equal(user.initials(), '??')

});

}