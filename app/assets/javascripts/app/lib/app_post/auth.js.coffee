$ = jQuery.sub()

class App.Auth

  @login: (params) ->
    App.Log.log 'Auth', 'notice', 'login', params
    App.Com.ajax(
      id:     'login',
      type:   'POST',
      url:     '/signin',
      data:    JSON.stringify(params.data),
      success: (data, status, xhr) =>

        # clear store
        App.Store.clear('all')

        @_login(data)

        # execute callback
        params.success(data, status, xhr)

      error: (xhr, statusText, error) =>
        @_loginError()
        params.error(xhr, statusText, error)
    )

  @loginCheck: ->
    App.Log.log 'Auth', 'notice', 'loginCheck'
    App.Com.ajax(
      id:    'login_check'
      async: false
      type:  'GET'
      url:   '/signshow'
      success: (data, status, xhr) =>
        @_login(data)

      error: (xhr, statusText, error) =>
        @_loginError()
    )

  @logout: ->
    App.Log.log 'Auth', 'notice', 'logout'
    App.Com.ajax(
      id:   'logout'
      type: 'DELETE'
      url:  '/signout'
      success: =>
        @_logout()

      error: (xhr, statusText, error) =>
        @_loginError()
    )

  @_login: (data) ->
    App.Log.log 'Auth', 'notice', '_login:success', data

    # if session is not valid
    if data.error

      # update config
      for key, value of data.config
        App.Config.set( key, value )

      # empty session
      App.Session.init()

      # update websocked auth info
      App.WebSocket.auth()

      # rebuild navbar with new navbar items
      App.Event.trigger 'ajax:auth'

      return false;

    # set avatar
    if !data.session.image
      data.session.image = 'http://placehold.it/48x48'

    # update config
    for key, value of data.config
      App.Config.set( key, value )

    # store user data
    for key, value of data.session
      App.Session.set( key, value )

    # refresh default collections
    for key, value of data.default_collections
      App[key].refresh( value, options: { clear: true } )

    # update websocked auth info
    App.WebSocket.auth()

    # rebuild navbar with user data
    App.Event.trigger 'ajax:auth', data.session


  @_logout: (data) ->
    App.Log.log 'Auth', 'notice', '_logout'

    # update websocked auth info
    App.WebSocket.auth()

    # clear store
    App.Store.clear('all')

  @_loginError: (xhr, statusText, error) ->
    App.Log.log 'Auth', 'notice', '_loginError:error'

    # empty session
    App.Session.init()

    # clear store
    App.Store.clear('all')

    # update websocked auth info
    App.WebSocket.auth()
