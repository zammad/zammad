# coffeelint: disable=camel_case_classes
class App.UiElement.object_attribute_options_context extends Spine.Module
  @render: (attribute, params = {}) ->
    related_object_attribute = @fetchObjectManagerAttribute(attribute, params)

    if not related_object_attribute
      return console.error('Related object attribute not found', attribute.object_attribute_object, attribute.object_attribute_name or attribute.related_object_attribute_selection_name)

    allFlatOptions = @buildOptions(related_object_attribute)

    optionsSelected = []

    if attribute.value
      optionsSelected = @buildOptionsSelected(attribute, related_object_attribute, allFlatOptions)

    item = $(App.view('generic/object_attribute_options_context')(
      attribute:              attribute,
      valueRaw:               JSON.stringify(attribute.value or {}),
      optionsSelected:        optionsSelected,
      limitActive:            optionsSelected.length > 0 or not _.isObject(attribute.value),
      objectAttributeDisplay: related_object_attribute.display or __('Name')
      required:               not attribute.null
      showDescription:        attribute.show_description or false
      hideAddAll:             optionsSelected.length >= allFlatOptions.length
    ))

    item.find('input[type="checkbox"]').off('click.limit_toggle').on('click.limit_toggle', (e) =>
      item.find('.js-objectAttributeOptionsContextListContainer, .js-objectAttributeOptionsContextLimitDescription').toggleClass('hide')
      item.find('.js-objectAttributeOptionsContext').val(JSON.stringify({}))
      item.find('tr[data-id]').remove()

      @updateRequiredValidator(item, e.target.checked)
    )

    item.off('click', '.js-add'         ).on('click',  '.js-add',         (e) => @onAdd(e, item, attribute.name, related_object_attribute, allFlatOptions))
    item.off('click', '.js-add-all'     ).on('click',  '.js-add-all',     (e) => @onAddAll(e, item, attribute.name, related_object_attribute, allFlatOptions))
    item.off('click', '.js-remove'      ).on('click',  '.js-remove',      (e) => @onRemove(e, item, attribute.name, related_object_attribute, allFlatOptions))
    item.off('change', '.js-description').on('change', '.js-description', (e) => @onDescriptionChange(e, item))

    @renderOptionDropdownNew(item, attribute.name, related_object_attribute, allFlatOptions)

    item

  @renderOptionDropdownNew: (item, name, related_object_attribute, allFlatOptions) ->
    filteredOptionValues = @getFilteredOptionValues(item, allFlatOptions)

    # Show/hide "Add All" button based on available options
    addAllButton = item.find('.js-add-all')
    addAllButton.toggleClass('hide', not filteredOptionValues?.length)

    attribute = {
      tag:        'tree_select',
      nulloption: true,
      null:       true,
      id:         'attribute-' + name + '-search',
      filter:     filteredOptionValues,
      translate:  related_object_attribute.translate
    }

    if related_object_attribute.relation
      attribute.relation = related_object_attribute.relation
    else
      attribute.options = related_object_attribute.options

    element = App.UiElement.ApplicationTreeSelect.render(attribute)

    item.find('.js-objectAttributeOptionsContextItemAddNew').html(element)
    item.find('.js-descriptionNew').val('')
    element.find('.js-shadow').trigger('change')

  @getFilteredOptionValues: (item, allOptions) ->
    return if not allOptions?.length

    currentValue = @getCurrentValue(item)
    selectedValues = Object.keys(currentValue)

    _.map(
      _.filter(allOptions, (option) -> not _.include(selectedValues, option.value)),
      (option) -> option.value
    )

  @onAdd: (e, item, name, related_object_attribute, allFlatOptions) ->
    e.stopPropagation()
    e.preventDefault()

    newOptionValue       = item.find('.js-shadow').val()
    newOptionDescription = item.find('.js-descriptionNew').val() or ''

    $(e.target.closest('tr')).find('.js-input').toggleClass('has-error', not newOptionValue)
    return if not newOptionValue

    displayValue = _.find(allFlatOptions, (option) -> option.value is newOptionValue)?.label
    return if not displayValue

    shadowRow = item.find('.js-objectAttributeOptionsContextShadowItemRow')

    newRow = shadowRow
      .clone()
      .removeClass('hide js-objectAttributeOptionsContextShadowItemRow')
      .attr('data-id', newOptionValue)

    newRow.find('td:first-child').text(displayValue)
    newRow.find('textarea').val(newOptionDescription)

    newRow.insertBefore(shadowRow)

    @addValue(item, newOptionValue, newOptionDescription)

    @renderOptionDropdownNew(item, name, related_object_attribute, allFlatOptions)

  @addRow: (item, optionValue, description, allFlatOptions) ->
    displayValue = _.find(allFlatOptions, (option) -> option.value is optionValue)?.label
    return if not displayValue

    shadowRow = item.find('.js-objectAttributeOptionsContextShadowItemRow')

    newRow = shadowRow
      .clone()
      .removeClass('hide js-objectAttributeOptionsContextShadowItemRow')
      .attr('data-id', optionValue)

    newRow.find('td:first-child').text(displayValue)
    newRow.find('textarea').val(description or '')

    newRow.insertBefore(shadowRow)

    @addValue(item, optionValue, description or '')

  @onAddAll: (e, item, name, related_object_attribute, allFlatOptions) ->
    e.stopPropagation()
    e.preventDefault()

    filteredOptionValues = @getFilteredOptionValues(item, allFlatOptions)
    return if not filteredOptionValues?.length

    for optionValue in filteredOptionValues
      item.find('.js-shadow').val(optionValue)
      item.find('.js-descriptionNew').val('')
      @onAdd(e, item, name, related_object_attribute, allFlatOptions)

    item.find('.js-shadow').val('')
    item.find('.js-descriptionNew').val('')

  @onRemove: (e, item, name, related_object_attribute, allFlatOptions) ->
    e.stopPropagation()
    e.preventDefault()

    # Get the row ID before removing the row
    rowId = $(e.target).closest('tr').attr('data-id')

    e.target
      .closest('tr')
      .remove()

    @removeValue(item, rowId)

    @renderOptionDropdownNew(item, name, related_object_attribute, allFlatOptions)

  @onDescriptionChange: (e, item) ->
    e.stopPropagation()
    e.preventDefault()

    # Get the associated row ID.
    rowId = $(e.target).closest('tr').attr('data-id')

    currentValue = @getCurrentValue(item)

    currentValue[rowId] = $(e.target).val()

    item.find('.js-objectAttributeOptionsContext').val(JSON.stringify(currentValue))

  @getCurrentValue: (item) ->
    currentValue = {}

    try
      currentValue = JSON.parse(item.find('.js-objectAttributeOptionsContext').val()) or {}
    catch e
      currentValue = {}

    @updateRequiredValidator(item, item.find('input[type="checkbox"]').get(0).checked and _.isEmpty(currentValue))

    currentValue

  @updateRequiredValidator: (item, validate) ->
    if validate
      item.find('.js-objectAttributeOptionsContextRequiredValidator').removeAttr('disabled')
    else
      item.find('.js-objectAttributeOptionsContextRequiredValidator').attr('disabled', true)

  @addValue: (item, value, description) ->
    currentValue = @getCurrentValue(item)

    # Add the value to the current value with the description (if any)
    currentValue[value] = description

    item.find('.js-objectAttributeOptionsContext').val(JSON.stringify(currentValue))

  @removeValue: (item, value) ->
    currentValue = @getCurrentValue(item)

    delete currentValue[value.toString()]

    item.find('.js-objectAttributeOptionsContext').val(JSON.stringify(currentValue))

  @fetchObjectManagerAttribute: (attribute, params) ->
    name = if attribute.related_object_attribute_selection_name
      [first, second] = attribute.related_object_attribute_selection_name.split('::')
      params?[first]?[second]
    else
      attribute.object_attribute_name

    App[attribute.object_attribute_object].configure_attributes.find((elem) -> elem.name == name)

  @buildOptions: (related_object_attribute) ->
    if related_object_attribute.relation
      itemsRaw = App[related_object_attribute.relation].search(sortBy: 'name')
      activeItems = itemsRaw.filter (elem) -> elem.active
      optionsArray = []
      _.map(activeItems, (item) ->
        {
          value: item.id.toString()
          label: item.displayName()
        }
      )
    else
      if _.isArray(related_object_attribute.options)
        @buildFlatOptions(
          related_object_attribute.options,
          _.some(
            related_object_attribute.options,
            (option) -> option.children # tree structures have children
          ),
          related_object_attribute.translate
        )
      else
        _.map(related_object_attribute.options, (label, value) ->
          {
            value: value
            label: if related_object_attribute.translate then App.i18n.translateInline(label) else label
          }
        )

  @buildOptionsSelected: (attribute, related_object_attribute, allFlatOptions) ->
    optionsSelected = []

    _.keys(attribute.value).forEach (value) ->
      if option = _.find(allFlatOptions, (option) -> option.value is value)
        optionsSelected.push(
          {
            value: value,
            label: option.label
            description: attribute.value[value] or ''
          }
        )

    # If custom sort is enabled, sort according to the configured order.
    #   Do this also if the options are an array (to respect the defined order).
    if related_object_attribute.customsort is 'on' or _.isArray(related_object_attribute.options)
      return _.sortBy(optionsSelected, (selectedOption) ->
        _.findIndex(allFlatOptions, (option) ->
          option.value is selectedOption.value
        )
      )

    # Otherwise, return sorted alphabetically.
    optionsSelected.sort (a, b) -> a.label.localeCompare(b.label)

  @buildFlatOptions: (options, isTree = false, isTranslated = false) ->
    flatOptions = []

    options.forEach (option) ->
      if !option.disabled
        label = if isTree
          App.TokenHelper.computeNameValue(option.value, isTranslated)
        else if isTranslated
          App.i18n.translateInline(option.name or option.value)
        else
          option.name or option.value

        flatOptions.push(
          value: option.value
          label: label
        )

      if option.children
        flatOptions.push App.UiElement.object_attribute_options_context.buildFlatOptions(
          option.children,
          true,
          isTranslated
        )...

    flatOptions
