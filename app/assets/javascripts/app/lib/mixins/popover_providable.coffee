InstanceMethods =
  # do not call directly
  initializePopovers: ->
    @el.on('remove', @removePopovers)

    params = _.extend {}, @constructor.popoversDefaults,
      parentController: @

    @initializedPopovers = @selectedPopovers().map (key) ->
      klass = App.Config.get(App.PopoverProvider.providersConfigKey)[key]
      new klass(params)

  # returns all or selected popovers
  selectedPopovers: ->
    if @constructor.allPopovers
      popoversConfig = App.Config.get(App.PopoverProvider.providersConfigKey)
      return Object.keys(popoversConfig)

    return @constructor.registeredPopovers || []

  # do not call directly
  buildPopovers: (buildParams) ->
    for popover in @initializedPopovers
      popover.build(buildParams)

  renderPopovers: (buildParams = {}) ->
    if !@initializedPopovers
      @initializePopovers()

    @buildPopovers(buildParams)

  removePopovers: ->
    return if !@initializedPopovers

    for popover in @initializedPopovers
      popover.clear()

    @initializedPopovers = undefined

  delayedRemoveAnyPopover: ->
    @delay(@constructor.anyPopoversDestroy, 100, 'removePopovers')

App.PopoverProvidable =
  registerPopovers: (klasses...) ->
    @allPopovers = undefined
    @registeredPopovers = klasses

  registerAllPopovers: ->
    @allPopovers = true

  anyPopoversDestroy: ->
    # do not remove permanent .popover--notifications widget
    $('.popover:not(.popover--notifications)').remove()

  extended: ->
    @include InstanceMethods
