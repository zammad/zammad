class App.Theme extends App.Controller
  constructor: ->
    super

    mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)')
    if typeof mediaQueryList.addEventListener is 'function'
      mediaQueryList.addEventListener('change', @onMediaQueryChange)

    @controllerBind('ui:theme:set', @set)
    @controllerBind('ui:theme:toggle-dark-mode', @toggleDarkMode)
    @set(
      theme: @currentTheme()
    )

  auto: ->
    if window.matchMedia('(prefers-color-scheme: dark)').matches then 'dark' else 'light'

  currentTheme: ->
    App.Session.get('preferences')?.theme || @auto()

  onMediaQueryChange: (event) =>
    @set(
      theme: @currentTheme()
    )

  toggleDarkMode: =>
    @set(
      theme: if document.documentElement.dataset.theme == 'dark' then 'light' else 'dark'
      save: true
    )

  set: (data) ->
    return if data.theme == document.documentElement.dataset.theme

    if data.save && App.Session.get()?.id
      App.Ajax.request(
        id:          'preferences'
        type:        'PUT'
        url:         "#{App.Config.get('api_path')}/users/preferences"
        data:        JSON.stringify(theme: data.theme)
        processData: true
      )
    document.documentElement.dataset.theme = data.theme
    App.Event.trigger('ui:theme:changed', data)

App.Config.set('theme', App.Theme, 'Plugins')
