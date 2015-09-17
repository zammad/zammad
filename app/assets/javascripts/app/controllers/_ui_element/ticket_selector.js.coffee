class App.UiElement.ticket_selector
  @defaults: ->
    defaults = ['ticket.state_id']

    groups =
      ticket:
        name: 'Ticket'
        model: 'Ticket'
      customer:
        name: 'Customer'
        model: 'User'
      organization:
        name: 'Organization'
        model: 'Organization'

    operators_type =
      '^datetime$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)']
      '^timestamp$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)']
      'boolean$': ['is', 'is not']
      '^input$': ['contains', 'contains not']
      '^textarea$': ['contains', 'contains not']

    operators_name =
      '_id$': ['is', 'is not']
      '_ids$': ['is', 'is not']

    # megre config
    elements = {}
    for groupKey, groupMeta of groups
      for row in App[groupMeta.model].configure_attributes

        # ignore passwords and relations
        if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids'
          config = _.clone(row)
          for operatorRegEx, operator of operators_type
            myRegExp = new RegExp(operatorRegEx, 'i')
            if config.tag && config.tag.match(myRegExp)
              config.operator = operator
            elements["#{groupKey}.#{config.name}"] = config
          for operatorRegEx, operator of operators_name
            myRegExp = new RegExp(operatorRegEx, 'i')
            if config.name && config.name.match(myRegExp)
              config.operator = operator
            elements["#{groupKey}.#{config.name}"] = config
    [defaults, groups, elements]

  @render: (attribute, params = {}) ->

    [defaults, groups, elements] = @defaults()

    selector = @buildAttributeSelector(groups, elements)

    search = =>
      @preview(item)

    # return item
    item = $( App.view('generic/ticket_selector')( attribute: attribute ) )
    item.find('.js-attributeSelector').prepend(selector)

    # add filter
    item.find('.js-add').bind('click', (e) =>
      element = $(e.target).closest('.js-filterElement')
      elementClone = element.clone(true)
      element.after(elementClone)
      elementClone.find('.js-attributeSelector select').trigger('change')
      @preview(item)
    )

    # remove filter
    item.find('.js-remove').bind('click', (e) =>
      $(e.target).closest('.js-filterElement').remove()
      @rebuildAttributeSelectors(item)
      @preview(item)
    )

    # change filter
    item.find('.js-attributeSelector select').bind('change', (e) =>
      groupAndAttribute = $(e.target).find('option:selected').attr('value')
      elementRow = $(e.target).closest('.js-filterElement')

      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute)
      @rebuildOperater(item, elementRow, groupAndAttribute, elements)
      @buildValue(item, elementRow, groupAndAttribute, elements)
    )

    # build inital params
    if !_.isEmpty(params.condition)
      selectorExists = false
      for groupAndAttribute, meta of params.condition
        if groupAndAttribute isnt 'attribute'
          selectorExists = true
          operator = meta.operator
          value = meta.value

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

    else
      for default_row in defaults

        # get selector rows
        elementFirst = item.find('.js-filterElement').first()
        elementLast = item.find('.js-filterElement').last()

        # clone, rebuild and append
        elementClone = elementFirst.clone(true)
        @rebuildAttributeSelectors(item, elementClone, default_row)
        elementLast.after(elementClone)
      item.find('.js-filterElement').first().remove()

    # bind for preview
    item.on('change', 'select.form-control', (e) =>
      App.Delay.set(
        search,
        600,
        'preview',
      )
    )
    item.on('change keyup', 'input.form-control', (e) =>
      App.Delay.set(
        search,
        600,
        'preview',
      )
    )

    item

  @preview: (item) ->
    params = App.ControllerForm.params(item)

    # ajax call
    App.Ajax.request(
      id:    'ticket_selector'
      type:  'POST'
      url:   "#{App.Config.get('api_path')}/tickets/selector"
      data:        JSON.stringify(params)
      processData: true,
      success: (data, status, xhr) =>
        App.Collection.loadAssets( data.assets )
        @ticketTable(data.ticket_ids, data.ticket_count, item)
    )

  @ticketTable: (ticket_ids, ticket_count, item) =>
    item.find('.js-previewCounter').html(ticket_count)
    new App.TicketList(
      el:         item.find('.js-previewTable')
      ticket_ids: ticket_ids
    )

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, value) ->

    # do nothing if item already exists
    name = "condition::#{groupAndAttribute}::value"
    return if elementRow.find("[name=\"#{name}\"]").get(0)

    # build new item
    attributeConfig = elements[groupAndAttribute]
    config = _.clone(attributeConfig)

    # force to use auto compition on user lookup
    if config.relation is 'User'
      config.tag = 'user_autocompletion'

    # render ui element
    item = ''
    if config && App.UiElement[config.tag]
      config['name'] = name
      config['value'] = value
      if 'multiple' of config
        config.multiple = true
        config.nulloption = false
      if config.tag is 'checkbox'
        config.tag = 'select'
        #config.type = 'datetime-local'
      #if config.tag is 'datetime'
      #  config.tag = 'input'
      #  config.type = 'datetime-local'
      tagSearch = "#{config.tag}_search"
      if App.UiElement[tagSearch]
        item = App.UiElement[tagSearch].render(config, {})
      else
        item = App.UiElement[config.tag].render(config, {})
    elementRow.find('.js-value').html(item)

  @buildAttributeSelector: (groups, elements) ->
    selection = $('<input type="hidden" name="condition::attribute"><select class="form-control"></select>')
    for groupKey, groupMeta of groups
      displayName = App.i18n.translateInline(groupMeta.name)
      selection.closest('select').append("<optgroup label=\"#{displayName}\" class=\"js-#{groupKey}\"></optgroup>")
      optgroup = selection.find("optgroup.js-#{groupKey}")
      for elementKey, elementGroup of elements
        spacer = elementKey.split(/\./)
        if spacer[0] is groupKey
          attributeConfig = elements[elementKey]
          if attributeConfig.operator
            displayName = App.i18n.translateInline(attributeConfig.display)
            optgroup.append("<option value=\"#{elementKey}\">#{displayName}</option>")
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

    attributeConfig = elements[groupAndAttribute]
    if attributeConfig.operator
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
    none = App.i18n.translateContent('No filter.')
    return [none] if _.isEmpty(condition)
    [defaults, groups, elements] = @defaults()
    rules = []
    for attribute, meta of condition

      objectAttribute = attribute.split(/\./)

      # get stored params
      if meta && objectAttribute[1]
        selectorExists = true
        operator = meta.operator
        value = meta.value
        model = toCamelCase(objectAttribute[0])
        modelAttribute = objectAttribute[1]

        config = elements[attribute]

        if modelAttribute.substr(modelAttribute.length-4,4) is '_ids'
          modelAttribute = modelAttribute.substr(0, modelAttribute.length-4)
        if modelAttribute.substr(modelAttribute.length-3,3) is '_id'
          modelAttribute = modelAttribute.substr(0, modelAttribute.length-3)
        valueHuman = []
        if _.isArray(value)
          for data in value
            r = @humanTextLookup(config, data)
            valueHuman.push r
        else
          valueHuman.push @humanTextLookup(config, value)
        rules.push "#{App.i18n.translateContent('Where')} <b>#{App.i18n.translateContent(model)} -> #{App.i18n.translateContent(toCamelCase(modelAttribute))}</b> #{App.i18n.translateContent(operator)} <b>#{valueHuman}</b>."

    return [none] if _.isEmpty(rules)
    rules

  @humanTextLookup: (config, value) ->
    return value if !App[config.relation]
    return value if !App[config.relation].exists(value)
    data = App[config.relation].fullLocal(value)
    return value if !data
    if data.displayName
      return App.i18n.translateContent( data.displayName() )
    valueHuman.push App.i18n.translateContent( data.name )
