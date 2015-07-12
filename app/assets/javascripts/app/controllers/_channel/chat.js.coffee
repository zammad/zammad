class App.ChannelChat extends App.ControllerTabs
  header: 'Chat'
  constructor: ->
    super

    @title 'Chat', true

    @tabs = [
      {
        name:       'Settings',
        target:     'setting',
        controller: App.SettingsArea, params: { area: 'Chat::Base' },
      },
    ]

    @render()
