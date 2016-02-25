class Index extends App.ControllerModal
  large: true
  head: 'Keyboard Shortcuts'
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  constructor: (params = {}) ->
    delete params.el # do attache to body
    super(params)

    return if !@authenticate()

  content: ->
    App.view('keyboard_shortcuts')(
      areas: App.Config.get('keyboard_shortcuts')
    )

  onClosed: ->
    window.history.go(-1)

  onSubmit: ->
    window.history.go(-1)

  onCancel: ->
    window.history.go(-1)

App.Config.set('keyboard_shortcuts', Index, 'Routes')

App.Config.set('KeyboardShortcuts', { prio: 1700, parent: '#current_user', name: 'Keyboard Shortcuts', translate: true, target: '#keyboard_shortcuts', role: [ 'Admin', 'Agent' ] }, 'NavBarRight')
