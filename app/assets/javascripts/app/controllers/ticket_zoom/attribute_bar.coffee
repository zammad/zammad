class App.TicketZoomAttributeBar extends App.Controller
  elements:
    '.buttonDropdown':   'buttonDropdown'

  events:
    'mousedown .js-openDropdownMacro':    'toggleDropdownMacro'
    'click .js-openDropdownMacro':        'stopPropagation'
    'mouseup .js-dropdownActionMacro':    'performTicketMacro'
    'mouseenter .js-dropdownActionMacro': 'onActionMacroMouseEnter'
    'mouseleave .js-dropdownActionMacro': 'onActionMacroMouseLeave'

  constructor: ->
    super

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
    )

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
    macroId = $(e.target).data('id')
    console.log "perform action", @$(e.currentTarget).text(), macroId
    macro = App.Macro.find(macroId)

    @callback(e, macro.perform)
    @closeMacroDropdown()

  onActionMacroMouseEnter: (e) =>
    @$(e.currentTarget).addClass('is-active')

  onActionMacroMouseLeave: (e) =>
    @$(e.currentTarget).removeClass('is-active')