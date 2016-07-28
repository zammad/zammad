class Index extends App.ControllerContent
  events:
    'click .js-delete': 'destroy'

  constructor: ->
    super

    # check authentication
    return if !@authenticate(false, 'Admin')

    @title 'Sessions', true

    @load()
    @interval(
      =>
        @load()
      45000
    )

  # fetch data, render view
  load: ->
    @startLoading()
    @ajax(
      id:    'sessions'
      type:  'GET'
      url:   @apiPath + '/sessions'
      success: (data) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @sessions = data.sessions
        @render()
    )

  render: ->

    # fill users
    for session in @sessions
      if session.data && session.data.user_id
        session.data.user = App.User.find(session.data.user_id)

    @html App.view('session')(
      sessions: @sessions
    )

  destroy: (e) ->
    e.preventDefault()
    sessionId = $(e.target ).closest('a').data('session-id')
    @ajax(
      id:    'sessions/' + sessionId
      type:  'DELETE'
      url:   @apiPath + '/sessions/' + sessionId
      success: (data) =>
        @load()
    )

App.Config.set('Session', { prio: 3800, name: 'Sessions', parent: '#system', target: '#system/sessions', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )