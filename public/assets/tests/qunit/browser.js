QUnit.test('App.Browser .magicKey', assert => {
  let stub = sinon.stub(App.Browser, 'isMac')

  stub.returns(true)
  assert.equal(App.Browser.magicKey(), 'cmd')

  stub.returns(false)
  assert.equal(App.Browser.magicKey(), 'ctrl')

  stub.restore()
})

QUnit.test('App.Browser .hotkeys', assert => {
  let stub = sinon.stub(App.Browser, 'isMac')

  stub.returns(true)
  assert.equal(App.Browser.hotkeys(), 'alt+ctrl')

  stub.returns(false)
  assert.equal(App.Browser.hotkeys(), 'ctrl+shift')

  stub.restore()
})

QUnit.test('App.Browser .isMac', assert => {
  let stub = sinon.stub(App.Browser, 'detection')
  stub.returns({
    browser: {
      major: "48",
      name: "Chrome",
      version: "48.0.2564.109",
    },
    os: {
      name: "Mac OS",
      version: "10.11.3",
    }
  })

  assert.ok(App.Browser.isMac())

  stub.returns({
    browser: {
      major: "48",
      name: "Chrome",
      version: "48.0.2564.109",
    },
    os: {
      name: "Debian McDebian",
      version: "14.10",
    }
  })

  assert.notOk(App.Browser.isMac())

  stub.returns({
    browser: {
      major: "48",
      name: "Chrome",
      version: "48.0.2564.109",
    },
    os: {}
  })

  assert.notOk(App.Browser.isMac())

  stub.restore()
})
