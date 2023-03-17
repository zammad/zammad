class App.ControllerTabs extends App.Controller
  events:
    'click .nav-tabs [data-toggle="tab"]': 'tabRemember'

  constructor: (params) ->
    @originParams = params # remember params for sub-controller
    super(params)

    # check authentication
    if @requiredPermission
      if !@permissionCheckRedirect(@requiredPermission)
        throw "No permission for #{@requiredPermission}"

  show: =>
    return if !@controllerList
    for localeController in @controllerList
      if localeController && localeController.show
        localeController.show()

  hide: =>
    return if !@controllerList
    for localeController in @controllerList
      if localeController && localeController.hide
        localeController.hide()

  render: ->
    @html App.view('generic/tabs')(
      header: @header
      subHeader: @subHeader
      tabs: @tabs
      addTab: @addTab
      headerSwitchName: @headerSwitchName
      headerSwitchChecked: @headerSwitchChecked
    )

    # insert content
    for tab in @tabs
      @$('.tab-content').append("<div class=\"tab-pane\" id=\"#{tab.target}\"></div>")
      if tab.controller
        params = tab.params || {}
        params.name = tab.name
        params.target = tab.target
        params.el = @$("##{tab.target}")
        @controllerList ||= []
        @controllerList.push new tab.controller(_.extend(@originParams, params))

    # check if tabs need to be show / cant' use .tab(), because tabs are note shown (only one tab exists)
    if @tabs.length <= 1
      @$('.tab-pane').addClass('active')
      return

    # set last or first tab to active
    @lastActiveTab = @Config.get('lastTab')
    if @lastActiveTab &&  @$(".nav-tabs li a[href='#{@lastActiveTab}']")[0]
      @$(".nav-tabs li a[href='#{@lastActiveTab}']").tab('show')
    else
      @$('.nav-tabs li:first a').tab('show')

  tabRemember: (e) =>
    @lastActiveTab = $(e.target).attr('href')
    @Config.set('lastTab', @lastActiveTab)
