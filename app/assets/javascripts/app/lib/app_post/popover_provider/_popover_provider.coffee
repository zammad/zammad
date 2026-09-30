class App.PopoverProvider
  @selectorCssClassPrefix = null # needs to be overrided
  @templateName = null # needs to be overrided
  @titleTemplateName = null # needs to be overrided
  @permission = 'ticket.agent'

  @providersConfigKey = 'PopoverProviders'

  @registerProvider: (key, klass) ->
    # create hash on the fly to avoid issues with class inheritance
    if !@providers
      @providers = {}

    @providers[key] = klass
    App.Config.set(key, klass, @providersConfigKey)

  @defaults =
    position: 'right'
    parentController: null
  popovers = null

  constructor: (params) ->
    if params.parentController is null
      throw 'Parent controller needs to be set'

    @params = _.extend {}, @constructor.defaults, params

  build: (buildParams) ->
    return if !@checkPermissions()
    @clear()
    @bind() if !buildParams.doNotBind
    return if buildParams.isTouchDevice is true
    @buildPopovers()

  checkPermissions: ->
    @params.parentController.permissionCheck(@constructor.permission)

  cssClass: ->
    "#{@constructor.selectorCssClassPrefix}-popover"

  bind: ->

  onHide: (event, elem) ->

  onShow: (event, elem) ->

  buildPopovers: (supplementaryData = {}) ->
    context = @

    selector = supplementaryData.selector || ".#{@cssClass()}"

    elements = @params.parentController.el.find(selector).popover('destroy').popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      sanitize:   false
      animation:  false
      delay:      100
      placement:  "auto #{@params.position}"
      title: ->
        context.buildTitleFor(@, supplementaryData)
      content: ->
        context.buildContentFor(@, supplementaryData)
    )
    elements.on('show.bs.popover', (e) -> context.onShow(e, @))
    elements.on('hide.bs.popover', (e) -> context.onHide(e, @))

    # A re-render strips the old trigger elements' data, so `popover('destroy')` on them is a no-op
    # and leaves an already shown tip behind in the body.
    @popoverInstances = elements.map(-> $(@).data('bs.popover')).get()

  clear: ->
    return if !@popoverInstances
    popover.destroy() for popover in @popoverInstances when popover.$element
    @popoverInstances = null

  hide: ->
    return if !@popoverInstances
    popover.hide() for popover in @popoverInstances

  buildTitleFor: (elem) ->
    'title'

  buildContentFor: (elem) ->
    'content'

  buildHtmlTitle: (params) ->
    App.view("popover/#{@constructor.titleTemplateName}")(params)

  buildHtmlContent: (params) ->
    html = $(App.view("popover/#{@constructor.templateName}")(params))

    html.find('.humanTimeFromNow').each =>
      @params.parentController.frontendTimeUpdateItem($(@))

    html

  displayTitleUsing: (object) ->
    throw 'please override'
