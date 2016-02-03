class App.Dashboard extends App.Controller
  events:
    'click .tabs .tab': 'toggle'
    'click .intro': 'clues'

  constructor: ->
    super

    if @isRole('Customer')
      @navigate '#', true
      return

    # render page
    @render()

    # rerender view, e. g. on language change
    @bind 'ui:rerender', =>
      return if !@authenticate(true)
      @render()

    # start intro
    preferences = @Session.get('preferences')
    if !preferences['intro']
      @clues()

  render: ->

    @html App.view('dashboard')(
      head:    'Dashboard'
      isAdmin: @isRole('Admin')
    )

    new App.DashboardStats(
      el: @$('.stat-widgets')
    )

    new App.DashboardActivityStream(
      el:    @$('.sidebar')
      limit: 25
    )

  clues: (e) =>
    if e
      e.preventDefault()
    new App.FirstStepsClues(
      el: @el
      onComplete: =>
        @ajax(
          id:          'preferences'
          type:        'PUT'
          url:         @apiPath + '/users/preferences'
          data:        JSON.stringify({user:{intro:true}})
          processData: true
        )
    )

  active: (state) =>
    @activeState = state

  isActive: =>
    @activeState

  url: ->
    '#dashboard'

  show: (params) =>

    # set title
    @title 'Dashboard'

    # highlight navbar
    @navupdate '#dashboard'

  hide: ->
    # no

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

App.Config.set( 'dashboard', DashboardRouter, 'Routes' )
App.Config.set( 'Dashboard', { prio: 100, parent: '', name: 'Dashboard', target: '#dashboard', role: ['Agent'], class: 'dashboard' }, 'NavBar' )
App.Config.set( 'Dashboard', { controller: 'Dashboard', authentication: true }, 'permanentTask' )
