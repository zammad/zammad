class Index extends App.ControllerContent
  divClass: 'lala'
  events:
    'click [data-type="delete"]': 'destroy'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @title 'Sessions', true

    @load()
    @interval(
      =>
        @load()
      45000
    )

  # fetch data, render view
  load: ->
    @ajax(
      id:    'sessions'
      type:  'GET'
      url:   @apiPath + '/sessions'
      success: (data) =>
        @render(data)
    )

  render: (data) ->

    # load assets
    App.Collection.loadAssets( data.assets )

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
    @ajax(
      id:    'sessions/' + sessionId
      type:  'DELETE'
      url:   @apiPath + '/sessions/' + sessionId
      success: (data) =>
        @load()
    )

App.Config.set( 'Session', { prio: 3700, name: 'Sessions', parent: '#system', target: '#system/sessions', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )