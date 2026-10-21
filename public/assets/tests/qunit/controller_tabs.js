// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// A hidden task is detached from the document, yet still renders, e.g. an admin page
//   after a setting change while another page is shown.
QUnit.test('App.ControllerTabs shows the remembered tab while detached from the document', assert => {
  App.Config.set('lastTab', '#second')

  var tabs = new App.ControllerTabs({
    el: $('<div>'),
    header: 'Tabs',
    tabs: [
      { name: 'First', target: 'first', controller: App.Controller },
      { name: 'Second', target: 'second', controller: App.Controller },
    ],
  })

  tabs.render()

  assert.equal(tabs.$('.nav-tabs li.active a').attr('href'), '#second', 'tab is active')
  assert.equal(tabs.$('.tab-pane.active').attr('id'), 'second', 'only its pane is shown')
})
