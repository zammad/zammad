class Index extends App.ControllerTabs
  header: 'Trigger'
  constructor: ->
    super

    @title 'Trigger', true

    @tabs = [
      {
        name:       'Time Based',
        target:     'c-time-based',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
      {
        name:       'Event Based',
        target:     'c-event-based',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
      {
        name:       'Notifications',
        target:     'c-notification',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
      {
        name:       'Web Hooks',
        target:     'c-web-hook',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
    ]

    @render()

App.Config.set( 'Trigger', { prio: 3000, name: 'Trigger', parent: '#manage', target: '#manage/triggers', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )