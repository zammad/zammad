class App.PopoverProvider
  @selectorCssClassPrefix = null # needs to be overrided
  @templateName = null # needs to be overrided
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
    @clear(@popovers)
    @bind()
    @popovers = @buildPopovers()

  checkPermissions: ->
    @params.parentController.permissionCheck(@constructor.permission)

  cssClass: ->
    "#{@constructor.selectorCssClassPrefix}-popover"

  bind: ->

  buildPopovers: (supplementaryData = {}) ->
    context = @

    selector = supplementaryData.selector || ".#{@cssClass()}"

    @params.parentController.el.find(selector).popover(
      trigger:    'hover'
      container:  'body'
      html:       true
      animation:  false
      delay:      100
      placement:  "auto #{@params.position}"
      title: ->
        context.buildTitleFor(@, supplementaryData)
      content: ->
        context.buildContentFor(@, supplementaryData)
    )

  clear: ->
    return if !@popovers
    @popovers.popover('destroy')

  buildTitleFor: (elem) ->
    'title'

  buildContentFor: (elem) ->
    'content'

  buildHtmlContent: (params) ->
    html = $(App.view("popover/#{@constructor.templateName}")(params))

    html.find('.humanTimeFromNow').each =>
      @params.parentController.frontendTimeUpdateItem($(@))

    html

  displayTitleUsing: (object) ->
    throw 'please override'

