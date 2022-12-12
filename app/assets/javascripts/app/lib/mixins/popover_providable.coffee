InstanceMethods =
  # do not call directly
  initializePopovers: ->
    @el.on 'remove', =>
      @removePopovers()

    @initializeIntersectionObserver()

    params = _.extend {}, @constructor.popoversDefaults,
      parentController: @

    @initializedPopovers = @selectedPopovers().map (key) ->
      klass = App.Config.get(App.PopoverProvider.providersConfigKey)[key]
      new klass(params)

  initializeIntersectionObserver: ->
    # IE11 does not support IntersectionObserver
    # remove this once IE11 support is gone
    return if typeof IntersectionObserver isnt 'function'

    @intersection_observer = new IntersectionObserver (entries) =>
      @intersectionChanged(entries)

    @intersection_observer.observe(@el[0])

  intersectionChanged: (entries) ->
    last = entries[entries.length - 1]

    return if last.isVisible

    return if !@initializedPopovers

    for popover in @initializedPopovers
      popover.hide()

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

    @intersection_observer.disconnect()

    for popover in @initializedPopovers
      popover.clear()

    @initializedPopovers = undefined

  # IE11 does not support IntersectionObserver
  # remove this once IE11 support is gone
  delayedRemoveAnyPopover: ->
    return if typeof IntersectionObserver is 'function'

    @delay(@constructor.anyPopoversDestroy, 100, 'removePopovers')

App.PopoverProvidable =
  registerPopovers: (klasses...) ->
    @allPopovers = undefined
    @registeredPopovers = klasses

  registerAllPopovers: ->
    @allPopovers = true

  anyPopoversDestroy: ->
    # do not remove permanent .popover--notifications widget
    $('.popover:not(.popover--notifications,.popover--richtextpopover)').popover('destroy')

  extended: ->
    @include InstanceMethods
