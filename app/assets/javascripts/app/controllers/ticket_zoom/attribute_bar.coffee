class App.TicketZoomAttributeBar extends App.Controller
  elements:
    '.js-submitDropdown': 'buttonDropdown'
    '.js-secondaryActionButtonLabel': 'secondaryActionButton'

  events:
    'mousedown .js-openDropdownMacro':    'toggleDropdownMacro'
    'click .js-openDropdownMacro':        'stopPropagation'
    'mouseup .js-dropdownActionMacro':    'performTicketMacro'
    'mouseenter .js-dropdownActionMacro': 'onActionMacroMouseEnter'
    'mouseleave .js-dropdownActionMacro': 'onActionMacroMouseLeave'
    'click .js-secondaryAction':          'chooseSecondaryAction'

  constructor: ->
    super

    @secondaryAction = @preferencesGet() || 'stayOnTab'
    if !@overview_id && @secondaryAction is 'closeNextInOverview'
      @secondaryAction = 'closeTab'

    @subscribeId = App.Macro.subscribe(@render)
    @render()

  release: =>
    App.Macro.unsubscribe(@subscribeId)

  render: =>
    macros = App.Macro.all()
    if _.isEmpty(macros) || !@isRole('Agent')
      macroDisabled = true
    @html App.view('ticket_zoom/attribute_bar')(
      macros: macros
      macroDisabled: macroDisabled
      overview_id: @overview_id
    )
    @setSecondaryAction()

  toggleDropdownMacro: =>
    if @buttonDropdown.hasClass 'is-open'
      @closeMacroDropdown()
    else
      @buttonDropdown.addClass 'is-open'
      $(document).bind 'click.buttonDropdown', @closeMacroDropdown

  closeMacroDropdown: =>
    @buttonDropdown.removeClass 'is-open'
    $(document).unbind 'click.buttonDropdown'

  performTicketMacro: (e) =>
    macroId = $(e.currentTarget).data('id')
    console.log 'perform action', @$(e.currentTarget).text(), macroId
    macro = App.Macro.find(macroId)

    @callback(e, macro.perform)
    @closeMacroDropdown()

  onActionMacroMouseEnter: (e) =>
    @$(e.currentTarget).addClass('is-active')

  onActionMacroMouseLeave: (e) =>
    @$(e.currentTarget).removeClass('is-active')

  chooseSecondaryAction: (e) =>
    type = $(e.currentTarget).find('.js-secondaryActionLabel').data('type')
    @setSecondaryAction(type)

  setSecondaryAction: (type = @secondaryAction) =>
    element = @$(".js-secondaryActionLabel[data-type=#{type}]")
    text = element.text()
    @$('.js-secondaryAction .js-selectedIcon.is-selected').removeClass('is-selected')
    element.closest('.js-secondaryAction').find('.js-selectedIcon').addClass('is-selected')
    @secondaryActionButton.text(text)
    @secondaryActionButton.data('type', type)
    App.LocalStorage.set(@preferencesStoreKey(), type, @Session.get('id'))

  preferencesGet: =>
    App.LocalStorage.get(@preferencesStoreKey(), @Session.get('id'))

  preferencesStoreKey: =>
    "ticketZoom:taskAktion:#{@ticket_id}"
