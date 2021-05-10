class App.Auth

  @login: (params) ->
    App.Log.debug 'Auth', 'login', params
    params.data['fingerprint'] = App.Browser.fingerprint()
    App.Ajax.request(
      id:     'login'
      type:   'POST'
      url:    App.Config.get('api_path') + '/signin'
      data:   JSON.stringify(params.data)
      success: (data, status, xhr) =>

        # set login (config, session, ...)
        @_login(data)

        # execute callback
        params.success(data, status, xhr)

      error: (xhr, statusText, error) =>
        @_loginError()
        params.error(xhr, statusText, error)
    )

  @loginCheck: (callback) ->
    params =
      fingerprint: App.Browser.fingerprint()
    App.Log.debug 'Auth', 'loginCheck'
    App.Ajax.request(
      id:    'login_check'
      async: false
      type:  'POST'
      url:   App.Config.get('api_path') + '/signshow'
      data:  JSON.stringify(params)
      success: (data, status, xhr) =>

        # set login (config, session, ...)
        @_login(data, 'check')

        if callback
          callback()

      error: (xhr, statusText, error) =>
        @_loginError()
    )

  @logout: (rerender = true, callback) ->
    App.Log.debug 'Auth', 'logout'

    # abort all AJAX requests
    # performed from the App context
    App.Ajax.abortAll()

    # add task to Spine.AJAX queue
    # which will finish all queued requests
    # and perform the logout afterwards
    performLogut = =>

      # clear all following AJAX
      # tasks left in the queue
      Spine.Ajax.clearQueue()

      App.Ajax.request(
        id:   'logout'
        type: 'DELETE'
        url:  App.Config.get('api_path') + '/signout'
        success: =>

          # set logout (config, session, ...)
          @_logout(rerender, callback)

        error: (xhr, statusText, error) =>
          @_loginError()
      )
    Spine.Ajax.queue(performLogut)

  @_login: (data, type) ->
    App.Log.debug 'Auth', '_login:success', data

    # if session is not valid
    if data.error

      # update config
      for key, value of data.config
        App.Config.set(key, value)

      # refresh default collections
      if data.collections
        App.Collection.resetCollections(data.collections)

      # empty session
      App.Session.init()

      # update model definition (needed for not authenticated areas like wizard)
      @_updateModelAttributes(data.models)

      # set locale
      App.i18n.set(App.i18n.detectBrowserLocale())

      # rebuild navbar with new navbar items
      App.Event.trigger('auth')
      App.Event.trigger('auth:failed')
      App.Event.trigger('ui:rerender')
      return false

    # clear local store
    if type isnt 'check'
      App.Event.trigger('clearStore')

    # update model definition
    @_updateModelAttributes(data.models)

    # update config
    for key, value of data.config
      App.Config.set(key, value)

    # refresh default collections
    if data.collections
      App.Collection.resetCollections(data.collections)

    # load assets
    if data.assets
      App.Collection.loadAssets(data.assets)

    # store user data
    App.Session.set(data.session.id)

    # trigger auth ok with new session data
    App.Event.trigger('auth', data.session)

    # init of i18n
    preferences = App.Session.get('preferences')
    if preferences && preferences.locale
      locale = preferences.locale
    if !locale
      locale = App.i18n.detectBrowserLocale()
    App.i18n.set(locale)

    App.Event.trigger('auth:login', data.session)
    App.Event.trigger('ui:rerender')
    App.TaskManager.tasksInitial()

  @_updateModelAttributes: (models) ->
    return if _.isEmpty(models)

    for model, attributes of models
      if App[model]
        if _.isFunction(App[model].updateAttributes)
          App[model].updateAttributes(attributes)

  @_logout: (rerender = true, callback) ->
    App.Log.debug 'Auth', '_logout'

    App.TaskManager.reset()
    App.Session.init()
    App.Ajax.abortAll()

    # clear all in-memory data of all App.Model's
    for model_key, model_object of App
      if _.isFunction(model_object.clearInMemory)
        model_object.clearInMemory()

    App.Event.trigger('auth')
    App.Event.trigger('auth:logout')

    if rerender
      @loginCheck(->
        window.location.href = '#login'
        App.Event.trigger('ui:rerender')
      )
    App.Event.trigger('clearStore')

    if callback
      callback()

  @_loginError: ->
    App.Log.debug 'Auth', '_loginError:error'

    # empty session
    App.Session.init()

    # rebuild navbar
    App.Event.trigger('auth')
    App.Event.trigger('auth:failed')
    App.Event.trigger('ui:rerender')
    App.Event.trigger('clearStore')
