# coffeelint: disable=camel_case_classes
class App.UiElement.ticket_selector extends App.UiElement.ApplicationSelector
  @subclauseContainer: (level = 0, operator = 'AND') ->
    isFirst = level is 0
    subclause = $( App.view('generic/application_selector_subclause')(
      level: level
      is_first: isFirst
    ) )
    selector = @buildSubclauseSelector(operator)
    subclause.find('.js-subclauseSelector').prepend(selector)
    subclause

  @rowContainer: (groups, elements, attribute, level = 1) ->
    if !@hasExpertConditions() or !@isExpertMode
      return super

    row = $( App.view('generic/application_selector_row')(
      attribute: attribute
      pre_condition: @HasPreCondition()
      has_expert_conditions: @hasExpertConditions()
      level: level
    ) )
    selector = @buildAttributeSelector(groups, elements)
    row.find('.js-attributeSelector').prepend(selector)
    row

  @prepareParamValue: (item, elements, attribute, params) ->
    paramValue = {}

    return paramValue if !params?[attribute.name]

    selector = params[attribute.name]

    if @hasExpertConditions() and @isExpertMode
      paramValue = @migrateSelector(selector)
    else
      if @isSelectorIncompatible(selector)
        @showAlert(
          __('Caution!'),
          __('You disabled the expert mode. This will downgrade all expert conditions and can lead to data loss in your condition attributes. Please check your conditions before saving.'),
          item
        )

      selector = @downgradeSelector(selector)

      for groupAndAttribute, meta of selector
        continue if !elements[groupAndAttribute]
        paramValue[groupAndAttribute] = meta

    # Also update the value directly in the attribute hash.
    attribute.value = paramValue

    paramValue

  @migrateSelector: (selector) ->
    return selector if selector.conditions

    result = {
      operator: 'AND',
      conditions: [],
    }

    _.each(_.keys(selector), (key) ->
      result.conditions.push(_.extend({ name: key }, selector[key]))
    )

    result

  @isSelectorIncompatible: (selector) ->
    return false if !selector?.conditions

    # A selector is considered to be incompatible with the expert mode turned off if:
    #   - the root subclause is set to anything other than 'AND'
    #   - in case it contains nested subclauses
    #   - the same attribute is used multiple times
    return true if selector.operator isnt 'AND'

    seenAttributes = {}

    for condition in selector.conditions
      if condition.conditions
        return true

      if seenAttributes[condition.name]
        return true

      seenAttributes[condition.name] = true

  @downgradeSelector: (selector) ->
    return selector if !selector.conditions

    result = {}

    for condition in selector.conditions
      continue if condition.conditions
      continue if !condition.name

      result[condition.name] = _.omit(condition, 'name')

    result

  @render: (attribute, params = {}) ->
    @params = params

    # Turn on the expert mode automatically if the currently stored selector already contains expert conditions.
    @isExpertMode = (@hasExpertConditions() and @isSelectorIncompatible(@params[attribute.name])) or
                    attribute.always_expert_mode

    item = $( App.view('generic/application_selector')(
      attribute: attribute
      has_expert_conditions: @hasExpertConditions()
      is_expert_mode: @isExpertMode
    ) )

    item.off('change.application_selector', '.js-switch input').on('change.application_selector', '.js-switch input', (e) =>
      toggleSwitch = $(e.target)
      newValue = toggleSwitch.prop('checked')

      callback = =>
        @isExpertMode = newValue
        item.find('.js-filterElement').remove()
        @renderItem(item, attribute, @params)

        if attribute.preview isnt false
          @preview(item)

      # In case the selector contains expert conditions, warn the user before switching off the expert mode.
      if !newValue and @isSelectorIncompatible(@params[attribute.name])
        return new App.ControllerConfirm(
          head: __('Are you sure?')
          message: __('Ticket selector contains expert conditions. If you turn off the expert mode, it can lead to data loss in your condition attributes.')
          callback: callback
          onCancel: ->
            toggleSwitch.prop('checked', true)
          container: @el
          small: true
        )

      callback()
    )

    @renderItem(item, attribute, @params)

  @renderItem: (item, attribute, params) ->
    if !@hasExpertConditions() or !@isExpertMode
      return super

    [defaults, groups, elements] = @defaults(attribute, params)

    defaults.unshift('subclause')

    # add filter
    item.off('click.application_selector', '.js-add').on('click.application_selector', '.js-add', (e) =>
      element = $(e.target).closest('.js-filterElement')
      level = @getPreviousElementLevel(element)

      # add first available attribute
      field = undefined
      for groupAndAttribute, _config of elements
        if @hasDuplicateSelector()
          field = groupAndAttribute
          break
        else if !item.find(".js-attributeSelector [value=\"#{groupAndAttribute}\"]:selected").get(0)
          field = groupAndAttribute
          break
      return if !field
      row = @rowContainer(groups, elements, attribute, level)

      emptyRow = item.find('div.horizontal-filter-body')
      if emptyRow.find('input.empty:hidden').length > 0 && @hasEmptySelectorAtStart()
        emptyRow.parent().replaceWith(row)
      else
        element.after(row)
        row.find('.js-attributeSelector select').trigger('change')

      @disableRemoveForOneAttribute(item)
      @rebuildAttributeSelectors(item, row, field, elements, {}, attribute)
      @toggleSubclauseDisableOnMaxLevels(item)
      @saveParams(item, params, attribute)

      if attribute.preview isnt false
        @preview(item)
    )

    # remove filter
    item.off('click.application_selector', '.js-remove').on('click.application_selector', '.js-remove', (e) =>
      return if $(e.currentTarget).hasClass('is-disabled')

      element = $(e.target).closest('.js-filterElement')

      # Remove all nested conditions first.
      if element.data('subclause') and element.data('level')
        level = element.data('level') + 1
        element.nextUntil(->
          $(@).data('level') < level
        , '.js-filterElement').remove()

      element.remove()

      @disableRemoveForOneAttribute(item)
      @updateAttributeSelectors(item)
      @saveParams(item, params, attribute)

      if attribute.preview isnt false
        @preview(item)
    )

    # add subclause
    item.off('click.application_selector', '.js-subclause').on('click.application_selector', '.js-subclause', (e) =>
      return if $(e.currentTarget).hasClass('is-disabled')

      element = $(e.target).closest('.js-filterElement')
      level = @getPreviousElementLevel(element)
      subclause = @subclauseContainer(level)

      emptyRow = item.find('div.horizontal-filter-body')
      if emptyRow.find('input.empty:hidden').length > 0 && @hasEmptySelectorAtStart()
        emptyRow.parent().replaceWith(subclause)
      else
        element.after(subclause)
        subclause.find('.js-subclauseSelector select').trigger('change')

      @disableRemoveForOneAttribute(item)
      @toggleSubclauseDisableOnMaxLevels(item)
      @saveParams(item, params, attribute)

      if attribute.preview isnt false
        @preview(item)
    )

    paramValue = @prepareParamValue(item, elements, attribute, params)

    # build initial params
    if !_.isEmpty(paramValue)
      @renderExpertConditions(item, attribute, params, paramValue)
    else
      if @hasEmptySelectorAtStart()
        row = @rowContainer(groups, elements, attribute)
        row.find('.horizontal-filter-body').html(@emptyBody(attribute))
        item.filter('.js-filter').append(row)
      else
        for groupAndAttribute in defaults

          # build and append
          if groupAndAttribute is 'subclause'
            subclause = @subclauseContainer()
            item.filter('.js-filter').append(subclause)
          else
            row = @rowContainer(groups, elements, attribute)
            @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, {}, attribute)
            item.filter('.js-filter').append(row)

    # change subclause selector
    item.off('change.application_selector', '.js-subclauseSelector select').on('change.application_selector', '.js-subclauseSelector select', =>
      @saveParams(item, params, attribute)
    )

    # change attribute selector
    item.off('change.application_selector', '.js-attributeSelector select').on('change.application_selector', '.js-attributeSelector select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @updateAttributeSelectors(item)
      @saveParams(item, params, attribute)
    )

    # change operator selector
    item.off('change.application_selector', '.js-operator select').on('change.application_selector', '.js-operator select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @buildOperator(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @saveParams(item, params, attribute)
    )

    # change pre-condition selector
    item.off('change.application_selector', '.js-preCondition select').on('change.application_selector', '.js-preCondition select', =>
      @saveParams(item, params, attribute)
    )

    # change attribute value
    item.off('change.application_selector keyup.application_selector', '.js-value .form-control').on('change.application_selector keyup.application_selector', '.js-value .form-control', =>
      @saveParams(item, params, attribute)
    )

    # bind for preview
    if attribute.preview isnt false
      search = =>
        @preview(item)

      triggerSearch = ->
        item.find('.js-previewCounterContainer').addClass('hide')
        item.find('.js-previewLoader').removeClass('hide')
        App.Delay.set(
          search,
          600,
          'preview',
        )

      item.off('change.application_selector', 'select').on('change.application_selector', 'select', (e) ->
        triggerSearch()
      )
      item.off('change.application_selector keyup.application_selector', 'input').on('change.application_selector keyup.application_selector', 'input', (e) ->
        triggerSearch()
      )

    @disableRemoveForOneAttribute(item)
    @toggleSubclauseDisableOnMaxLevels(item)
    @saveParams(item, params, attribute)

    @applySortable(item, attribute, params)

    if attribute.preview isnt false
      @preview(item)

    item

  @saveParams: (item, params, attribute) ->
    if !@hasExpertConditions() or !@isExpertMode
      return super

    @params = @buildExpertConditions(item, attribute)

  @applySortable: (elementFull, attribute, params) =>
    elementFull.filter('.js-filter').sortable({
      tolerance: 'pointer'
      handle:    '.draggable'
      items:     '> :not(.unsortable)'
      opacity:   0.75
      helper: (event, item) ->
        helper = $('<div></div>')
        helper.append(item.clone())

        # If the element is a subclause, clone its children and show them as part of the drag helper.
        if item.data('subclause')
          level = item.data('level') + 1
          children = item.nextUntil(->
            $(@).data('level') < level
          , '.js-filterElement').not('.ui-sortable-placeholder')
          helper.append(children.clone())

          # Hide the child elements temporarily.
          children.addClass('hidden')

        helper

      start: (event, ui) ->

        # If the element is a subclause, remember its children when the dragging starts.
        if ui.item.data('subclause')
          level = ui.item.data('level') + 1
          children = ui.item.nextUntil(->
            $(@).data('level') < level
          , '.js-filterElement').not('.ui-sortable-placeholder')
          ui.item.data('children', children)

      sort: (event, ui) =>

        # Get the level of the element right above the placeholder, but don't count the hidden elements,
        #   as the placeholder may appear right below the dragged item in certain cases.
        previousElement = ui.placeholder.prev('.js-filterElement:visible')

        # If the item hasn't been moved yet vertically, placeholder might not exist yet.
        #   In this case, consider the element right above the item for the target level.
        if !previousElement.length
          previousElement = ui.item.prev('.js-filterElement:visible')

        level = @getPreviousElementLevel(previousElement)

        cursorLevel = 1
        cursorPosition = ui.position?.left - 25 # NB: empirical offset due to styles

        # Invert the horizontal position, in case of the RTL language.
        if App.i18n.dir() is 'rtl'
          cursorPosition = -ui.position?.left + 90 # NB: empirical offset due to styles

        # Cursor level is the rounded quotient of the horizontal position in pixels and the level width constant (27px).
        if cursorPosition > 0
          cursorLevel = Math.ceil(cursorPosition/27)

        # Allow the cursor level to be considered only if it is lower than the current value.
        if level > cursorLevel
          level = cursorLevel

        # Set the level on the placeholder to give the user a suggestion what would happen if they drop the element.
        ui.placeholder.data('level', level).attr('data-level', level)

        # Remember the level to apply it later to the element.
        ui.item.data('new-level', level)

        return if ui.placeholder.data('height-set')

        # Set the placeholder height to the sum of all elements inside the helper container, sans the overhead.
        helperHeight = 0
        ui.helper.find('.js-filterElement').each(->
          helperHeight += $(@).outerHeight()
        )
        ui.placeholder.height(helperHeight - 16).data('height-set', true)

      stop: (event, ui) =>

        # Get the already calculated level, or calculate fresh one from the element just preceeding the dropped item.
        #   It might happen that the drag and drop operation was too fast for sorting to kick in.
        level = ui.item.data('new-level') || @getPreviousElementLevel(ui.item.prev('.js-filterElement:visible'))
        levelDiff = ui.item.data('level') - level

        # If the element is a subclause, move all of its previously identified children as well.
        #   We are not able to determine the children at this point on our own,
        #   since the element was already moved in the DOM.
        if ui.item.data('subclause') and ui.item.data('children')
          lastChild = ui.item
          children = ui.item.data('children')

          for child in children
            child = $(child)
            child.detach().insertAfter(lastChild)
            lastChild = child

            childLevel = child.data('level') - levelDiff
            child.data('level', childLevel).attr('data-level', childLevel)

          # Show all of the child elements again.
          children.removeClass('hidden')

          # Clean up the temporary data.
          ui.item.removeData('children')

        # Change the level both in jQuery object cache and DOM element.
        #   https://stackoverflow.com/a/9768213/17674471
        ui.item.data('level', level).attr('data-level', level)

        # Clean up the temporary data.
        ui.item.removeData('new-level')

        # Identify the items right below the dropped item which have a higher level.
        #   If the dropped item is not a subclause, the indentation is not allowed.
        #   Consequently, decrease their level by one and break the old subclause.
        if !ui.item.data('subclause')
          nextItems = ui.item.nextUntil(->
            $(@).data('level') <= level
          , '.js-filterElement')

          for nextItem in nextItems
            $(nextItem).data('level', level).attr('data-level', level)

        @disableRemoveForOneAttribute(elementFull)
        @toggleSubclauseDisableOnMaxLevels(elementFull)
        @saveParams(elementFull, params, attribute)

        if attribute.preview isnt false
          @preview(elementFull)
    })

  @getPreviousElementLevel: (element) ->
    level = 1

    # Get the initial level from the nearest subclause, increasing it by one.
    if element.data('subclause') and element.data('level')
      level = element.data('level') + 1

    # Otherwise, fallback on the level of a sibling element.
    else if element.data('level')
      level = element.data('level')

    level

  @renderExpertConditions: (item, attribute, params, rootSubclause) ->
    if !rootSubclause.conditions
      App.Log.error 'App.UiElement.ticket_selector', 'Unexpected root subclause format', rootSubclause

    @renderSubclause(item, attribute, params, rootSubclause)

  @renderSubclause: (item, attribute, params, condition, level = 0) ->
    subclause = @subclauseContainer(level, condition.operator)
    item.filter('.js-filter').append(subclause)

    for condition in condition.conditions
      if condition.conditions then @renderSubclause(item, attribute, params, condition, level + 1)
      else @renderCondition(item, attribute, params, condition, level + 1)

  @renderCondition: (item, attribute, params, condition, level) ->
    [defaults, groups, elements] = @defaults(attribute, params)

    row = @rowContainer(groups, elements, attribute, level)
    @rebuildAttributeSelectors(item, row, condition.name, elements, condition, attribute)
    item.filter('.js-filter').append(row)

  @disableRemoveForOneAttribute: (elementFull) ->
    if !@hasExpertConditions() or !@isExpertMode
      return super

    conditions = elementFull.find('.js-filterElement').not('[data-subclause]')

    if conditions.length > 1
      conditions.find('.js-remove').removeClass('is-disabled')
    else
      conditions.find('.js-remove').addClass('is-disabled')

    subclauses = elementFull.find('.js-filterElement[data-subclause][data-level]')

    for subclause in subclauses
      subclause = $(subclause)
      level = subclause.data('level') + 1
      nestedConditions = subclause.nextUntil(->
        $(@).data('level') < level
      , '.js-filterElement').not('[data-subclause]')

      if nestedConditions.length and conditions.length is nestedConditions.length
        subclause.find('.js-remove').addClass('is-disabled')
      else
        subclause.find('.js-remove').removeClass('is-disabled')

  @toggleSubclauseDisableOnMaxLevels: (elementFull) ->
    return if !@maxNestedLevels()

    elementFull.find('.js-subclause').each((index, subclauseButton) =>
      subclauseButton = $(subclauseButton)
      element = subclauseButton.closest('.js-filterElement')
      level = element.data('level') || 0
      isSubclause = element.data('subclause')
      if element.data('subclause') and level >= @maxNestedLevels() or level > @maxNestedLevels()
        subclauseButton.addClass('is-disabled')
      else
        subclauseButton.removeClass('is-disabled')
    )

  @buildSubclauseSelector: (operator) ->
    selection = $('<select class="form-control"></select>')
    selection.closest('select').append("<option value=\"AND\">#{App.i18n.translateInline('Match all (AND)')}</option>")
    selection.closest('select').append("<option value=\"OR\">#{App.i18n.translateInline('Match any (OR)')}</option>")
    selection.closest('select').append("<option value=\"NOT\">#{App.i18n.translateInline('Match none (NOT)')}</option>")
    selection.val(operator)
    selection

  @buildOperator: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    if !@hasExpertConditions() or !@isExpertMode
      return super

    currentOperator = elementRow.find('.js-operator option:selected').attr('value')

    if !meta.operator && currentOperator
      meta.operator = currentOperator

    selection = $('<select class="form-control"></select>')

    attributeConfig = elements[groupAndAttribute]
    if attributeConfig.operator

      # check if operator exists
      operatorExists = false
      for operator in attributeConfig.operator
        if meta.operator is operator
          operatorExists = true
          break

      if !operatorExists
        for operator in attributeConfig.operator
          meta.operator = operator
          break

      for operator in attributeConfig.operator
        operatorName = App.i18n.translateInline(@mapOperatorDisplayName(operator))
        selected = ''
        if !groupAndAttribute.match(/^ticket/) && operator is 'has changed'
          # do nothing, only show "has changed" in ticket attributes
        else
          if meta.operator is operator
            selected = 'selected="selected"'
          selection.append("<option value=\"#{operator}\" #{selected}>#{operatorName}</option>")
      selection

    elementRow.find('.js-operator select').replaceWith(selection)

    if @HasPreCondition()
      @buildPreCondition(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
    else
      @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @buildPreCondition: (elementFull, elementRow, groupAndAttribute, elements, meta, attributeConfig) ->
    if !@hasExpertConditions() or !@isExpertMode
      return super

    currentOperator = elementRow.find('.js-operator option:selected').attr('value')
    currentPreCondition = elementRow.find('.js-preCondition option:selected').attr('value')

    if !meta.pre_condition
      meta.pre_condition = currentPreCondition

    toggleValue = =>
      preCondition = elementRow.find('.js-preCondition option:selected').attr('value')
      if preCondition isnt 'specific'
        elementRow.find('.js-value select').html('')
        elementRow.find('.js-value').addClass('hide')
      else
        elementRow.find('.js-value').removeClass('hide')
        @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

    # force to use auto completion on user lookup
    attribute = _.clone(attributeConfig)

    attributeSelected = elements[groupAndAttribute]

    preCondition = false
    if attributeSelected.relation is 'User'
      preCondition = 'user'
      attribute.tag = 'user_autocompletion'
    if attributeSelected.relation is 'Organization'
      preCondition = 'org'
      attribute.tag = 'autocompletion_ajax'
    if !preCondition
      elementRow.find('.js-preCondition select').html('')
      elementRow.find('.js-preCondition').closest('.controls').addClass('hide')
      toggleValue()
      @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
      return

    elementRow.find('.js-preCondition').removeClass('hide')

    selection = $('<select class="form-control"></select>')
    options = {}
    if preCondition is 'user'
      if attributeConfig.noCurrentUser isnt true
        options['current_user.id'] = App.i18n.translateInline('current user')
      options['specific'] = App.i18n.translateInline('specific user')
      options['not_set'] = App.i18n.translateInline('not set (not defined)')
    else if preCondition is 'org'
      if attributeConfig.noCurrentUser isnt true
        options['current_user.organization_id'] = App.i18n.translateInline('current user organization')
      options['specific'] = App.i18n.translateInline('specific organization')
      options['not_set'] = App.i18n.translateInline('not set (not defined)')

    for key, value of options
      selected = ''
      if key is meta.pre_condition
        selected = 'selected="selected"'
      selection.append("<option value=\"#{key}\" #{selected}>#{App.i18n.translateInline(value)}</option>")
    elementRow.find('.js-preCondition').closest('.controls').removeClass('hide')
    elementRow.find('.js-preCondition select').replaceWith(selection)

    elementRow.find('.js-preCondition select').off('change.application_selector').on('change.application_selector', (e) ->
      toggleValue()
    )

    @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
    toggleValue()

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    if !@hasExpertConditions() or !@isExpertMode
      return super

    # build new item
    attributeConfig = elements[groupAndAttribute]
    config = _.clone(attributeConfig)

    if config.relation is 'User'
      config.tag = 'user_autocompletion'
    if config.relation is 'Organization'
      config.tag = 'autocompletion_ajax'

    # render ui element
    item = ''
    if config && App.UiElement[config.tag] && meta.operator isnt 'today'

      # Allow for multiple elements of the same type.
      delete config['name']
      delete config['id']

      if typeof meta.value isnt 'undefined'
        config['value'] = meta.value
      if 'multiple' of config
        config = @buildValueConfigMultiple(config, meta)
      if config.relation is 'User'
        config.multiple = false
        config.nulloption = false
        config.guess = false
        config.disableCreateObject = true
      if config.relation is 'Organization'
        config.multiple = false
        config.nulloption = false
        config.guess = false
      if config.tag is 'checkbox'
        config.tag = 'select'
      item = @renderConfig(config, meta)
    if meta.operator is 'before (relative)' || meta.operator is 'within next (relative)' || meta.operator is 'within last (relative)' || meta.operator is 'after (relative)' || meta.operator is 'from (relative)' || meta.operator is 'till (relative)'
      config['value'] = meta
      item = App.UiElement['time_range'].render(config, {})

    elementRow.find('.js-value').removeClass('hide').html(item)
    if meta.operator is 'has changed'
      elementRow.find('.js-value').addClass('hide')
      elementRow.find('.js-preCondition').closest('.controls').addClass('hide')
    else
      elementRow.find('.js-value').removeClass('hide')

  @buildExpertConditions: (item, attribute) ->
    expertConditions = item.find('.js-expertConditions input:hidden')

    if !expertConditions.length
      expertConditions = $("<input type=\"hidden\" name=\"{json}#{attribute.name}\">")
      item.find('.js-expertConditions').append(expertConditions)

    # Get root subclause conditions.
    element = item.find('.js-filterElement[data-subclause]').not('[data-level]')
    if element.length isnt 1
      App.Log.error 'App.UiElement.ticket_selector', 'Unexpected root subclause', element
      return

    value = @prepareSubclauseConditions(element.nextAll(), element)
    json = JSON.stringify(value)
    expertConditions.val(json)

    {
      "#{attribute.name}": value,
    }

  @prepareSubclauseConditions: (elements, element) ->
    value = {}

    value.operator = element.find('.js-subclauseSelector select').val()

    level = if element.data('level') then element.data('level') + 1 else 1
    conditions = elements.filter(".js-filterElement[data-level=\"#{level}\"]")

    value.conditions = []

    if !conditions.length
      App.Log.debug 'App.UiElement.ticket_selector', 'Missing subclause conditions', element
      return value

    conditions.each((index, condition) =>
      condition = $(condition)
      if condition.data('subclause')
        level = condition.data('level') + 1
        subclauseElements = condition.nextUntil(->
          $(@).data('level') < level
        , '.js-filterElement')
        value.conditions.push(@prepareSubclauseConditions(subclauseElements, condition))
      else
        value.conditions.push(@prepareCondition(condition))
    )

    value

  @prepareCondition: (element) ->
    value = {}

    attributeSelector = element.find('.js-attributeSelector select')

    if !attributeSelector.length
      App.Log.error 'App.UiElement.ticket_selector', 'Missing condition attribute selector', element
      return value

    value.name = attributeSelector.val()

    if element.find('.js-operator select')?.val()
      value.operator = element.find('.js-operator select').val()

    if element.find('.js-preCondition select')?.val()
      value.pre_condition = element.find('.js-preCondition select').val()

    if element.find('select.js-range')?.val()
      value.range = element.find('select.js-range').val()

    if element.find('input[type="hidden"]')?.val()
      value.value = element.find('input[type="hidden"]').val()
    else if element.find('select.js-value')?.val()
      value.value = element.find('select.js-value').val()
    else if element.find('.js-value .js-objectId')?.val()
      value.value = element.find('.js-value .js-objectId').val()
    else if element.find('.js-value .js-shadow')?.val()
      value.value = element.find('.js-value .js-shadow').val()
    else if element.find('.js-value input.form-control')?.val()
      value.value = element.find('.js-value input.form-control').val()
    else if element.find('.js-value .form-control')?.val()
      value.value = element.find('.js-value .form-control').val()

    value

  @maxNestedLevels: ->
    return 2

  @hasExpertConditions: ->
    return App.Config.get('ticket_allow_expert_conditions')

  @hasDuplicateSelector: ->
    return @hasExpertConditions() && @isExpertMode
