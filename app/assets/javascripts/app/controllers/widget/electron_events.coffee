class Widget
  constructor: ->
    return if !window.require
    ipcRenderer = window.require('electron').ipcRenderer
    return if !ipcRenderer
    App.Event.bind('online_notification_counter', (e) ->
      ipcRenderer.send('set-badge', e)
    )

App.Config.set('aaa_electron_events', Widget, 'Navigations')
