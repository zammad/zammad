class App.SearchableSelect extends Spine.Controller

  events:
    'input .js-input':                  'onInput'
    'blur .js-input':                   'onBlur'
    'focus .js-input':                  'onFocus'
    'click .js-option':                 'selectItem'
    'mouseenter .js-option':            'highlightItem'
    'shown.bs.dropdown':                'onDropdownShown'
    'hidden.bs.dropdown':               'onDropdownHidden'

  elements:
    '.js-option': 'option_items'
    '.js-input': 'input'
    '.js-shadow': 'shadowInput'
    '.js-optionsList': 'optionsList'
    '.js-autocomplete-invisible': 'invisiblePart'
    '.js-autocomplete-visible': 'visiblePart'

  className: 'searchableSelect dropdown dropdown--actions'

  element: =>
    @el

  constructor: ->
    super
    @render()

  render: ->
    firstSelected = _.find @options.attribute.options, (option) -> option.selected

    if firstSelected
      @options.attribute.valueName = firstSelected.name
      @options.attribute.value = firstSelected.value

    @options.attribute.renderedOptions = App.view('generic/searchable_select_options')
      options: @options.attribute.options

    @html App.view('generic/searchable_select')( @options.attribute )

    @input.on 'keydown', @navigate

  onDropdownShown: =>
    @input.on 'click', @stopPropagation
    @highlightFirst()
    @isOpen = true

  onDropdownHidden: =>
    @input.off 'click', @stopPropagation
    @option_items.removeClass '.is-active'
    @isOpen = false

  toggle: =>
    @$('[data-toggle="dropdown"]').dropdown('toggle')

  stopPropagation: (event) ->
    event.stopPropagation()

  navigate: (event) =>
    switch event.keyCode
      when 40 then @nudge event, 1 # down
      when 38 then @nudge event, -1 # up
      when 39 then @fillWithAutocompleteSuggestion event # right
      when 37 then @fillWithAutocompleteSuggestion event # left
      when 13 then @onEnter event
      when 27 then @onEscape()
      when 9 then @onTab event

  onEscape: ->
    @toggle() if @isOpen

  nudge: (event, direction) ->
    return @toggle() if not @isOpen

    event.preventDefault()
    visibleOptions = @option_items.not('.is-hidden')
    highlightedItem = @option_items.filter('.is-active')
    currentPosition = visibleOptions.index(highlightedItem)

    currentPosition += direction

    return if currentPosition < 0
    return if currentPosition > visibleOptions.size() - 1

    @option_items.removeClass('is-active')
    visibleOptions.eq(currentPosition).addClass('is-active')
    @clearAutocomplete()

  fillWithAutocompleteSuggestion: (event) ->
    if !@suggestion
      return

    if event.keyCode is 39 # right
      # end position
      caretPosition = @suggestion.length
    else
      # current position
      caretPosition = @invisiblePart.text().length + 1

    @input.val @suggestion
    @shadowInput.val @suggestionValue
    @clearAutocomplete()
    @toggle()

    @input.prop('selectionStart', caretPosition)
    @input.prop('selectionEnd', caretPosition)

  autocomplete: (value, text) ->
    @suggestion = text
    @suggestionValue = value
    startIndex = text.indexOf(@query)

    if !@query or startIndex != 0
      return @clearAutocomplete()

    @invisiblePart.text(@query)
    @visiblePart.text(text.slice(@query.length))

  clearAutocomplete: ->
    @suggestion = null
    @visiblePart.text('')
    @invisiblePart.text('')

  selectItem: (event) ->
    @input.val event.currentTarget.textContent.trim()
    @input.trigger('change')
    @shadowInput.val event.currentTarget.getAttribute('data-value')
    @shadowInput.trigger('change')

  onTab: (event) ->
    return if not @isOpen
    event.preventDefault()

  onEnter: (event) ->
    @clearAutocomplete()

    if not @isOpen
      if @shadowInput.val() is ''
        event.preventDefault()
        @toggle()
      return

    event.preventDefault()

    @input.val @option_items.filter('.is-active').text().trim()
    @input.trigger('change')
    @shadowInput.val @option_items.filter('.is-active').attr('data-value')
    @shadowInput.trigger('change')
    @toggle()

  onBlur: ->
    @clearAutocomplete()

  onFocus: ->
    textEnd = @input.val().length
    @input.prop('selectionStart', textEnd)
    @input.prop('selectionEnd', textEnd)

  onInput: (event) =>
    @toggle() if not @isOpen

    @query = @input.val()
    @filterByQuery @query

  filterByQuery: (query) ->
    regex = new RegExp(query.split(' ').join('.*'), 'i')

    @option_items
      .addClass 'is-hidden'
      .filter ->
        @textContent.match(regex)
      .removeClass 'is-hidden'

    @highlightFirst(true)

  highlightFirst: (autocomplete) ->
    first = @option_items.removeClass('is-active').not('.is-hidden').first()
    first.addClass 'is-active'

    if autocomplete
      @autocomplete first.attr('data-value'), first.text().trim()

  highlightItem: (event) =>
    @option_items.removeClass('is-active')
    $(event.currentTarget).addClass('is-active')