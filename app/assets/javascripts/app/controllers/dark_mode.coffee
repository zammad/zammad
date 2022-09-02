class App.DarkMode extends App.Controller
  constructor: ->
    super

    @quickToggle = $('#dark-mode-quick-switch')
    @quickToggleMenuItem = @quickToggle.closest('.dropdown-menu-item--toggle')

    @quickToggle.on('change', @quickToggleChange)
    @quickToggle.closest('.zammad-switch').on('click', @stopPropagation)
    @quickToggleMenuItem.on('click', @onMenuItemClick)

    if localStorage.getItem('dark-mode') == 'on' || window.matchMedia('(prefers-color-scheme: dark)').matches
      this.setMode 'on'

  stopPropagation: (event) ->
    console.log "stopPropagation"
    event.stopPropagation()

  onMenuItemClick: (event) =>
    event.stopPropagation()
    oppositeState = if @quickToggle.prop('checked') then 'off' else 'on'
    this.setMode oppositeState
    console.log "onMenuItemClick"

  quickToggleChange: =>
    state = if @quickToggle.prop('checked') then 'on' else 'off'
    console.log "quickToggleChange", @quickToggle.prop('checked'), state
    this.setMode state, true

  setMode: (mode, silent) ->
    enabled = mode == 'on' ? true : false
    if mode == 'auto'
      enabled = window.matchMedia('(prefers-color-scheme: dark)').matches
    document.documentElement.dataset.darkMode = if enabled then 'on' else 'off'
    localStorage.setItem('dark-mode', mode)
    if !silent
      @quickToggle.prop('checked', enabled)

App.Config.set('DarkMode', { prio: 1000, parent: '#current_user', name: __('Dark Mode'), translate: true, toggle: 'dark-mode-quick', permission: ['user_preferences.*'] }, 'NavBarRight')
