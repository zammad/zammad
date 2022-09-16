class App.DarkMode extends App.Controller
  constructor: ->
    super

    @quickToggle         = $('#dark-mode-quick-switch')
    @quickToggleLabel    = @quickToggle.next('label')
    @quickToggleMenuItem = @quickToggle.closest('.dropdown-menu-item--toggle').find('span.u-textTruncate')

    @quickToggleMenuItem.on('click', @onMenuItemClick)
    @quickToggleLabel.on('click', @quickToggleChange)
    @controllerBind('ui:theme:changed', @onUpdate)

  currentTheme: ->
    if @quickToggle.prop('checked') then 'dark' else 'light'

  oppositeTheme: ->
    if @quickToggle.prop('checked') then 'light' else 'dark'

  onMenuItemClick: (event) =>
    event.stopPropagation()
    @quickToggleLabel.trigger('click')

  quickToggleChange: (event) =>
    event.stopPropagation()
    App.Event.trigger('ui:theme:set', { theme: @oppositeTheme(), source: 'quick_switch' })

  onUpdate: (event) =>
    return if event.source is 'quick_switch'
    return if event.detectedTheme is @currentTheme()

    @quickToggle.prop('checked', if event.detectedTheme is 'dark' then true else false)

App.Config.set('DarkMode', { prio: 1000, parent: '#current_user', name: __('Dark Mode'), translate: true, toggle: 'dark-mode-quick', checked: (-> document.documentElement.dataset.theme == 'dark'), permission: ['user_preferences.*'] }, 'NavBarRight')
