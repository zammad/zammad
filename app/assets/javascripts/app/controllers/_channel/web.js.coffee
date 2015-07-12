class App.ChannelWeb extends App.ControllerTabs
  header: 'Web'
  constructor: ->
    super

    @title 'Web', true

    @tabs = [
      {
        name:       'Settings',
        target:     'w-setting',
        controller: App.SettingsArea, params: { area: 'CustomerWeb::Base' },
      },
    ]

    @render()
