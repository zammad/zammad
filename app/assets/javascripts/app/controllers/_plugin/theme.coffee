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

  currentTheme: (theme) =>
    theme ||= App.Session.get('preferences')?.theme

    switch theme
      when 'dark'
        'dark'
      when 'light'
        'light'
      else
        @auto()

  onMediaQueryChange: (event) =>
    @set(
      theme: @currentTheme()
    )

  toggleDarkMode: =>
    @set(
      theme: if document.documentElement.dataset.theme == 'dark' then 'light' else 'dark'
      save: true
    )

  set: (data) =>
    if data.save && App.Session.get()?.id
      App.Ajax.request(
        id:          'preferences'
        type:        'PUT'
        url:         "#{App.Config.get('api_path')}/users/preferences"
        data:        JSON.stringify(theme: data.theme)
        processData: true
      )
      App.Event.trigger('ui:theme:saved', data)

    document.documentElement.dataset.theme = @currentTheme(data.theme)
    App.Event.trigger('ui:theme:changed', data)

App.Config.set('theme', App.Theme, 'Plugins')
