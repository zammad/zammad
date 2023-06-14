class TimeAccounting extends App.ControllerTabs
  @requiredPermission: 'admin.time_accounting'
  header: __('Time Accounting')
  headerSwitchName: 'time-accounting'

  events:
    'change .js-header-switch input': 'didChangeHeaderSwitch'
    'show.bs.tab li':                 'willShowTab'

  elements:
    '.js-header-switch input': 'timeAccountingSetting'

  constructor: ->
    super

    @tabs = [
      {
        name:       __('Settings')
        target:     'settings'
        controller: App.TimeAccountingSettings
      },
      {
        name:       __('Activity Types')
        target:     'types'
        controller: App.TimeAccountingTypes
      },
      {
        name:       __('Accounted Time')
        target:     'accounted_time'
        controller: App.TimeAccountingAccountedTime
      },
    ]

    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  render: =>
    super
    @renderHeader()

  renderHeader: =>
    @timeAccountingSetting.prop('checked', App.Setting.get('time_accounting'))

  didChangeHeaderSwitch: ->
    value = @timeAccountingSetting.prop('checked')
    App.Setting.set('time_accounting', value)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  willShowTab: (e) ->
    selector = $(e.target).attr('href')
    @$(selector).trigger('show.bs.tab')

App.Config.set('TimeAccounting', { prio: 8500, name: __('Time Accounting'), parent: '#manage', target: '#manage/time_accounting', controller: TimeAccounting, permission: ['admin.time_accounting'] }, 'NavBarAdmin')
