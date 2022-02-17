class App.ControllerObserver extends App.Controller
  model: 'Ticket'
  template: 'tba'
  globalRerender: true
  lastAttributes: undefined

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
        @lastAttributes = undefined
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

    return if !@hasChanged(object)

    @render(object)

  hasChanged: (object) =>
    currentAttributes = {}

    objectCloned = $.extend(true, {}, object)
    if @observe
      for key, active of @observe
        if active && !_.isFunction(value)
          currentAttributes[key] = objectCloned[key]

    if @observeNot
      for key, value of objectCloned
        if key isnt 'cid' && !@observeNot[key] && !_.isFunction(value)
          currentAttributes[key] = value

    if !@lastAttributes
      @lastAttributes = currentAttributes
      return true

    diff = difference(currentAttributes, @lastAttributes)
    if _.isEmpty(diff)
      @log 'debug', 'maybeRender no diff, no rerender'
      return false

    @log 'debug', 'maybeRender.diff', diff, @observe, @model
    @lastAttributes = currentAttributes

    true

  render: (object) =>
    @log 'debug', 'render', @template, object
    @html App.view(@template)(
      object: object
    )

    if @renderPost
      @renderPost(object)

  release: =>
    #console.trace()
    @log 'debug', 'release', @object_id, @model, @subscribeId
    App[@model].unsubscribe(@subscribeId)
