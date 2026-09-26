// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

QUnit.module('navigation branding', hooks => {
  let productLogo
  let productName

  hooks.beforeEach(() => {
    productLogo = App.Config.get('product_logo')
    productName = App.Config.get('product_name')
  })

  hooks.afterEach(() => {
    App.Config.set('product_logo', productLogo)
    App.Config.set('product_name', productName)
  })

  const renderNavigation = () => $(App.view('navigation')({
    user: { id: 1 },
    logoUrl: App.Controller.prototype.logoUrl.call({ Config: App.Config }),
  }))

  QUnit.test('uses the uploaded product logo and preserves notifications', assert => {
    App.Config.set('product_logo', 'custom-logo.png')
    App.Config.set('product_name', 'Example "Helpdesk" <Support>')

    const navigation = renderNavigation()
    const logo = navigation.find('.js-toggleNotifications img')

    assert.equal(logo.length, 1)
    assert.equal(logo.attr('src'), '/api/v1/system_assets/product_logo/custom-logo.png')
    assert.equal(logo.attr('alt'), 'Example "Helpdesk" <Support>')
    assert.equal(navigation.find('.logo svg.icon-logo').length, 0)
    assert.equal(navigation.find('.js-toggleNotifications .js-notificationsCounter').length, 1)
  })

  for (const logo of ['logo.svg', '', undefined, null]) {
    QUnit.test(`uses the stock icon for product_logo=${logo}`, assert => {
      App.Config.set('product_logo', logo)

      const navigation = renderNavigation()

      assert.equal(navigation.find('.logo svg.icon-logo').length, 1)
      assert.equal(navigation.find('.logo img').length, 0)
    })
  }
})
