class ChannelWeb extends App.ControllerTabs
  requiredPermission: 'admin.channel_web'
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

App.Config.set('Web', { prio: 1000, name: 'Web', parent: '#channels', target: '#channels/web', controller: ChannelWeb, permission: ['admin.channel_web'] }, 'NavBarAdmin')
