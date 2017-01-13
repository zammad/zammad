class Index
  constructor: ->
    new App.KeyboardShortcutModal()

App.Config.set('keyboard_shortcuts', Index, 'Routes')
App.Config.set('KeyboardShortcuts', { prio: 1700, parent: '#current_user', name: 'Keyboard Shortcuts', translate: true, target: '#keyboard_shortcuts', permission: ['admin', 'ticket.agent'] }, 'NavBarRight')
