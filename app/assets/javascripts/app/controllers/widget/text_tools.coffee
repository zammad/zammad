class App.WidgetTextTools extends App.Controller
  searchCondition: {}

  constructor: ->
    super

    @searchCondition = @data.ticket || {}

    # remember instances
    @bindElements = []
    if @selector
      @$(@selector).data('plugin_texttools', {})
      @bindElements = @$(@selector)
    else
      if @el.attr('contenteditable')
        @el.data('plugin_texttools', {})
        @bindElements = @el
      else
        @$('[contenteditable]').data('plugin_texttools', {})
        @bindElements = @$('[contenteditable]')
    @update()

    @subscribeId = App.AITextTool.subscribe(@update, initFetch: true)

    @controllerBind('TextToolsPreconditionUpdate', (data) =>
      return if data.taskKey isnt @taskKey
      @searchCondition = $.extend({}, @searchCondition, data.params)
      @update()
    )

  release: =>
    App.AITextTool.unsubscribe(@subscribeId)

  reload: (data) =>
    return if !data
    @data            = data
    @searchCondition = @data.ticket
    @update()

  currentCollection: =>
    @all

  update: =>
    allRaw = App.AITextTool.getList()
    @all = []

    # Get group IDs that match ticket create form.
    # This will be used to handle empty group_id cases.
    userGroupIds = _.map @data.user.allGroupIds('create'), (elem) -> parseInt(elem)

    for item in allRaw
      if !_.isEmpty(item.group_ids)
        if @searchCondition.group_id
          continue if !_.includes(item.group_ids, parseInt(@searchCondition.group_id))
        else
          # Show text tools that are available in one of the user's groups
          continue if _.intersection(item.group_ids, userGroupIds).length == 0

      attributes = item.attributes()
      @all.push attributes

    # set new data
    for element in @bindElements or []
      continue if !$(element).data().plugin_texttools

      $(element).data().plugin_texttools.searchCondition = @searchCondition
      $(element).data().plugin_texttools.collection      = @all

  @enabled: ->
    App.Config.get('ai_assistance_text_tools') and App.Config.get('ai_provider')

  @availableTextTools: (ce) ->
    $(ce.element).data().plugin_texttools?.collection or []

  @hasAvailableTextTools: (ce) ->
    @availableTextTools(ce).length

  @contextData: (ce) ->
    $(ce.element).data().plugin_texttools?.searchCondition or {}

  @showModal: (e, ce, selection, el) ->
    textToolId = $(e.target).data('id')

    new App.TextToolsModal(
      container: el.closest('.content')
      contextData: @contextData(ce)
      textTool: App.AITextTool.find(textToolId)
      selectedText: selection.content
      approve: (result) -> ce.replaceSelection(selection.ranges, result)
    )

  @renderDropdown: (e, ce, selection, el) ->
    bubbleMenuElement = $(e.target).closest('.js-bubbleMenu')
    popupContainerElement = bubbleMenuElement.find('.dropup-container')

    popupContainerElement.parent().removeClass('show-dropdown')
    dropdownMenu = popupContainerElement.find('.dropdown-menu')

    return dropdownMenu.remove() if dropdownMenu.length
    return if !App.WidgetTextTools.hasAvailableTextTools(ce)

    popupContainerElement.parent().addClass('show-dropdown')

    textToolsDropdown = $(App.view('generic/text_tools_dropdown')(items: App.WidgetTextTools.availableTextTools(ce), disabled: false))

    popupContainerElement.html(textToolsDropdown)

    textToolsDropdown.off('mousedown.text-tools-dropdown').on 'mousedown.text-tools-dropdown', '.js-action', (e) ->
      e.preventDefault()
      App.WidgetTextTools.showModal(e, ce, selection, el)
      textToolsDropdown.removeClass('open')
      popupContainerElement.parent().removeClass('show-dropdown')

      return false

    # Position the dropdown menu on the right side of the dropdown container when in RTL locale.
    if App.i18n.dir() is 'rtl'
      popupContainerElement
        .css('left', 'auto')
        .css('right', "#{textToolsDropdown.find('.dropdown-menu').width()}px")

    textToolsDropdown.addClass('open')
