class ChannelWeb extends App.ControllerTabs
  requiredPermission: 'admin.channel_web'
  header: __('Web')
  constructor: ->
    super

    @title __('Web'), true

    @tabs = [
      {
        name:       __('Settings'),
        target:     'w-setting',
        controller: App.SettingsArea, params: { area: 'CustomerWeb::Base' },
      },
    ]

    @render()

App.Config.set('Web', { prio: 1000, name: __('Web'), parent: '#channels', target: '#channels/web', controller: ChannelWeb, permission: ['admin.channel_web'] }, 'NavBarAdmin')
