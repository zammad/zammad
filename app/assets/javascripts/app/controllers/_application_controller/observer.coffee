class App.ControllerObserver extends App.Controller
  model: 'Ticket'
  template: 'tba'
  globalRerender: true

  ###
  observe:
    title: true

  observeNot:
    title: true

  ###

  constructor: ->
    super
    #console.trace()
    @log 'debug', 'new', @object_id, @model

    if App[@model].exists(@object_id)
      @maybeRender(App[@model].fullLocal(@object_id))
    else
      App[@model].full(@object_id, @maybeRender)

    # rerender, e. g. on language change
    if @globalRerender
      @controllerBind('ui:rerender', =>
        @lastAttributres = undefined
        @maybeRender(App[@model].fullLocal(@object_id))
      )

  subscribe: (object, typeOfChange) =>
    @maybeRender(object, typeOfChange)

  maybeRender: (object, typeOfChange) =>
    if typeOfChange is 'remove'
      @release()
      @el.remove()
      return

    @log 'debug', 'maybeRender', @object_id, object, @model

    if !@subscribeId
      @subscribeId = object.subscribe(@subscribe)

    # remember current attributes
    currentAttributes = {}
    if @observe
      for key, active of @observe
        if active
          currentAttributes[key] = object[key]
    if @observeNot
      for key, value of object
        if key isnt 'cid' && !@observeNot[key] && !_.isFunction(value) && !_.isObject(value)
          currentAttributes[key] = value

    if !@lastAttributres
      @lastAttributres = {}
    else
      diff = difference(currentAttributes, @lastAttributres)
      if _.isEmpty(diff)
        @log 'debug', 'maybeRender no diff, no rerender'
        return

    @log 'debug', 'maybeRender.diff', diff, @observe, @model
    @lastAttributres = currentAttributes

    @render(object, diff)

  render: (object, diff) =>
    @log 'debug', 'render', @template, object, diff
    @html App.view(@template)(
      object: object
    )

    if @renderPost
      @renderPost(object)

  release: =>
    #console.trace()
    @log 'debug', 'release', @object_id, @model, @subscribeId
    App[@model].unsubscribe(@subscribeId)
