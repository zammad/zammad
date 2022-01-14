class App.TicketZoomAttributeBar extends App.Controller
  elements:
    '.js-submitDropdown': 'buttonDropdown'
    '.js-reset':          'resetButton'

  events:
    'mousedown .js-openDropdownMacro':    'toggleMacroMenu'
    'click .js-openDropdownMacro':        'preventDefaultAndStopPropagation'
    'mouseup .js-dropdownActionMacro':    'performTicketMacro'
    'mouseenter .js-dropdownActionMacro': 'onActionMacroMouseEnter'
    'mouseleave .js-dropdownActionMacro': 'onActionMacroMouseLeave'
    'click .js-secondaryAction':          'chooseSecondaryAction'

  searchCondition: {}
  constructor: ->
    super

    @secondaryAction = @getAction()

    @subscribeId = App.Macro.subscribe(@checkMacroChanges)
    @render()

    # rerender, e. g. on language change
    @controllerBind('ui:rerender', =>
      @render()
    )

    @controllerBind('MacroPreconditionUpdate', (data) =>
      return if data.taskKey isnt @taskKey
      @searchCondition = data.params
      @render()
    )

  getAction: ->
    return App.Session.get().preferences.secondaryAction || App.Config.get('ticket_secondary_action') || 'stayOnTab'

  release: =>
    App.Macro.unsubscribe(@subscribeId)

  render: =>

    # remember current reset state
    resetButtonShown = false
    if @resetButton.get(0) && !@resetButton.hasClass('hide')
      resetButtonShown = true

    macros = App.Macro.getList()

    @macroLastUpdated = App.Macro.lastUpdatedAt()
    @possibleMacros   = []

    if _.isEmpty(macros) || @ticket.currentView() is 'customer'
      macroDisabled = true
    else
      for macro in macros
        if !_.isEmpty(macro.group_ids) && @searchCondition.group_id && !_.includes(macro.group_ids, parseInt(@searchCondition.group_id))
          continue

        @possibleMacros.push macro

    localeEl = $(App.view('ticket_zoom/attribute_bar')(
      macros:           @possibleMacros
      macroDisabled:    macroDisabled
      overview_id:      @overview_id
      resetButtonShown: resetButtonShown
    ))
    @setSecondaryAction(@secondaryAction, localeEl)

    if @ticket.currentView() is 'agent'
      @taskbarWatcher = new App.TaskbarWatcher(
        taskKey: @taskKey
        el:      localeEl.filter('.js-avatars')
      )

    @html localeEl

  start: =>
    return if !@taskbarWatcher
    @taskbarWatcher.start()
    @setSecondaryAction(@getAction(), @el)

  stop: =>
    return if !@taskbarWatcher
    @taskbarWatcher.stop()

  checkMacroChanges: =>
    macroLastUpdated = App.Macro.lastUpdatedAt()
    return if macroLastUpdated is @macroLastUpdated
    @render()

  toggleMacroMenu: =>
    if @buttonDropdown.hasClass('is-open')
      @closeMacroMenu()
      return
    @openMacroMenu()

  openMacroMenu: =>
    @buttonDropdown.addClass 'is-open'
    $(document).bind 'click.buttonDropdown', @closeMacroMenu

  closeMacroMenu: =>
    @buttonDropdown.removeClass 'is-open'
    $(document).unbind 'click.buttonDropdown'

  performTicketMacro: (e) =>
    macroId = $(e.currentTarget).data('id')
    macro = App.Macro.find(macroId)

    @callback(e, macro)
    @closeMacroMenu()

  onActionMacroMouseEnter: (e) =>
    @$(e.currentTarget).addClass('is-active')

  onActionMacroMouseLeave: (e) =>
    @$(e.currentTarget).removeClass('is-active')

  chooseSecondaryAction: (e) =>
    type = $(e.currentTarget).find('.js-secondaryActionLabel').data('type')
    @setSecondaryAction(type, @el)
    @setUserPreferencesSecondaryAction(type)

  setSecondaryAction: (type, localEl) ->
    element = localEl.find(".js-secondaryActionLabel[data-type=#{type}]")
    return @setSecondaryAction('stayOnTab', localEl) if element.length == 0
    text = element.text()
    localEl.find('.js-secondaryAction .js-selectedIcon.is-selected').removeClass('is-selected')
    element.closest('.js-secondaryAction').find('.js-selectedIcon').addClass('is-selected')
    localEl.find('.js-secondaryActionButtonLabel').text(text)
    localEl.find('.js-secondaryActionButtonLabel').data('type', type)

  setUserPreferencesSecondaryAction: (type) ->
    session = App.Session.get()
    return if session.preferences.secondaryAction is type

    @ajax(
      id:          'setUserPreferencesSecondaryAction'
      type:        'PUT'
      url:         "#{App.Config.get('api_path')}/users/preferences"
      data:        JSON.stringify(secondaryAction: type)
      processData: true
    )
