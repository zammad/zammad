class App.Dashboard extends App.Controller
  clueAccess: true
  events:
    'click .tabs .tab': 'toggle'
    'click .js-intro': 'clues'

  constructor: ->
    super

    if !@permissionCheck('ticket.agent')
      @clueAccess = false
      return

    # render page
    @render()

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', =>
      return if !@authenticateCheck()
      @render()
    )

    @mayBeClues()

  render: ->

    localEl = $( App.view('dashboard')(
      head:    'Dashboard'
      isAdmin: @permissionCheck('admin')
    ) )

    new App.DashboardStats(
      el: localEl.find('.stat-widgets')
    )

    new App.DashboardActivityStream(
      el:    localEl.find('.js-activityContent')
      limit: 25
    )

    new App.DashboardFirstSteps(
      el: localEl.find('.first-steps-widgets')
    )

    @html localEl

  mayBeClues: =>
    return if !@clueAccess
    return if !@shown
    return if @Config.get('switch_back_to_possible')
    preferences = @Session.get('preferences')
    @clueAccess = false
    return if preferences['intro']
    @clues()

  clues: (e) =>
    @clueAccess = false
    if e
      e.preventDefault()
    @navigate '#clues'

  active: (state) =>
    return @shown if state is undefined
    @shown = state
    if state
      @mayBeClues()

  url: ->
    '#dashboard'

  show: (params) =>

    # incase of being only customer, redirect to default router
    if @permissionCheck('ticket.customer') && !@permissionCheck('ticket.agent')
      @navigate '#ticket/view', { hideCurrentLocationFromHistory: true }
      return

    # incase of being only admin, redirect to admin interface (show no empty white content page)
    if !@permissionCheck('ticket.customer') && !@permissionCheck('ticket.agent') && @permissionCheck('admin')
      @navigate '#manage', { hideCurrentLocationFromHistory: true }
      return

    # set title
    @title 'Dashboard'

    # highlight navbar
    @navupdate '#dashboard'

  changed: ->
    false

  toggle: (e) =>
    @$('.tabs .tab').removeClass('active')
    $(e.target).addClass('active')
    target = $(e.target).data('area')
    @$('.tab-content').addClass('hidden')
    @$(".tab-content.#{target}").removeClass('hidden')

class DashboardRouter extends App.ControllerPermanent
  requiredPermission: ['*']

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
App.Config.set('Dashboard', { prio: 100, parent: '', name: 'Dashboard', target: '#dashboard', key: 'Dashboard', permission: ['ticket.agent'], class: 'dashboard' }, 'NavBar')
