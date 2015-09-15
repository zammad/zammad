class App.UiElement.ticket_selector extends App.UiElement.ApplicationUiElement
  @render: (attribute, params = {}) ->

    # list of attributes
    groups =
      tickets:
        name: 'Ticket'
        model: 'Ticket'
      users:
        name: 'Customer'
        model: 'User'
      organizations:
        name: 'Organization'
        model: 'Organization'

    elements =
      tickets:
        title:
          tag: 'input'
          operator: ['contains', 'contains not']
        number:
          tag: 'input'
          operator: ['contains', 'contains not']
        group_id:
          relation: 'Group'
          tag: 'select'
          multible: true
          operator: ['is', 'is not']
        priority_id:
          relation: 'Priority'
          tag: 'select'
          multible: true
          operator: ['is', 'is not']
        state_id:
          relation: 'State'
          tag: 'select'
          multible: true
          operator: ['is', 'is not']
        owner_id:
          tag: 'user_selection'
          relation: 'User'
          operator: ['is', 'is not']
        customer_id:
          tag: 'user_selection'
          relation: 'User'
          operator: ['is', 'is not']
        organization_id:
          tag: ''
          relation: 'Organization'
          operator: ['is', 'is not']
        tag:
          tag: 'tag'
          multible: true
          operator: ['is', 'is not']
        created_at:
          tag: 'timestamp'
          operator: ['before', 'after']
        updated_at:
          tag: 'timestamp'
          operator: ['before', 'after']
        escalation_time:
          tag: 'timestamp'
          operator: ['before', 'after']
      users:
        firstname:
          tag: 'input'
          operator: ['contains', 'contains not']
        lastname:
          tag: 'input'
          operator: ['contains', 'contains not']
        email:
          tag: 'input'
          operator: ['contains', 'contains not']
        login:
          tag: 'input'
          operator: ['contains', 'contains not']
        created_at:
          tag: 'time_selector_enhanced'
          operator: ['before', 'after']
        updated_at:
          tag: 'time_selector_enhanced'
          operator: ['before', 'after']
      organizations:
        name:
          tag: 'input'
          operator: ['contains', 'contains not']
        shared:
          tag: 'boolean'
          operator: ['is', 'is not']
        created_at:
          tag: 'time_selector_enhanced'
          operator: ['before', 'after']
        updated_at:
          tag: 'time_selector_enhanced'
          operator: ['before', 'after']

    # megre config
    for groupKey, groupMeta of groups
      for elementKey, elementGroup of elements
        if elementKey is groupKey
          configure_attributes = App[groupMeta.model].configure_attributes
          for attributeName, attributeConfig of elementGroup
            for attribute in configure_attributes
              if attribute.name is attributeName
                attributeConfig.config = attribute

    selector = @buildAttributeSelector(groups, elements)

    # return item
    item = $( App.view('generic/ticket_selector')( attribute: attribute ) )
    item.find('.js-attributeSelector').prepend(selector)

    # add filter
    item.find('.js-add').bind('click', (e) =>
      element = $(e.target).closest('.js-filterElement')
      elementClone = element.clone(true)
      element.after(elementClone)
      elementClone.find('.js-attributeSelector select').trigger('change')
    )

    # remove filter
    item.find('.js-remove').bind('click', (e) =>
      $(e.target).closest('.js-filterElement').remove()
      @rebuildAttributeSelectors(item)
    )

    # change filter
    item.find('.js-attributeSelector select').bind('change', (e) =>
      groupAndAttribute = $(e.target).find('option:selected').attr('value')
      elementRow = $(e.target).closest('.js-filterElement')

      console.log('CHANGE', groupAndAttribute, $(e.target))

      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute)
      @rebuildOperater(item, elementRow, groupAndAttribute, elements)
      @buildValue(item, elementRow, groupAndAttribute, elements)
    )

    # build inital params
    console.log('P', params)
    if !_.isEmpty(params.condition)
      selectorExists = false
      for position of params.condition.attribute

        # get stored params
        groupAndAttribute = params.condition.attribute[position]
        if params.condition[groupAndAttribute]
          selectorExists = true
          operator = params.condition[groupAndAttribute].operator
          value = params.condition[groupAndAttribute].value

          # get selector rows
          elementFirst = item.find('.js-filterElement').first()
          elementLast = item.find('.js-filterElement').last()

          # clone, rebuild and append
          elementClone = elementFirst.clone(true)
          @rebuildAttributeSelectors(item, elementClone, groupAndAttribute)
          @rebuildOperater(item, elementClone, groupAndAttribute, elements, operator)
          @buildValue(item, elementClone, groupAndAttribute, elements, value)
          elementLast.after(elementClone)

      # remove first dummy row
      if selectorExists
        item.find('.js-filterElement').first().remove()
    item

  @getElementConfig: (groupAndAttribute, elements) ->
    for elementGroup, elementConfig of elements
      for elementKey, elementItem of elementConfig
        if "#{elementGroup}.#{elementKey}" is groupAndAttribute
          return elementItem
    false

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, value) ->

    # do nothing if item already exists
    name = "condition::#{groupAndAttribute}::value"
    return if elementRow.find("[name=\"#{name}\"]").get(0)

    # build new item
    attributeConfig = @getElementConfig(groupAndAttribute, elements)
    item = ''
    if attributeConfig && attributeConfig.config && App.UiElement[attributeConfig.config.tag]
      config = _.clone(attributeConfig.config)
      config['name'] = name
      config['value'] = value
      if 'multiple' of config
        config.multiple = true
        config.nulloption = false
      item = App.UiElement[attributeConfig.config.tag].render(config, {})
    elementRow.find('.js-value').html(item)

  @buildAttributeSelector: (groups, elements) ->
    selection = $('<input type="hidden" name="condition::attribute"><select class="form-control"></select>')
    for groupKey, groupMeta of groups
      displayName = App.i18n.translateInline(groupMeta.name)
      selection.closest('select').append("<optgroup label=\"#{displayName}\" class=\"js-#{groupKey}\"></optgroup>")
      optgroup = selection.find("optgroup.js-#{groupKey}")
      for elementKey, elementGroup of elements
        if elementKey is groupKey
          for attributeName, attributeConfig of elementGroup
            if attributeConfig.config && attributeConfig.config.display
              displayName = App.i18n.translateInline(attributeConfig.config.display)
            else
              displayName = App.i18n.translateInline(attributeName)
            optgroup.append("<option value=\"#{groupKey}.#{attributeName}\">#{displayName}</option>")
    selection

  @rebuildAttributeSelectors: (elementFull, elementRow, groupAndAttribute) ->

    # enable all
    elementFull.find('.js-attributeSelector select option').removeAttr('disabled')

    # disable all used attributes
    elementFull.find('.js-attributeSelector select').each(->
      keyLocal = $(@).val()
      elementFull.find('.js-attributeSelector select option[value="' + keyLocal + '"]').attr('disabled', true)
      elementFull.find('.js-hiddenAttribute').val(keyLocal)
    )

    # disable - if we only have one attribute
    if elementFull.find('.js-attributeSelector select').length > 1
      elementFull.find('.js-remove').removeClass('is-disabled')
    else
      elementFull.find('.js-remove').addClass('is-disabled')

    # set attribute
    if groupAndAttribute
      elementRow.find('.js-attributeSelector select').val(groupAndAttribute)
      elementRow.find('[name="condition::attribute"]').val("#{groupAndAttribute}")

  @buildOperator: (elementFull, elementRow, groupAndAttribute, elements, current_operator) ->
    selection = $("<select class=\"form-control\" name=\"condition::#{groupAndAttribute}::operator\"></select>")
    attributeConfig = @getElementConfig(groupAndAttribute, elements)
    for operator in attributeConfig.operator
      operatorName = App.i18n.translateInline(operator)
      selected = ''
      if current_operator is operator
        selected = 'selected="selected"'
      selection.append("<option value=\"#{operator}\" #{selected}>#{operatorName}</option>")
    selection

  @rebuildOperater: (elementFull, elementRow, groupAndAttribute, elements, current_operator) ->
    return if !groupAndAttribute

    # do nothing if item already exists
    name = "condition::#{groupAndAttribute}::operator"
    return if elementRow.find("[name=\"#{name}\"]").get(0)

    # render new operator
    operator = @buildOperator(elementFull, elementRow, groupAndAttribute, elements, current_operator)
    elementRow.find('.js-operator select').replaceWith(operator)

  @humanText: (condition) ->
    return [] if _.isEmpty(condition)
    rules = []
    for position of condition.attribute

      # get stored params
      groupAndAttribute = condition.attribute[position]
      if condition[groupAndAttribute]
        selectorExists = true
        operator = condition[groupAndAttribute].operator
        value = condition[groupAndAttribute].value
        rules.push "Where <b>#{groupAndAttribute}</b> #{operator} <b>#{value}</b>."
    rules