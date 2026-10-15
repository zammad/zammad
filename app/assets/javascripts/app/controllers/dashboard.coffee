class App.Dashboard extends App.Controller
  @include App.CluesShowable

  events:
    'click .tabs .tab': 'toggle'
    'click .js-intro': 'clues'

  constructor: ->
    super

    return if !@permissionCheck('ticket.agent')

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', =>
      return if !@authenticateCheck()
      @render()
    )

    @controllerBind('config_update_local', (data) => @configUpdated(data))

    # The task is started at boot for every agent, even with the dashboard turned off,
    #   so it is there to render once the dashboard gets turned on.
    return if !@Config.get('dashboard')

    @render()

    @mayBeClues()

  configUpdated: (data) ->
    return if !data.name.startsWith('dashboard')

    if data.name is 'dashboard'
      @updateNavMenu()

      if !data.value and @shown
        @navigate '#ticket/view', { hideCurrentLocationFromHistory: true }

    # These settings change which activities are listed, so the cached activity stream is outdated.
    App.SessionStorage.delete('activity_stream') if data.name in ['dashboard', 'dashboard_activity_stream', 'dashboard_activity_stream_own']
    @render()

  render: ->
    if !@Config.get('dashboard')
      @html('')
      return

    stats          = App.DashboardStats.anyVisibleToCurrentUser()
    activityStream = @Config.get('dashboard_activity_stream')
    firstSteps     = @Config.get('dashboard_first_steps')

    localEl = $( App.view('dashboard')(
      head:           __('Dashboard')
      isAdmin:        @permissionCheck('admin')
      stats:          stats
      activityStream: activityStream
      firstSteps:     firstSteps
    ) )

    if stats
      new App.DashboardStats(
        el: localEl.find('.stat-widgets')
      )

    if activityStream
      new App.DashboardActivityStream(
        el:    localEl.find('.js-activityContent')
        limit: 25
      )

    if firstSteps
      new App.DashboardFirstSteps(
        el: localEl.find('.first-steps-widgets')
      )

    @html localEl

  active: (state) =>
    return @shown if state is undefined
    @shown = state
    if state and @Config.get('dashboard')
      @mayBeClues()

  url: ->
    '#dashboard'

  show: (params) =>
    if @permissionCheck('ticket.agent') && !@Config.get('dashboard')
      @navigate '#ticket/view', { hideCurrentLocationFromHistory: true }
    else if @permissionCheck('ticket.agent')
      @title __('Dashboard')
      @navupdate '#dashboard'
    # in case of being only customer, redirect to default router
    else if @permissionCheck('ticket.customer')
      @navigate '#ticket/view', { hideCurrentLocationFromHistory: true }
    # in case of being only admin, redirect to admin interface (show no empty white content page)
    else if @permissionCheck('admin')
      @navigate '#manage', { hideCurrentLocationFromHistory: true }
    # fallback for user who is neither admin nor customer
    else
      @navigate '#welcome', { hideCurrentLocationFromHistory: true }

  changed: ->
    false

  toggle: (e) =>
    @$('.tabs .tab').removeClass('active')
    $(e.target).addClass('active')
    target = $(e.target).data('area')
    @$('.tab-content').addClass('hidden')
    @$(".tab-content.#{target}").removeClass('hidden')

class DashboardRouter extends App.ControllerPermanent
  @requiredPermission: ['*']

  constructor: (params) ->
    super

    # check authentication
    @authenticateCheckRedirect()

    App.TaskManager.execute(
      key:        'Dashboard'
      controller: 'Dashboard'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set('dashboard', DashboardRouter, 'Routes')
App.Config.set('Dashboard', { controller: 'Dashboard', permission: ['*'] }, 'permanentTask')
App.Config.set('Dashboard', { prio: 100, parent: '', name: __('Dashboard'), target: '#dashboard', key: 'Dashboard', permission: ['ticket.agent'], setting: ['dashboard'], class: 'dashboard' }, 'NavBar')
