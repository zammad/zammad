class App.SearchableSelect extends Spine.Controller

  events:
    'input .js-input':                                'onInput'
    'blur .js-input':                                 'onBlur'
    'focus .js-input':                                'onFocus'
    'click .js-input':                                'onClick'
    'focus .js-shadow':                               'onShadowFocus'
    'change .js-shadow':                              'onShadowChange'
    'click .js-option':                               'selectItem'
    'click .js-enter .searchableSelect-option-text':  'selectItem'
    'click .searchableSelect-option-arrow':           'navigateIn'
    'click .searchableSelect-option-button':          'navigateIn'
    'click .js-back':                                 'navigateOut'
    'mouseenter .js-option':                          'highlightItem'
    'mouseenter .js-enter':                           'highlightItem'
    'mouseenter .js-back':                            'highlightItem'
    'shown.bs.dropdown':                              'onDropdownShown'
    'hidden.bs.dropdown':                             'onDropdownHidden'
    'keyup .js-input':                                'onKeyUp'
    'click .js-remove:not(.is-disabled)':             'removeThisToken'
    'show.bs.dropdown':                               'onDropdownShow'
    'keydown .js-clear':                              'onClearKeyDown'

  elements:
    '.js-dropdown':               'dropdown'
    '.js-option, .js-enter':      'optionItems'
    '.js-input':                  'input'
    '.js-shadow':                 'shadowInput'
    '.js-optionsList':            'optionsList'
    '.js-optionsSubmenu':         'optionsSubmenu'
    '.js-autocomplete-invisible': 'invisiblePart'
    '.js-autocomplete-visible':   'visiblePart'
    '.js-clear':                  'clear'

  className: 'searchableSelect controls dropdown dropdown--actions'

  element: =>
    @el

  constructor: ->
    super
    @render()

  render: ->
    @renderElement()

  computeNameValue: (name, translate) ->
    App.TokenHelper.computeNameValue(name, translate)

  prepareTokenContent: ({ name, value, displayName, object, disabled }) =>
    App.TokenHelper.prepareTokenContent({ name, value, displayName, object, disabled, translate: @attribute.translate })

  renderElement: =>
    @updateAttributeOptionDisplayName(@attribute.options)
    @updateAttributeValueName()

    tokens = ''
    if @attribute.multiple && @attribute.value && @attribute.valueType isnt 'json'
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
            values.push({ name: name, value: value })
            tokens += App.view('generic/token')(
              @prepareTokenContent({ name, value, object: relation, disabled })
            )

      else
        for value in @attribute.value
          values.push({ name: value, value: value })
          tokens += App.view('generic/token')(
            @prepareTokenContent({ name: value, value, disabled })
          )

      @attribute.value = values

    @html App.view('generic/searchable_select')
      attribute: @attribute
      options: @renderAllOptions('', @attribute.options, 0)
      submenus: @renderSubmenus(@attribute.options)
      tokens: @attribute.existingTokens or tokens

    @input.get(0).selectValue = @selectValue

    # initial data
    @lastValue   = @attribute.value
    @currentMenu = @findMenuContainingValue(@attribute.value)

    @clear.on('click.searchable_select', @clearValue)

    @el.addClass('searchableSelect-dropdown-up') if @attribute.direction == 'up'

  renderSubmenus: (options, level = 1) ->
    html = ''
    if options
      for option in options
        if option.children
          html += App.view('generic/searchable_select_submenu')(
            options: @renderOptions(option.children)
            parentValue: option.value
            title: option.name
            level: level
          )
          if @hasSubmenu(option.children)
            html += @renderSubmenus(option.children, level + 1)
    html

  updateAttributeOptionDisplayName: (options, parentNames = []) =>
    return if _.isEmpty(options)

    for option in options
      currentPath = _.clone(parentNames)
      currentPath.push(option.name)

      option.displayName = @displayName(currentPath)

      if option.children
        @updateAttributeOptionDisplayName(option.children, currentPath)

  displayName: (path) ->
    # We leave it to the browser to "invert" the chevron on RTL languages.
    #   This happens automatically for inlined RTL text since chevron is considered punctuation.
    path.join(' › ')

  updateAttributeValueName: ->
    firstSelected = @findFirstSelection(@attribute.options)

    if firstSelected
      @attribute.valueName = firstSelected.name
      @attribute.value = firstSelected.value
      @attribute.displayName = firstSelected.displayName
    else if @attribute.unknown && @attribute.value
      @attribute.valueName = @attribute.value
      @attribute.displayName = @attribute.valueName
    else if @hasSubmenu @attribute.options
      @attribute.valueName = @getName(@attribute.value, @attribute.options)
      @attribute.displayName = @getDisplayName(@attribute.value, @attribute.options)

  findFirstSelection: (options) ->
    return if !options
    for option in options
      return option if option.selected
      if option.children
        selectedOption = @findFirstSelection(option.children)
        return selectedOption if selectedOption

  hasSubmenu: (options) ->
    return false if !options
    for option in options
      return true if option.children
    return false

  getName: (value, options) ->
    for option in options
      if option.value?.toString() is value?.toString()
        return option.name
      if option.children
        name = @getName(value, option.children)
        return name if name isnt undefined
    undefined

  getDisplayName: (value, options) ->
    for option in options
      if option.value?.toString() is value?.toString()
        return option.displayName
      if option.children
        displayName = @getDisplayName(value, option.children)
        return displayName if displayName isnt undefined
    undefined

  isOptionSelected: (option) =>
    return true if @attribute.multiple and _.some(@attribute.value or [], (val) -> option.value?.toString() is val.value.toString())
    return true if option.value?.toString() is @attribute.value?.toString()
    false

  renderOptions: (options) =>
    html = ''
    for option in options
      classes = 'u-textTruncate'
      if option.children
        classes += ' js-enter'
      else
        classes += ' js-option'
      if option.category
        classes += ' with-category'
      if option.inactive and option.children
        classes += ' inactive-with-children'

      template =
        if option.inactive and option.children
          'generic/searchable_select_option_inactive_with_children'
        else
          'generic/searchable_select_option'

      html += App.view(template)
        class:      classes
        isSelected: @isOptionSelected(option)
        option:     option

    html

  renderAllOptions: (parentName, options, level) =>
    html = ''
    if options
      for option in options
        className = if option.children then 'js-enter' else 'js-option'
        if level && level > 0
          className += ' is-hidden is-child'
        if option.inactive and option.children
          className += ' inactive-with-children'

        template =
          if option.inactive and option.children
            'generic/searchable_select_option_inactive_with_children'
          else
            'generic/searchable_select_option'

        html += App.view(template)
          class:      className
          detail:     parentName
          isSelected: @isOptionSelected(option)
          option:     option

        if option.children
          # We leave it to the browser to "invert" the chevron on RTL languages.
          #   This happens automatically for inlined RTL text since chevron is considered punctuation.
          delimiter = if level is 0 then '—' else '›'
          html += @renderAllOptions("#{parentName} #{delimiter} #{option.name}", option.children, level + 1)
    html

  onDropdownShow: (event)  =>
    if @attribute.disabled
      event.preventDefault()

  onDropdownShown: =>
    if !@isOpen && !@attribute?.ajax
      @resetSearch()

    @input.on('click', @stopPropagation)

    @highlightFirst()
    if @getIndex(@currentMenu) > 0
      @showSubmenu(@currentMenu)
    @isOpen = true

    @toggleClear()

  onDropdownHidden: =>
    @input.off('click', @stopPropagation)
    @unhighlightCurrentItem()
    @isOpen = false
    @resetAutocomplete()

    if !@input.val() && !@attribute.multiple
      @updateAttributeValueName()
      @input.val(@attribute.valueName)
        .attr('title', @attribute.displayName)
    @input.trigger('change')
    @shadowInput.trigger('change')

    @toggleClear()

  resetAutocomplete: =>
    return if not @query or @query isnt @input.val()

    @query = ''
    @input.val(@query)
    @filterByQuery(@query)

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
      @input.trigger('blur')

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
    @currentItem.addClass('is-highlighted') if @currentItem.hasClass('js-enter')
    @clearAutocomplete()

  autocompleteOrNavigateIn: (event) ->
    if not @query and @currentItem?.hasClass('js-enter')
      @navigateIn(event)
    else
      @fillWithAutocompleteSuggestion(event)

  autocompleteOrNavigateOut: (event) ->
    # if we're in a depth then navigateOut
    if @getIndex(@currentMenu) != 0
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
        .attr('title', @suggestion)
      @shadowInput.val(@suggestionValue)
    @clearAutocomplete()
    if not @attribute.multiple
      @toggle()
      @input.trigger('blur')

    @input.prop('selectionStart', caretPosition)
    @input.prop('selectionEnd', caretPosition)

  autocomplete: (value, text) ->
    return if @attribute.multiple

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

  resetSearch: =>
    @input.val('')
      .removeAttr('title')
    @onInput(null, false)

  setMenuByLastValue: =>
    @currentMenu.prop('hidden', true)
    @currentMenu = @findMenuContainingValue(@lastValue)
    @currentMenu.prop('hidden', false)

  selectValue: (value, currentText, displayName) =>
    @resetSearch()

    @input.val(currentText)
      .attr('title', displayName)
    @shadowInput.val(value)

    @attribute.valueName = currentText
    @attribute.value     = value
    @lastValue           = value

    @setMenuByLastValue()

  selectItem: (event) ->
    row = $(event.currentTarget).closest('li')

    if row.is('.has-inactive')
      event.stopPropagation()
      return

    currentText = row.find('[role=option]')[0]?.firstChild?.textContent?.trim()
    return if not currentText

    dataId     = row.data('value')
    @lastValue = dataId

    if @attribute.multiple
      event.stopPropagation()
      @addValueToShadowInput(currentText, dataId, row.data('displayName'))
    else
      @selectValue(dataId, currentText, row.data('displayName'))
      @toggleClear()

    @setMenuByLastValue()
    @markSelected(dataId)

  markSelected: (value) ->
    if not @attribute.multiple
      @el.find('li')
        .removeClass('is-selected')

    @el.find("li[data-value='#{jQuery.escapeSelector(value)}']")
      .addClass('is-selected')

  unmarkSelected: (value) ->
    return if not @attribute.multiple

    @el.find("li[data-value='#{jQuery.escapeSelector(value)}']")
      .removeClass('is-selected')

  navigateIn: (event) ->
    event.stopPropagation()
    @navigateDepth(1)

  navigateOut: (event) ->
    event.stopPropagation()
    @navigateDepth(-1)

  navigateDepth: (dir) ->
    return if @animating or not @currentItem
    if dir > 0
      target = @currentItem.attr('data-value')
      target_menu = @optionsSubmenu.filter((i, el) -> $(el).attr('data-parent-value') is target)
    else
      target_menu = @findMenuContainingValue(@currentMenu.attr('data-parent-value'))

    @animateToSubmenu(target_menu, dir)

  animateToSubmenu: (target_menu, direction) ->
    @animating = true
    target_menu.prop('hidden', false)
    @dropdown.height(Math.max(target_menu.height(), @currentMenu.height()))
    oldCurrentItem = @currentItem

    @currentMenu.data('current_item_index', @currentItem.index())

    # by default always start from the back button
    target_item_index = 0

    # if the direction is out then we know the target item -> its the parent item
    if direction is -1
      value = @currentMenu.attr('data-parent-value')
      target_item_index = @getOptionIndex(target_menu, value)

    @currentItem = target_menu.children().eq(target_item_index)
    @currentItem.addClass('is-active is-highlighted')

    target_menu.velocity
      properties:
        translateX: [0, direction * 100 + '%']
      options:
        duration: 240
        complete: ->
          target_menu.css('translateX', '').css('transform', '')

    if @attribute.direction == 'up'
      @dropdown.css('overflow-y', 'hidden')

    @currentMenu.velocity
      properties:
        translateX: [direction * -100 + '%', 0]
      options:
        duration: 240
        complete: =>
          if @attribute.direction == 'up'
            @dropdown.css('overflow-y', 'auto')

          oldCurrentItem.removeClass('is-active')
          oldCurrentItem.removeClass('is-highlighted') if oldCurrentItem.hasClass('js-enter')
          @currentMenu.prop('hidden', true)
          @currentMenu.css('translateX', '').css('transform', '')
          @dropdown.height(target_menu.height())
          @currentMenu = target_menu
          @animating = false

  showSubmenu: (menu) ->
    @currentMenu.prop('hidden', true)
    menu.prop('hidden', false)
    @dropdown.height(menu.height())

  findParentOptionByValue: (options, value, lastParent) ->
    return if !options

    for option in options
      return lastParent if option.value?.toString() is value?.toString()

      parent = @findParentOptionByValue(option.children, value, option)
      return parent if parent

  findMenuContainingValue: (value) ->
    return @optionsList if !@attribute.options or !value

    parent = @findParentOptionByValue(@attribute.options, value)
    return @optionsList if !parent

    @optionsSubmenu.filter((i, el) -> $(el).attr('data-parent-value') is parent.value.toString())

  getIndex: (menu) ->
    return 0 if !menu
    return parseInt(menu.attr('data-level')) || 0

  onTab: (event) ->
    if not @isOpen
      @input.off('click', @stopPropagation)
      @resetAutocomplete()

      if !@input.val() && !@attribute.multiple
        @updateAttributeValueName()
        @input.val(@attribute.valueName)
          .attr('title', @attribute.displayName)

      @toggleClear()
      return

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
      return if @currentItem.hasClass('has-inactive') or @currentItem.hasClass('inactive-with-children')

      valueName   = @currentItem.children('span.searchableSelect-option-text').text().trim()
      value       = @currentItem.attr('data-value')
      displayName = @currentItem.data('displayName')
      if @attribute.multiple
        @addValueToShadowInput(valueName, value, displayName)
      else
        @selectValue(value, valueName, displayName)
        @toggleClear()

      @markSelected(value)
      @currentItem.removeClass('is-active')
      @currentItem.removeClass('is-highlighted') if @currentItem.hasClass('js-enter')
      @currentItem = null

    @input.trigger('change')

    if not @attribute.multiple
      @toggle()
      @input.trigger('blur')

  onBlur: ->
    @clearAutocomplete()
    @input.off 'keydown.searchable_select'

  onFocus: ->
    @initialValue = @input.val()
    @input.on 'keydown.searchable_select', @navigate

  onClick: ->
    # Clear the input value so the user can start searching immediately (#4830).
    # Regression which provoked (#5335)
    @resetSearch()

  # propergate focus to our visible input
  onShadowFocus: ->
    @toggle() if not @isOpen
    @input.trigger('focus')

  onShadowChange: =>
    value = @shadowInput.val()

    if @attribute.multiple and @currentData
      # create token
      @createToken(@currentData)
      @currentData = null

    @updateAttributeOptionSelected(@attribute.options, value)

  updateAttributeOptionSelected: (options, value) =>
    return if _.isEmpty(options)

    for option in options
      if @attribute.multiple
        option.selected = _.includes(value or [], option.value.toString())
      else
        option.selected = option.value.toString() is value?.toString()

      if option.children
        @updateAttributeOptionSelected(option.children, value)

  createToken: ({ name, value, displayName }) =>
    content = @prepareTokenContent({ name, value, displayName, object: @attribute.relation })
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
    @shadowInput.find("[value=\"#{jQuery.escapeSelector(id)}\"]").remove()
    @shadowInput.trigger('change')
    @unmarkSelected(id)
    token.remove()

  onInput: (event, doToggle = true) =>
    @toggle() if not @isOpen && doToggle

    @query = @input.val()
    @filterByQuery @query

    if @attribute.unknown && !@attribute.multiple
      @shadowInput.val @query

  filterByQuery: (query) ->
    if (query && query.length > 0) || @getIndex(@currentMenu) == 0 || !@lastValue
      @currentMenu.prop('hidden', true)
      @optionsList.prop('hidden', false)
      @currentMenu = @optionsList
    else
      @setMenuByLastValue()

    query = escapeRegExp(query)
    regex = new RegExp(query.split(' ').join('.*'), 'i')

    @optionsList.addClass 'is-filtered'

    @optionItems
      .addClass 'is-hidden'
      .filter ->
        @textContent.match(regex)
      .removeClass 'is-hidden'

    if query
      @optionsList.addClass 'has-query'
      @optionItems.filter('.inactive-with-children').addClass 'is-hidden'
    else
      @optionsList.removeClass 'has-query'
      @optionItems.filter('.is-child').addClass 'is-hidden'

    # if all are hidden
    if @attribute.unknown && @optionItems.length == @optionItems.filter('.is-hidden').length
      @optionItems.not('.is-child').removeClass 'is-hidden'
      @unhighlightCurrentItem()
      @optionsList.removeClass 'is-filtered'
    else
      @highlightFirst(true)

    if @currentMenu.height() > 0
      @dropdown.height(@currentMenu.height())

  addValueToShadowInput: (currentText, dataId, displayName = null) ->
    @resetSearch()

    if @attribute.multiple
      return if @shadowInput.val().includes("#{dataId}") if @shadowInput.val() # cast dataId to string before check
      @currentData = { name: currentText, value: dataId, displayName: displayName }
    else
      @currentData = { name: currentText, value: dataId, displayName: displayName }
      return if @shadowInput.val().includes("#{dataId}") if @shadowInput.val() # cast dataId to string before check

    displayTextToUse = displayName || currentText
    @shadowInput.append($('<option/>').attr('selected', true).attr('value', @currentData.value).text(displayTextToUse))
    @onShadowChange()

  highlightFirst: (autocomplete) ->
    return if autocomplete and document.activeElement isnt @input.get(0)

    @unhighlightCurrentItem()
    @currentItem = @getCurrentOptions().not('.is-hidden').first()
    @currentItem.addClass('is-active')
    @currentItem.addClass('is-highlighted') if @currentItem.hasClass('js-enter')

    if autocomplete
      @autocomplete @currentItem.attr('data-value'), @currentItem.children('span.searchableSelect-option-text').text().trim()

  highlightItem: (event) =>
    @unhighlightCurrentItem()
    @currentItem = $(event.currentTarget)
    @currentItem.addClass('is-active')

  unhighlightCurrentItem: ->
    return if !@currentItem
    @currentItem.removeClass('is-active')
    @currentItem.removeClass('is-highlighted') if @currentItem.hasClass('js-enter')
    @currentItem = null

  toggleClear: =>
    return if @attribute.multiple

    if @attribute.value?.toString().length
      @clear.removeClass('hide')
    else
      @clear.addClass('hide')

  clearValue: =>
    event.stopPropagation()

    @selectValue('', '', '')
    @input.trigger('change')
    @shadowInput.trigger('change')
    @markSelected('')
    @toggleClear()

  onClearKeyDown: (event) =>
    switch event.keyCode
      when 13 then @clearValue() # enter
      when 32 then @clearValue() # space
