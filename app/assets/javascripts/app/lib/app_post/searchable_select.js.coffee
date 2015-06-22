class App.SearchableSelect extends Spine.Controller

  events:
    'input .js-input':                 'filterList'
    'click .js-value':                 'selectItem'
    'mouseenter .js-value':            'highlightItem'
    'shown.bs.dropdown':  'onDropdownShown'
    'hidden.bs.dropdown': 'onDropdownHidden'

  elements:
    '.js-value': 'values'
    '.js-input': 'input'
    '.js-shadow': 'shadowInput'

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

    @html App.view('generic/searchable_select')( @options.attribute )

    @input.on 'keydown', @navigate

  onDropdownShown: =>
    @input.on 'click', @stopPropagation
    @highlightFirst()
    @isOpen = true

  onDropdownHidden: =>
    @input.off 'click', @stopPropagation
    @values.removeClass '.is-active'
    @isOpen = false

  toggle: =>
    @$('[data-toggle="dropdown"]').dropdown('toggle')

  stopPropagation: (event) ->
    event.stopPropagation()

  navigate: (event) =>
    switch event.keyCode
      when 40 then @nudge event, 1 # down
      when 38 then @nudge event, -1 # up
      when 13 then @onEnter event
      when 27 then @onEscape()
      when 9 then @onTab event

  onEscape: ->
    @toggle() if @isOpen

  nudge: (event, direction) ->
    return @toggle() if not @isOpen

    event.preventDefault()
    visibleValues = @values.not('.is-hidden')
    highlightedItem = @values.filter('.is-active')
    currentPosition = visibleValues.index(highlightedItem)

    currentPosition += direction

    return if currentPosition < 0
    return if currentPosition > visibleValues.size() - 1

    @values.removeClass('is-active')
    visibleValues.eq(currentPosition).addClass('is-active')

  selectItem: (event) ->
    @input.val event.currentTarget.textContent.trim()
    @input.trigger('change')
    @shadowInput.val event.currentTarget.getAttribute('data-value')
    @shadowInput.trigger('change')

  onTab: (event) ->
    return if not @isOpen
    event.preventDefault()

  onEnter: (event) ->
    if not @isOpen
      if @shadowInput.val() is ''
        event.preventDefault()
        @toggle()
      return

    event.preventDefault()

    @input.val @values.filter('.is-active').text().trim()
    @input.trigger('change')
    @shadowInput.val @values.filter('.is-active').attr('data-value')
    @shadowInput.trigger('change')
    @toggle()

  filterList: (event) =>
    @toggle() if not @isOpen

    query = @input.val()
    @filterByQuery query

  filterByQuery: (query) ->
    regex = new RegExp(query.split(' ').join('.*'), 'i')

    @values
      .addClass 'is-hidden'
      .filter ->
        this.textContent.match(regex)
      .removeClass 'is-hidden'

    @highlightFirst()

  highlightFirst: ->
    @values.removeClass('is-active').not('.is-hidden').first().addClass 'is-active'

  highlightItem: (event) =>
    @values.removeClass('is-active')
    $(event.currentTarget).addClass('is-active')