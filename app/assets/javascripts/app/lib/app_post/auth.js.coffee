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

        # execute callback
        params.success(data, status, xhr)

      error: (xhr, statusText, error) =>
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
        App.Log.log 'Auth', 'notice', 'logincheck:success', data

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

        # update websocked auth info
        App.WebSocket.auth()

        # refresh/load default collections
        for key, value of data.default_collections
          App.Collection.reset( type: key, data: value )

        # rebuild navbar with new navbar items
        App.Event.trigger 'ajax:auth', data.session

      error: (xhr, statusText, error) =>
        App.Log.log 'Auth', 'notice', 'logincheck:error'

        # empty session
        App.Session.init()

        # clear store
        App.Store.clear('all')

        # update websocked auth info
        App.WebSocket.auth()
    )

  @logout: ->
    App.Log.log 'Auth', 'notice', 'logout'
    App.Com.ajax(
      id:   'logout'
      type: 'DELETE'
      url:  '/signout'
      success: =>

        # update websocked auth info
        App.WebSocket.auth()

        # clear store
        App.Store.clear('all')

      error: (xhr, statusText, error) =>

        # update websocked auth info
        App.WebSocket.auth()
    )