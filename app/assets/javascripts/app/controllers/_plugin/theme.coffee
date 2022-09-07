class App.Theme extends App.Controller
  constructor: ->
    super

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', @onMediaQueryChange)
    @controllerBind('ui:theme:set', @set)
    @controllerBind('ui:theme:toggle-dark-mode', @toggleDarkMode)
    @set(
      theme: App.Session.get('preferences').theme
      source: 'self'
    )

  onMediaQueryChange: (event) =>
    if App.Session.get('preferences').theme == 'auto'
      @set({ theme: 'auto' })

  toggleDarkMode: =>
    @set
      theme: if document.documentElement.dataset.theme == 'dark' then 'light' else 'dark'

  set: (data) ->
    detectedTheme = data.theme
    if data.theme == 'auto'
      detectedTheme = if window.matchMedia('(prefers-color-scheme: dark)').matches then 'dark' else 'light'
    return if data.theme == App.Session.get('preferences').theme && detectedTheme == document.documentElement.dataset.theme
    localStorage.setItem('theme', data.theme)
    if data.source != 'self'
      App.Ajax.request(
        id:          'preferences'
        type:        'PUT'
        url:         "#{App.Config.get('api_path')}/users/preferences"
        data:        JSON.stringify(theme: data.theme)
        processData: true
      )
    document.documentElement.dataset.theme = detectedTheme
    App.Event.trigger('ui:theme:changed', { theme: data.theme, detectedTheme: detectedTheme, source: data.source })

App.Config.set('theme', App.Theme, 'Plugins')
