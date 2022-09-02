class App.Theme extends App.Controller
  constructor: ->
    super

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', @onMediaQueryChange)
    @controllerBind('ui:theme:set', @set)
    @controllerBind('ui:theme:toggle-dark-mode', @toggleDarkMode)

  onMediaQueryChange: (event) =>
    if App.Session.get('preferences').theme == 'auto'
      @set({ theme: 'auto' })

  toggleDarkMode: =>
    @set
      theme: if document.documentElement.dataset.theme == 'dark' then 'light' else 'dark'

  set: (data) ->
    localStorage.setItem('theme', data.theme)
    App.Ajax.request(
      id:          'preferences'
      type:        'PUT'
      url:         "#{App.Config.get('api_path')}/users/preferences"
      data:        JSON.stringify(theme: data.theme)
      processData: true
    )
    detectedTheme = data.theme
    if data.theme == 'auto'
      detectedTheme = if window.matchMedia('(prefers-color-scheme: dark)').matches then 'dark' else 'light'
    document.documentElement.dataset.theme = detectedTheme
    App.Event.trigger('ui:theme:changed', { theme: data.theme, detectedTheme: detectedTheme, source: data.source })

App.Config.set('theme', App.Theme, 'Plugins')
