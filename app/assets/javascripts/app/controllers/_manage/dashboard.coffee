# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class DashboardElements extends App.Controller
  events:
    'change .js-dashboardElement input': 'toggleElement'

  constructor: ->
    super
    @render()

  toggleElement: (e) ->
    input = $(e.currentTarget)
    App.Setting.set(input.attr('name'), input.prop('checked'), notify: true)

class DashboardViews extends DashboardElements
  events:
    'change .js-activityStream select': 'changeActivityStream'

  render: =>
    @html App.view('settings/dashboard_views')(
      disabled:       !App.Setting.get('dashboard')
      activityStream: DashboardViews.activityStream()
    )
    @el.append App.view('settings/dashboard_elements')(
      disabled: !App.Setting.get('dashboard')
      elements: [
        {
          name:        __('First Steps')
          key:         'dashboard_first_steps'
          description: __('Onboard new users with a step-by-step Zammad setup.')
          active:      App.Setting.get('dashboard_first_steps')
        }
      ]
    )

  # The dropdown is backed by two settings, so that everything checking whether
  #   the activity stream is turned on keeps reading a plain boolean.
  @activityStream: ->
    # A choice still saving wins, as the stream is only turned on after the limit is saved.
    return @latestActivityStream.value if @latestActivityStream
    return 'off' if !App.Setting.get('dashboard_activity_stream')
    return 'own' if App.Setting.get('dashboard_activity_stream_own')
    'all'

  changeActivityStream: (e) ->
    value = $(e.currentTarget).val()

    # On the class, as choosing renders this controller anew. An object, so that an earlier
    #   choice of the same value that is still saving is not taken for this one.
    choice = { value: value }
    DashboardViews.latestActivityStream = choice
    saved = ->
      DashboardViews.latestActivityStream = null if DashboardViews.latestActivityStream is choice

    if value is 'off'
      App.Setting.set('dashboard_activity_stream', false, notify: true, doneLocal: saved, failLocal: saved)
      return

    # The stream is turned on only once the limit is saved, so agents never see their colleagues'
    #   activities in between, nor when saving the limit fails.
    App.Setting.set('dashboard_activity_stream_own', value is 'own',
      failLocal: saved
      doneLocal: ->
        # The admin chose something else while saving, that choice decides.
        return if DashboardViews.latestActivityStream isnt choice

        # Saved even when it is on already, so the toast shows only once both settings are saved.
        App.Setting.set('dashboard_activity_stream', true, notify: true, doneLocal: saved, failLocal: saved)
    )

class DashboardWidgets extends DashboardElements
  render: =>
    elements = []
    for widget in _.sortBy(App.Config.get('Stats'), 'prio')
      key = App.DashboardStats.settingName(widget)

      # Widgets without such a setting, e.g. from an addon, cannot be turned off.
      continue if !App.Setting.findByAttribute('name', key)

      elements.push(
        name:        widget.title
        key:         key
        description: widget.description
        active:      App.Setting.get(key)
      )

    @html App.view('settings/dashboard_elements')(
      disabled: !App.Setting.get('dashboard')
      elements: elements
    )

class SettingDashboard extends App.ControllerTabs
  @requiredPermission: 'admin.dashboard'
  header: __('Dashboard')
  description: __('Options for enabling/disabling the dashboard and customizing its elements. If the dashboard is disabled, ticket overviews become your Zammad landing page.')
  headerSwitchName: 'dashboard'

  events:
    'change .js-header-switch input': 'didChangeHeaderSwitch'

  constructor: ->
    super

    @title __('Dashboard'), true
    @tabs = [
      { name: __('Dashboard views'),   target: 'views',   controller: DashboardViews }
      { name: __('Dashboard widgets'), target: 'widgets', controller: DashboardWidgets }
    ]

    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  render: =>
    # A render closes an open dropdown, and a single save renders several times.
    shownSettings = @shownSettings()
    return if _.isEqual(shownSettings, @renderedSettings)
    @renderedSettings = shownSettings

    @alert               = @emptyDashboardAlert()
    @headerSwitchChecked = App.Setting.get('dashboard')
    super

  # The activity stream as its dropdown shows it, so saving its two settings renders just once.
  shownSettings: ->
    settings = { activityStream: DashboardViews.activityStream() }
    for setting in App.Setting.all() when setting.name not in ['dashboard_activity_stream', 'dashboard_activity_stream_own']
      settings[setting.name] = setting.state_current.value
    settings

  emptyDashboardAlert: ->
    return if !App.Setting.get('dashboard')
    return if App.Setting.get('dashboard_first_steps')
    return if DashboardViews.activityStream() isnt 'off'
    return if App.DashboardStats.anyVisible()

    variant: 'warning'
    message: App.i18n.translateContent('All views and widgets are turned off, so agents see an empty dashboard. If you do not need the dashboard at all, you can turn it off.')

  didChangeHeaderSwitch: (e) ->
    App.Setting.set('dashboard', $(e.currentTarget).prop('checked'), notify: true)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

App.Config.set('SettingDashboard', { prio: 1300, parent: '#settings', name: __('Dashboard'), target: '#settings/dashboard', controller: SettingDashboard, permission: ['admin.dashboard'] }, 'NavBarAdmin')
