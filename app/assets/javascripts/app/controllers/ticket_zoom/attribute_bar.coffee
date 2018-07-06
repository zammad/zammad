class App.TicketZoomAttributeBar extends App.Controller
  @include App.TicketNavigable

  elements:
    '.js-submitDropdown': 'buttonDropdown'
    '.js-reset': 'resetButton'

  events:
    'mousedown .js-openDropdownMacro':    'toggleMacroMenu'
    'click .js-openDropdownMacro':        'stopPropagation'
    'mouseup .js-dropdownActionMacro':    'performTicketMacro'
    'mouseenter .js-dropdownActionMacro': 'onActionMacroMouseEnter'
    'mouseleave .js-dropdownActionMacro': 'onActionMacroMouseLeave'
    'click .js-secondaryAction':          'chooseSecondaryAction'

  constructor: ->
    super

    @secondaryAction = 'stayOnTab'

    @subscribeId = App.Macro.subscribe(@checkMacroChanges)
    @render()

    # rerender, e. g. on language change
    @bind('ui:rerender', =>
      @render()
    )

  release: =>
    App.Macro.unsubscribe(@subscribeId)

  render: =>

    # remember current reset state
    resetButtonShown = false
    if @resetButton.get(0) && !@resetButton.hasClass('hide')
      resetButtonShown = true

    macros = App.Macro.findAllByAttribute('active', true)
    @macroLastUpdated = App.Macro.lastUpdatedAt()

    if _.isEmpty(macros) || !@permissionCheck('ticket.agent')
      macroDisabled = true

    localeEl = $(App.view('ticket_zoom/attribute_bar')(
      macros: macros
      macroDisabled: macroDisabled
      overview_id: @overview_id
      resetButtonShown: resetButtonShown
    ))
    @setSecondaryAction(@secondaryAction, localeEl)

    if @permissionCheck('ticket.agent')
      @taskbarWatcher = new App.TaskbarWatcher(
        taskKey: @taskKey
        el:      localeEl.filter('.js-avatars')
      )

    @html localeEl

  start: =>
    return if !@taskbarWatcher
    @taskbarWatcher.start()

  stop: =>
    return if !@taskbarWatcher
    @taskbarWatcher.stop()

  checkMacroChanges: =>
    macroLastUpdated = App.Macro.lastUpdatedAt()
    return if macroLastUpdated is @macroLastUpdated
    @render()

  toggleMacroMenu: =>
    if @buttonDropdown.hasClass('is-open') then @closeMacroMenu() else @openMacroMenu()

  openMacroMenu: =>
    @buttonDropdown.addClass 'is-open'
    $(document).bind 'click.buttonDropdown', @closeMacroMenu

  closeMacroMenu: =>
    @buttonDropdown.removeClass 'is-open'
    $(document).unbind 'click.buttonDropdown'

  performTicketMacro: (e) =>
    macroId = $(e.currentTarget).data('id')
    macro = App.Macro.find(macroId)

    @callback(e, macro.perform)
    @closeMacroMenu()
    @replaceTabWith(macro.ux_flow_next_up)

  replaceTabWith: (dest) =>
    switch dest
      when 'none'
        return
      when 'next_task'
        @closeTab()
      when 'next_from_overview'
        @closeTab()
        @openNextTicketInOverview()

  onActionMacroMouseEnter: (e) =>
    @$(e.currentTarget).addClass('is-active')

  onActionMacroMouseLeave: (e) =>
    @$(e.currentTarget).removeClass('is-active')

  chooseSecondaryAction: (e) =>
    type = $(e.currentTarget).find('.js-secondaryActionLabel').data('type')
    @setSecondaryAction(type, @el)

  setSecondaryAction: (type, localEl) ->
    element = localEl.find(".js-secondaryActionLabel[data-type=#{type}]")
    text = element.text()
    localEl.find('.js-secondaryAction .js-selectedIcon.is-selected').removeClass('is-selected')
    element.closest('.js-secondaryAction').find('.js-selectedIcon').addClass('is-selected')
    localEl.find('.js-secondaryActionButtonLabel').text(text)
    localEl.find('.js-secondaryActionButtonLabel').data('type', type)
