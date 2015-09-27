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

App.Config.set( 'Web', { prio: 1000, name: 'Web', parent: '#channels', target: '#channels/web', controller: App.ChannelWeb, role: ['Admin'] }, 'NavBarAdmin' )
