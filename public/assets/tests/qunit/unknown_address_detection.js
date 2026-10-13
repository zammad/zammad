// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

window.onload = function() {

QUnit.module('unknown address detection', {
  beforeEach: function() {
    this.config = {
      fqdn:             App.Config.get('fqdn'),
      alternative_fqdn: App.Config.get('alternative_fqdn'),
      http_type:        App.Config.get('http_type'),
    }

    App.Config.set('fqdn', 'zammad.example.org')
    App.Config.set('alternative_fqdn', '')
    App.Config.set('http_type', 'https')

    App.UnknownAddressDetection.notified = false
    $.noty.closeAll()
  },
  afterEach: function() {
    _.each(this.config, (value, key) => App.Config.set(key, value))

    App.UnknownAddressDetection.notified = false
    $.noty.closeAll()
  },
})

const fakeLocation = (hash) => ({
  protocol: 'http:',
  host:     'localhost:3000',
  pathname: '/',
  search:   '?foo=bar',
  hash:     hash,
})

QUnit.test('redirects to the same page on the configured address', assert => {
  assert.equal(
    App.UnknownAddressDetection.redirectUrl(fakeLocation('#ticket/zoom/1')),
    'https://zammad.example.org/?foo=bar#ticket/zoom/1',
  )
})

QUnit.test('stays silent on a configured address', assert => {
  App.Config.set('fqdn', 'localhost:3000')
  App.Config.set('http_type', 'http')

  assert.equal(App.UnknownAddressDetection.redirectUrl(fakeLocation('#ticket/zoom/1')), undefined)
})

QUnit.test('resolves the page that is current when the link is clicked', assert => {
  const current = fakeLocation('#ticket/zoom/1')

  App.UnknownAddressDetection.notify(current)

  // Toasts closed by the previous test are still fading out, the newest one is the last.
  const link = $('#notify a').last()

  assert.equal(link.length, 1)
  assert.equal(link.attr('href'), 'https://zammad.example.org/?foo=bar#ticket/zoom/1')

  current.hash = '#ticket/zoom/2'

  // The test page must not actually leave.
  link.on('click', e => e.preventDefault())
  link.get(0).click()

  assert.equal(link.attr('href'), 'https://zammad.example.org/?foo=bar#ticket/zoom/2')
})

}
