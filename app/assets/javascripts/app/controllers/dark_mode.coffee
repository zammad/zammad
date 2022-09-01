class App.DarkMode extends App.Controller
  constructor: ->
    super

    @quickToggle = $('#dark-mode-quick-switch')
    @quickToggleMenuItem = @quickToggle.closest('.dropdown-menu-item--toggle')

    @quickToggle.on('change', @quickToggleChange)
    @quickToggle.closest('.zammad-switch').on('click', @stopPropagation)
    @quickToggleMenuItem.on('click', @onMenuItemClick)

    @controllerBind('ui:theme:changed', @onUpdate)

  stopPropagation: (event) ->
    event.stopPropagation()

  onMenuItemClick: (event) =>
    event.stopPropagation()
    oppositeTheme = if @quickToggle.prop('checked') then 'light' else 'dark'
    App.Event.trigger('ui:theme:set', { theme: oppositeTheme, source: 'quick_switch' })

  quickToggleChange: =>
    theme = if @quickToggle.prop('checked') then 'dark' else 'light'
    App.Event.trigger('ui:theme:set', { theme: theme, source: 'quick_switch' })

  onUpdate: (event) =>
    if event.source != 'quick_switch'
      @quickToggle.prop('checked', event.detectedTheme == 'dark')

App.Config.set('DarkMode', { prio: 1000, parent: '#current_user', name: __('Dark Mode'), translate: true, toggle: 'dark-mode-quick', checked: (-> document.documentElement.dataset.theme == 'dark'), permission: ['user_preferences.*'] }, 'NavBarRight')
