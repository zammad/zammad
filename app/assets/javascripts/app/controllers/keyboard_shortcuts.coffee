class App.KeyboardShortcuts extends App.ControllerModal
  authenticateRequired: true
  large: true
  head: __('Keyboard Shortcuts')
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  events:
    'change #switch-shortcut-enable': 'toggleShortcutEnable'
    'click .js-switch-shortcut-layout': 'toggleShortcutLayout'

  constructor: ->
    super
    @controllerBind('keyboard_shortcuts_close', @close)

  content: ->
    App.view('keyboard_shortcuts')(
      areas: App.Config.get('keyboard_shortcuts')
      magicKey: App.Browser.magicKey()
      hotkeys: App.Browser.hotkeysDisplay()
      isDisabled: App.KeyboardShortcutPlugin.isDisabled()
      useOldShortcutLayout: App.KeyboardShortcutPlugin.useOldShortcutLayout()
    )

  exists: =>
    return true if @el.parents('html').length > 0
    false

  onClosed: ->
    return if window.location.hash isnt '#keyboard_shortcuts'
    window.history.back()

  toggleShortcutEnable: ->
    App.KeyboardShortcutPlugin.toggleShortcutEnable()

    @render()

  toggleShortcutLayout: ->
    App.KeyboardShortcutPlugin.toggleShortcutLayout()

    @render()

App.Config.set('keyboard_shortcuts', App.KeyboardShortcuts, 'Routes')
App.Config.set('KeyboardShortcuts', { prio: 1700, parent: '#current_user', name: __('Keyboard Shortcuts'), translate: true, target: '#keyboard_shortcuts', permission: ['admin', 'ticket.agent'] }, 'NavBarRight')
