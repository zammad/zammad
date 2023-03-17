class App.SearchableSelect extends Spine.Controller

  events:
    'input .js-input':                                'onInput'
    'blur .js-input':                                 'onBlur'
    'focus .js-input':                                'onFocus'
    'focus .js-shadow':                               'onShadowFocus'
    'change .js-shadow':                              'onShadowChange'
    'click .js-option':                               'selectItem'
    'click .js-option .searchableSelect-option-text': 'selectItem'
    'click .js-enter .searchableSelect-option-text':  'navigateInOrSelectItem'
    'click .searchableSelect-option-arrow':           'navigateIn'
    'click .js-back':                                 'navigateOut'
    'mouseenter .js-option':                          'highlightItem'
    'mouseenter .js-enter':                           'highlightItem'
    'mouseenter .js-back':                            'highlightItem'
    'shown.bs.dropdown':                              'onDropdownShown'
    'hidden.bs.dropdown':                             'onDropdownHidden'
    'keyup .js-input':                                'onKeyUp'
    'click .js-remove:not(.is-disabled)':             'removeThisToken'
    'show.bs.dropdown':                               'onDropdownShow'

  elements:
    '.js-dropdown':               'dropdown'
    '.js-option, .js-enter':      'optionItems'
    '.js-input':                  'input'
    '.js-shadow':                 'shadowInput'
    '.js-optionsList':            'optionsList'
    '.js-optionsSubmenu':         'optionsSubmenu'
    '.js-autocomplete-invisible': 'invisiblePart'
    '.js-autocomplete-visible':   'visiblePart'

  className: 'searchableSelect dropdown dropdown--actions'

  element: =>
    @el

  constructor: ->
    super
    @render()

  render: ->
    @updateAttributeValueName()

    tokens = ''
    if @attribute.multiple && @attribute.value
      relation = @attribute.relation

      # fallback for if the value is not an array
      if typeof @attribute.value isnt 'object'
        @attribute.value = [@attribute.value]

      # create tokens and attribute values
      values = []
      disabled = @attribute.disabled
      if relation
        for dataId in @attribute.value
          if App[relation] && App[relation].exists dataId
            name = App[relation].find(dataId).displayName()
            value = dataId
            values.push({name: name, value: value})
            tokens += App.view('generic/token')(
              name: name
              value: value
              object: relation
              disabled: disabled
            )

      else
        for value in @attribute.value
          values.push({name: value, value: value})
          tokens += App.view('generic/token')(
            name: value
            value: value
            disabled: disabled
          )

      @attribute.value = values

    @html App.view('generic/searchable_select')
      attribute: @attribute
      options: @renderAllOptions('', @attribute.options, 0)
      submenus: @renderSubmenus(@attribute.options)
      tokens: tokens

    @input.get(0).selectValue = @selectValue

    # initial data
    @currentMenu = @findMenuContainingValue(@attribute.value)
    @level = @getIndex(@currentMenu)

  renderSubmenus: (options) ->
    html = ''
    if options
      for option in options
        if option.children
          html += App.view('generic/searchable_select_submenu')(
            options: @renderOptions(option.children)
            parentValue: option.value
            title: option.name
          )
          if @hasSubmenu(option.children)
            html += @renderSubmenus(option.children)
    html

  updateAttributeValueName: ->
    firstSelected = _.find(@attribute.options, (option) -> option.selected)

    if firstSelected
      @attribute.valueName = firstSelected.name
      @attribute.value = firstSelected.value
    else if @attribute.unknown && @attribute.value
      @attribute.valueName = @attribute.value
    else if @hasSubmenu @attribute.options
      @attribute.valueName = @getName(@attribute.value, @attribute.options)

  hasSubmenu: (options) ->
    return false if !options
    for option in options
      return true if option.children
    return false

  getName: (value, options) ->
    for option in options
      if option.value is value
        return option.name
      if option.children
        name = @getName(value, option.children)
        return name if name isnt undefined
    undefined

  renderOptions: (options) ->
    html = ''
    for option in options
      classes = 'u-textTruncate'
      if option.children
        classes += ' js-enter'
      else
        classes += ' js-option'
      if option.category
        classes += ' with-category'

      html += App.view('generic/searchable_select_option')
        option: option
        class: classes
    html

  renderAllOptions: (parentName, options, level) ->
    html = ''
    if options
      for option in options
        className = if option.children then 'js-enter' else 'js-option'
        if level && level > 0
          className += ' is-hidden is-child'

        html += App.view('generic/searchable_select_option')(
          option: option
          class: className
          detail: parentName
        )

        if option.children
          html += @renderAllOptions("#{parentName} — #{option.name}", option.children, level+1)
    html

  onDropdownShow: (event)  =>
    if @attribute.disabled
      event.preventDefault()

  onDropdownShown: =>
    @input.on('click', @stopPropagation)
    @highlightFirst()
    if @level > 0
      @showSubmenu(@currentMenu)
    @isOpen = true

  onDropdownHidden: =>
    @input.off('click', @stopPropagation)
    @unhighlightCurrentItem()
    @isOpen = false

    if !@input.val() && !@attribute.multiple
      @updateAttributeValueName()
      @input.val(@attribute.valueName)
    @input.trigger('change')
    @shadowInput.trigger('change')

  onKeyUp: =>
    return if @input.val().trim() isnt '' || @attribute.multiple
    @shadowInput.val('')

  toggle: =>
    @currentItem = null
    @$('[data-toggle="dropdown"]').dropdown('toggle')

  stopPropagation: (event) ->
    event.stopPropagation()

  navigate: (event) =>
    switch event.keyCode
      when 40 then @nudge(event, 1) # down
      when 38 then @nudge(event, -1) # up
      when 39 then @autocompleteOrNavigateIn(event) # right
      when 37 then @autocompleteOrNavigateOut(event) # left
      when 13 then @onEnter(event)
      when 27 then @onEscape(event)
      when 9 then @onTab(event)
      when 8 # remove last token on backspace
        if @input.val() is '' && @input.is(event.target) && @attribute.multiple
          @removeToken('last')

  onEscape: ->
    if @isOpen
      event.stopPropagation()  # if the input is in a modal, prevent the modal from closing
      @toggle()

  getCurrentOptions: ->
    @currentMenu.find('.js-option, .js-enter, .js-back')

  getOptionIndex: (menu, value) ->
    menu.find('.js-option, .js-enter')
    .filter((i, el) -> $(el).attr('data-value') is value)
    .index()

  nudge: (event, direction) ->
    return @toggle() if not @isOpen

    options = @getCurrentOptions()

    event.preventDefault()
    visibleOptions = options.not('.is-hidden')
    highlightedItem = options.filter('.is-active')
    currentPosition = visibleOptions.index(highlightedItem)

    currentPosition += direction

    return if currentPosition < 0
    return if currentPosition > visibleOptions.length - 1

    @unhighlightCurrentItem()
    @currentItem = visibleOptions.eq(currentPosition)
    @currentItem.addClass('is-active')
    @clearAutocomplete()

  autocompleteOrNavigateIn: (event) ->
    if @currentItem && @currentItem.hasClass('js-enter')
      @navigateIn(event)
    else
      @fillWithAutocompleteSuggestion(event)

  autocompleteOrNavigateOut: (event) ->
    # if we're in a depth then navigateOut
    if @level != 0
      @navigateOut(event)
    else
      @fillWithAutocompleteSuggestion(event)

  fillWithAutocompleteSuggestion: (event) ->
    if !@suggestion
      return

    if event.keyCode is 39 # right
      # end position
      caretPosition = @suggestion.length
    else
      # current position
      caretPosition = @invisiblePart.text().length + 1

    if @attribute.multiple
      @addValueToShadowInput(@suggestion, @suggestionValue)
    else
      @input.val(@suggestion)
      @shadowInput.val(@suggestionValue)
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

  selectValue: (key, value) =>
    @input.val value
    @shadowInput.val key

  navigateInOrSelectItem: (event) ->
    return @selectItem(event) if @attribute.multiple
    return @navigateIn(event)

  selectItem: (event) ->
    currentText = $(event.target).text().trim()
    return if !currentText

    dataId = $(event.target).closest('li').data('value')
    if @attribute.multiple
      @addValueToShadowInput(currentText, dataId)
    else
      @selectValue(dataId, currentText)

  navigateIn: (event) ->
    event.stopPropagation()
    if !@attribute.multiple
      @selectItem(event)
    @navigateDepth(1)

  navigateOut: (event) ->
    event.stopPropagation()
    @navigateDepth(-1)

  navigateDepth: (dir) ->
    return if @animating
    if dir > 0
      target = @currentItem.attr('data-value')
      target_menu = @optionsSubmenu.filter((i, el) -> $(el).attr('data-parent-value') is target)
    else
      target_menu = @findMenuContainingValue(@currentMenu.attr('data-parent-value'))

    @animateToSubmenu(target_menu, dir)

    @level+=dir

  animateToSubmenu: (target_menu, direction) ->
    @animating = true
    target_menu.prop('hidden', false)
    @dropdown.height(Math.max(target_menu.height(), @currentMenu.height()))
    oldCurrentItem = @currentItem

    @currentMenu.data('current_item_index', @currentItem.index())
    # default: 1 (first item after the back button)
    target_item_index = target_menu.data('current_item_index') || 1
    # if the direction is out then we know the target item -> its the parent item
    if direction is -1
      value = @currentMenu.attr('data-parent-value')
      target_item_index = @getOptionIndex(target_menu, value)

    @currentItem = target_menu.children().eq(target_item_index)
    @currentItem.addClass('is-active')

    target_menu.velocity
      properties:
        translateX: [0, direction*100+'%']
      options:
        duration: 240

    @currentMenu.velocity
      properties:
        translateX: [direction*-100+'%', 0]
      options:
        duration: 240
        complete: =>
          oldCurrentItem.removeClass('is-active')
          $.Velocity.hook(@currentMenu, 'translateX', '')
          @currentMenu.prop('hidden', true)
          @dropdown.height(target_menu.height())
          @currentMenu = target_menu
          @animating = false

  showSubmenu: (menu) ->
    @currentMenu.prop('hidden', true)
    menu.prop('hidden', false)
    @dropdown.height(menu.height())

  findMenuContainingValue: (value) ->
    return @optionsList if !value

    # in case of numbers
    if !value.split && value.toString
      value = value.toString()
    path = value.split('::')
    if path.length == 1
      return @optionsList
    else
      path.pop()
      target = path.join('::')
      return @optionsSubmenu.filter((i, el) -> $(el).attr('data-parent-value') is target)

  getIndex: (menu) ->
    return 0 if !menu
    parentValue = menu.attr('data-parent-value')
    return 0 if !parentValue
    return parentValue.split('::').length

  onTab: (event) ->
    return if not @isOpen
    event.preventDefault()

  onEnter: (event) ->
    if @currentItem
      if @currentItem.hasClass('js-back')
        return @navigateOut(event)

    @clearAutocomplete()

    if not @isOpen
      if @shadowInput.val() is ''
        event.preventDefault()
        @toggle()
      else
        @trigger 'enter'
        @el.trigger 'enter'
      return

    event.preventDefault()

    if @currentItem || !@attribute.unknown
      valueName = @currentItem.children('span.searchableSelect-option-text').text().trim()
      value     = @currentItem.attr('data-value')
      if @attribute.multiple
        @addValueToShadowInput(valueName, value)
      else
        @input.val valueName
        @shadowInput.val value
        @shadowInput.trigger('change')

    @input.trigger('change')

    if @currentItem
      if @currentItem.hasClass('js-enter')
        @navigateIn(event)
        @currentItem = null
        return
    @currentItem = null

    @toggle()

  onBlur: ->
    @clearAutocomplete()
    @input.off 'keydown.searchable_select'

  onFocus: ->
    @input.on 'keydown.searchable_select', @navigate
    textEnd = @input.val().length
    @input.prop('selectionStart', textEnd)
    @input.prop('selectionEnd', textEnd)

  # propergate focus to our visible input
  onShadowFocus: ->
    @input.trigger('focus')

  onShadowChange: ->
    value = @shadowInput.val()

    if @attribute.multiple and @currentData
      # create token
      @createToken(@currentData)
      @currentData = null

    if Array.isArray(@attribute.options)
      for option in @attribute.options
        option.selected = (option.value + '') == value # makes sure option value is always a string

  createToken: ({name, value}) =>
    content = {}
    if @attribute.relation
      content =
        name: String(name)
        value: value
        object: @attribute.relation
    else
      content =
        name: String(value)
        value: value

    @input.before App.view('generic/token')(content)

  removeThisToken: (e) =>
    @removeToken $(e.currentTarget).parents('.token')

  removeToken: (which) =>
    switch which
      when 'last'
        token = @$('.token').last()
        return if not token.length
      else
        token = which

    id = token.data('value')
    @shadowInput.find("[value=\"#{id}\"]").remove()
    @shadowInput.trigger('change')
    token.remove()

  onInput: (event) =>
    @toggle() if not @isOpen

    @query = @input.val()
    @filterByQuery @query

    if @attribute.unknown && !@attribute.multiple
      @shadowInput.val @query

  filterByQuery: (query) ->
    query = escapeRegExp(query)
    regex = new RegExp(query.split(' ').join('.*'), 'i')

    @optionsList.addClass 'is-filtered'

    @optionItems
      .addClass 'is-hidden'
      .filter ->
        @textContent.match(regex)
      .removeClass 'is-hidden'

    if !query
      @optionItems.filter('.is-child').addClass 'is-hidden'

    # if all are hidden
    if @attribute.unknown && @optionItems.length == @optionItems.filter('.is-hidden').length
      @optionItems.not('.is-child').removeClass 'is-hidden'
      @unhighlightCurrentItem()
      @optionsList.removeClass 'is-filtered'
    else
      @highlightFirst(true)

  addValueToShadowInput: (currentText, dataId) ->
    @input.val('')

    if @attribute.multiple
      return if @shadowInput.val().includes("#{dataId}") if @shadowInput.val() # cast dataId to string before check
      @currentData = {name: currentText, value: dataId}
    else
      @currentData = {name: currentText, value: dataId}
      return if @shadowInput.val().includes("#{dataId}") if @shadowInput.val() # cast dataId to string before check

    @shadowInput.append($('<option/>').attr('selected', true).attr('value', @currentData.value).text(@currentData.name))
    @onShadowChange()

  highlightFirst: (autocomplete) ->
    @unhighlightCurrentItem()
    @currentItem = @getCurrentOptions().not('.is-hidden').first()
    @currentItem.addClass 'is-active'

    if autocomplete
      @autocomplete @currentItem.attr('data-value'), @currentItem.children('span.searchableSelect-option-text').text().trim()

  highlightItem: (event) =>
    @unhighlightCurrentItem()
    @currentItem = $(event.currentTarget)
    @currentItem.addClass('is-active')

  unhighlightCurrentItem: ->
    return if !@currentItem
    @currentItem.removeClass('is-active')
    @currentItem = null
