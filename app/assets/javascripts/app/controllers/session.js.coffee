class Index extends App.ControllerContent
  divClass: 'lala'
  events:
    'click [data-type="delete"]': 'destroy'

  constructor: ->
    super
    # check authentication
    return if !@authenticate()

    @load()
#    @interval(
#      =>
#        @load()
#      10000
#    )

  # fetch data, render view
  load: ->
    App.Com.ajax(
      id:    'sessions'
      type:  'GET'
      url:   'api/sessions'
      success: (data) =>
        @render(data)
    )

  render: (data) ->
    App.Collection.load( type: 'User', data: data.users )

    # fill users
    for session in data.sessions
      if session.data && session.data.user_id
        session.data.user = App.User.find( session.data.user_id )

    @html App.view('session')(
      sessions: data.sessions
    )

    # show frontend times
    @frontendTimeUpdate()

  destroy: (e) ->
    e.preventDefault()
    sessionId = $( e.target ).data('session-id')
    App.Com.ajax(
      id:    'sessions/' + sessionId
      type:  'DELETE'
      url:   'api/sessions/' + sessionId
      success: (data) =>
        @load()
    )


#App.Config.set( 'session', Session, 'Routes' )
#App.Config.set( 'session', { prio: 3700, parent: '#admin', name: 'Sessions', target: '#session', role: ['Admin'] }, 'NavBar' )

App.Config.set( 'Session', { prio: 3700, name: 'Sessions', parent: '#system', target: '#system/sessions', controller: Index, role: ['Admin'] }, 'NavBarLevel44' )

