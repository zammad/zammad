class App.ControllerNavSidbar extends App.Controller
  constructor: (params) ->
    super

    if @authenticateRequired
      @authenticateCheckRedirect()

    @render(true)

    @controllerBind('ui:rerender',
      =>
        @render(true)
        @updateNavigation(true, params)
    )

  show: (params = {}) =>
    @navupdate ''
    @shown = true
    if params
      for key, value of params
        if key isnt 'el' && key isnt 'shown' && key isnt 'match'
          @[key] = value
    @updateNavigation(false, params)
    if @activeController && _.isFunction(@activeController.show)
      @activeController.show(params)

  hide: =>
    @shown = false
    if @activeController && _.isFunction(@activeController.hide)
      @activeController.hide()

  render: (force = false) =>
    groups = @groupsSorted()
    selectedItem = @selectedItem(groups)

    @html App.view('generic/navbar_level2/index')(
      className: @configKey
    )
    @$('.sidebar').html App.view('generic/navbar_level2/navbar')(
      groups: groups
      className: @configKey
      selectedItem: selectedItem
    )

  updateNavigation: (force, params) =>
    groups = @groupsSorted()
    selectedItem = @selectedItem(groups)
    return if !selectedItem
    return if !force && @lastTarget && selectedItem.target is @lastTarget
    @lastTarget = selectedItem.target
    @$('.sidebar li').removeClass('active')
    @$(".sidebar li a[href=\"#{selectedItem.target}\"]").parent().addClass('active')

    @executeController(selectedItem, params)

  groupsSorted: =>

    # get accessable groups
    groups = App.Config.get(@configKey)
    groupsUnsorted = []
    for key, item of groups
      if !item.controller
        if !item.permission
          groupsUnsorted.push item
        else
          match = false
          for permissionName in item.permission
            if !match && @permissionCheck(permissionName)
              match = true
              groupsUnsorted.push item
    _.sortBy(groupsUnsorted, (item) -> return item.prio)

  selectedItem: (groups) =>

    # get items of group
    for group in groups
      items = App.Config.get(@configKey)
      itemsUnsorted = []
      for key, item of items
        if item.parent is group.target
          if item.controller
            if !item.permission
              itemsUnsorted.push item
            else
              match = false
              for permissionName in item.permission
                if !match && @permissionCheck(permissionName)
                  match = true
                  itemsUnsorted.push item

      group.items = _.sortBy(itemsUnsorted, (item) -> return item.prio)

    # set active item
    selectedItem = undefined
    for group in groups
      if group.items
        for item in group.items
          if item.target.match("/#{@target}$")
            item.active = true
            selectedItem = item
          else
            item.active = false

    if !selectedItem
      for group in groups
        break if selectedItem
        if group.items
          for item in group.items
            item.active = true
            selectedItem = item
            break

    selectedItem

  executeController: (selectedItem, params) =>

    if @activeController
      @activeController.el.remove()
      @activeController = undefined

    @$('.main').append('<div>')
    @activeController = new selectedItem.controller(_.extend(params, el: @$('.main div')))

  setPosition: (position) =>
    return if @shown
    return if !position
    if position.main
      @$('.main').scrollTop(position.main)
    if position.sidebar
      @$('.sidebar').scrollTop(position.sidebar)

  currentPosition: =>
    data =
      main: @$('.main').scrollTop()
      sidebar: @$('.sidebar').scrollTop()
