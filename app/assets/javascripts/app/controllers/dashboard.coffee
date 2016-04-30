class App.Dashboard extends App.Controller
  clueAccess: true
  events:
    'click .tabs .tab': 'toggle'
    'click .js-intro': 'clues'

  constructor: ->
    super

    if @isRole('Customer')
      @clueAccess = false
      return

    # render page
    @render()

    # rerender view, e. g. on language change
    @bind 'ui:rerender', =>
      return if !@authenticate(true)
      @render()

    @mayBeClues()

  render: ->

    localEl = $( App.view('dashboard')(
      head:    'Dashboard'
      isAdmin: @isRole('Admin')
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

    if @isRole('Customer')
      @navigate '#', true
      return

    # set title
    @title 'Dashboard'

    # highlight navbar
    @navupdate '#dashboard'

  changed: ->
    false

  release: ->
    # no

  toggle: (e) =>
    @$('.tabs .tab').removeClass('active')
    $(e.target).addClass('active')
    target = $(e.target).data('area')
    @$('.tab-content').addClass('hidden')
    @$(".tab-content.#{target}").removeClass('hidden')

class DashboardRouter extends App.ControllerPermanent
  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    App.TaskManager.execute(
      key:        'Dashboard'
      controller: 'Dashboard'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set('dashboard', DashboardRouter, 'Routes')
App.Config.set('Dashboard', { prio: 100, parent: '', name: 'Dashboard', target: '#dashboard', key: 'Dashboard', role: ['Agent'], class: 'dashboard' }, 'NavBar')
App.Config.set('Dashboard', { controller: 'Dashboard', authentication: true }, 'permanentTask')
