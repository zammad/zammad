# coffeelint: disable=camel_case_classes
class App.UiElement.ticket_selector
  @defaults: (attribute = {}) ->
    defaults = ['ticket.state_id']

    groups =
      ticket:
        name: 'Ticket'
        model: 'Ticket'
      article:
        name: 'Article'
        model: 'TicketArticle'
      customer:
        name: 'Customer'
        model: 'User'
      organization:
        name: 'Organization'
        model: 'Organization'

    if attribute.executionTime
      groups.execution_time =
        name: 'Execution Time'

    operators_type =
      '^datetime$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)', 'till (relative)', 'from (relative)']
      '^timestamp$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)', 'till (relative)', 'from (relative)']
      '^date$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)']
      'boolean$': ['is', 'is not']
      'integer$': ['is', 'is not']
      '^radio$': ['is', 'is not']
      '^select$': ['is', 'is not']
      '^tree_select$': ['is', 'is not']
      '^input$': ['contains', 'contains not']
      '^richtext$': ['contains', 'contains not']
      '^textarea$': ['contains', 'contains not']
      '^tag$': ['contains all', 'contains one', 'contains all not', 'contains one not']

    if attribute.hasChanged
      operators_type =
        '^datetime$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)', 'till (relative)', 'from (relative)', 'has changed']
        '^timestamp$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)', 'till (relative)', 'from (relative)', 'has changed']
        '^date$': ['before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)', 'till (relative)', 'from (relative)', 'has changed']
        'boolean$': ['is', 'is not', 'has changed']
        'integer$': ['is', 'is not', 'has changed']
        '^radio$': ['is', 'is not', 'has changed']
        '^select$': ['is', 'is not', 'has changed']
        '^tree_select$': ['is', 'is not', 'has changed']
        '^input$': ['contains', 'contains not', 'has changed']
        '^richtext$': ['contains', 'contains not', 'has changed']
        '^textarea$': ['contains', 'contains not', 'has changed']
        '^tag$': ['contains all', 'contains one', 'contains all not', 'contains one not']

    operators_name =
      '_id$': ['is', 'is not']
      '_ids$': ['is', 'is not']

    if attribute.hasChanged
      operators_name =
        '_id$': ['is', 'is not', 'has changed']
        '_ids$': ['is', 'is not', 'has changed']

    # merge config
    elements = {}

    if attribute.article is false
      delete groups.article

    if attribute.action
      elements['ticket.action'] =
        name: 'action'
        display: 'Action'
        tag: 'select'
        null: false
        translate: true
        options:
          create: 'created'
          update: 'updated'
        operator: ['is', 'is not']

    for groupKey, groupMeta of groups
      if groupKey is 'execution_time'
        if attribute.executionTime
          elements['execution_time.calendar_id'] =
            name: 'calendar_id'
            display: 'Calendar'
            tag: 'select'
            relation: 'Calendar'
            null: false
            translate: false
            operator: ['is in working time', 'is not in working time']

      else
        for row in App[groupMeta.model].configure_attributes

          # ignore passwords and relations
          if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids' && row.searchable isnt false
            config = _.clone(row)
            if config.type is 'email' || config.type is 'tel'
              config.type = 'text'
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

            if config.tag == 'select'
              config.multiple = true

    if attribute.out_of_office
      elements['ticket.out_of_office_replacement_id'] =
        name: 'out_of_office_replacement_id'
        display: 'Out of office replacement'
        tag: 'autocompletion_ajax'
        relation: 'User'
        null: false
        translate: true
        operator: ['is', 'is not']

    elements['ticket.mention_user_ids'] =
      name: 'mention_user_ids'
      display: 'Subscribe'
      tag: 'autocompletion_ajax'
      relation: 'User'
      null: false
      translate: true
      operator: ['is', 'is not']

    [defaults, groups, elements]

  @rowContainer: (groups, elements, attribute) ->
    row = $( App.view('generic/ticket_selector_row')(attribute: attribute) )
    selector = @buildAttributeSelector(groups, elements)
    row.find('.js-attributeSelector').prepend(selector)
    row

  @render: (attribute, params = {}) ->

    [defaults, groups, elements] = @defaults(attribute)

    item = $( App.view('generic/ticket_selector')(attribute: attribute) )

    # add filter
    item.delegate('.js-add', 'click', (e) =>
      element = $(e.target).closest('.js-filterElement')

      # add first available attribute
      field = undefined
      for groupAndAttribute, _config of elements
        if !item.find(".js-attributeSelector [value=\"#{groupAndAttribute}\"]:selected").get(0)
          field = groupAndAttribute
          break
      return if !field
      row = @rowContainer(groups, elements, attribute)
      element.after(row)
      row.find('.js-attributeSelector select').trigger('change')
      @rebuildAttributeSelectors(item, row, field, elements, {}, attribute)

      if attribute.preview isnt false
        @preview(item)
    )

    # remove filter
    item.delegate('.js-remove', 'click', (e) =>
      return if $(e.currentTarget).hasClass('is-disabled')
      $(e.target).closest('.js-filterElement').remove()
      @updateAttributeSelectors(item)
      if attribute.preview isnt false
        @preview(item)
    )

    # build initial params
    if !_.isEmpty(params[attribute.name])
      selectorExists = false
      for groupAndAttribute, meta of params[attribute.name]
        selectorExists = true

        # build and append
        row = @rowContainer(groups, elements, attribute)
        @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, meta, attribute)
        item.filter('.js-filter').append(row)

    else
      for groupAndAttribute in defaults

        # build and append
        row = @rowContainer(groups, elements, attribute)
        @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, {}, attribute)
        item.filter('.js-filter').append(row)

    # change attribute selector
    item.delegate('.js-attributeSelector select', 'change', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @updateAttributeSelectors(item)
    )

    # change operator selector
    item.delegate('.js-operator select', 'change', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @buildOperator(item, elementRow, groupAndAttribute, elements, {}, attribute)
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

      item.on('change', 'select', (e) ->
        triggerSearch()
      )
      item.on('change keyup', 'input', (e) ->
        triggerSearch()
      )

    @disableRemoveForOneAttribute(item)
    item

  @preview: (item) ->
    params = App.ControllerForm.params(item)
    App.Ajax.request(
      id:    'ticket_selector'
      type:  'POST'
      url:   "#{App.Config.get('api_path')}/tickets/selector"
      data:        JSON.stringify(params)
      processData: true,
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        item.find('.js-previewCounterContainer').removeClass('hide')
        item.find('.js-previewLoader').addClass('hide')
        @ticketTable(data.ticket_ids, data.ticket_count, item)
    )

  @ticketTable: (ticket_ids, ticket_count, item) ->
    item.find('.js-previewCounter').html(ticket_count)
    new App.TicketList(
      tableId:    'ticket-selector'
      el:         item.find('.js-previewTable')
      ticket_ids: ticket_ids
    )

  @buildAttributeSelector: (groups, elements) ->
    selection = $('<select class="form-control"></select>')
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

  # disable - if we only have one attribute
  @disableRemoveForOneAttribute: (elementFull) ->
    if elementFull.find('.js-attributeSelector select').length > 1
      elementFull.find('.js-remove').removeClass('is-disabled')
    else
      elementFull.find('.js-remove').addClass('is-disabled')

  @updateAttributeSelectors: (elementFull) ->

    # enable all
    elementFull.find('.js-attributeSelector select option').removeAttr('disabled')

    # disable all used attributes
    elementFull.find('.js-attributeSelector select').each(->
      keyLocal = $(@).val()
      elementFull.find('.js-attributeSelector select option[value="' + keyLocal + '"]').attr('disabled', true)
    )

    # disable - if we only have one attribute
    @disableRemoveForOneAttribute(elementFull)


  @rebuildAttributeSelectors: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->

    # set attribute
    if groupAndAttribute
      elementRow.find('.js-attributeSelector select').val(groupAndAttribute)

    @buildOperator(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @buildOperator: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')

    name = "#{attribute.name}::#{groupAndAttribute}::operator"

    if !meta.operator && currentOperator
      meta.operator = currentOperator

    selection = $("<select class=\"form-control\" name=\"#{name}\"></select>")

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
        operatorName = App.i18n.translateInline(operator)
        selected = ''
        if !groupAndAttribute.match(/^ticket/) && operator is 'has changed'
          # do nothing, only show "has changed" in ticket attributes
        else
          if meta.operator is operator
            selected = 'selected="selected"'
          selection.append("<option value=\"#{operator}\" #{selected}>#{operatorName}</option>")
      selection

    elementRow.find('.js-operator select').replaceWith(selection)

    @buildPreCondition(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @buildPreCondition: (elementFull, elementRow, groupAndAttribute, elements, meta, attributeConfig) ->
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

    name = "#{attribute.name}::#{groupAndAttribute}::value"
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

    elementRow.find('.js-preCondition').closest('.controls').removeClass('hide')
    name = "#{attribute.name}::#{groupAndAttribute}::pre_condition"

    selection = $("<select class=\"form-control\" name=\"#{name}\" ></select>")
    options = {}
    if preCondition is 'user'
      options =
        'current_user.id': App.i18n.translateInline('current user')
        'specific': App.i18n.translateInline('specific user')
        'not_set': App.i18n.translateInline('not set (not defined)')
    else if preCondition is 'org'
      options =
        'current_user.organization_id': App.i18n.translateInline('current user organization')
        'specific': App.i18n.translateInline('specific organization')
        'not_set': App.i18n.translateInline('not set (not defined)')

    for key, value of options
      selected = ''
      if key is meta.pre_condition
        selected = 'selected="selected"'
      selection.append("<option value=\"#{key}\" #{selected}>#{App.i18n.translateInline(value)}</option>")
    elementRow.find('.js-preCondition').closest('.controls').removeClass('hide')
    elementRow.find('.js-preCondition select').replaceWith(selection)

    elementRow.find('.js-preCondition select').bind('change', (e) ->
      toggleValue()
    )

    @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
    toggleValue()

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    name = "#{attribute.name}::#{groupAndAttribute}::value"

    # build new item
    attributeConfig = elements[groupAndAttribute]
    config = _.clone(attributeConfig)

    if config.relation is 'User'
      config.tag = 'user_autocompletion'
    if config.relation is 'Organization'
      config.tag = 'autocompletion_ajax'

    # render ui element
    item = ''
    if config && App.UiElement[config.tag]
      config['name'] = name
      if attribute.value && attribute.value[groupAndAttribute]
        config['value'] = _.clone(attribute.value[groupAndAttribute]['value'])
      if 'multiple' of config
        config.multiple = true
        config.nulloption = false
      if config.relation is 'User'
        config.multiple = false
        config.nulloption = false
        config.guess = false
      if config.relation is 'Organization'
        config.multiple = false
        config.nulloption = false
        config.guess = false
      if config.tag is 'checkbox'
        config.tag = 'select'
      if config.tag is 'datetime'
        config.validationContainer = 'self'
      tagSearch = "#{config.tag}_search"
      if App.UiElement[tagSearch]
        item = App.UiElement[tagSearch].render(config, {})
      else
        item = App.UiElement[config.tag].render(config, {})
    if meta.operator is 'before (relative)' || meta.operator is 'within next (relative)' || meta.operator is 'within last (relative)' || meta.operator is 'after (relative)' || meta.operator is 'from (relative)' || meta.operator is 'till (relative)'
      config['name'] = "#{attribute.name}::#{groupAndAttribute}"
      if attribute.value && attribute.value[groupAndAttribute]
        config['value'] = _.clone(attribute.value[groupAndAttribute])
      item = App.UiElement['time_range'].render(config, {})

    elementRow.find('.js-value').removeClass('hide').html(item)
    if meta.operator is 'has changed'
      elementRow.find('.js-value').addClass('hide')
      elementRow.find('.js-preCondition').closest('.controls').addClass('hide')
    else
      elementRow.find('.js-value').removeClass('hide')

  @humanText: (condition) ->
    none = App.i18n.translateContent('No filter.')
    return [none] if _.isEmpty(condition)
    [defaults, groups, elements] = @defaults()
    rules = []
    for attribute, meta of condition

      objectAttribute = attribute.split(/\./)

      # get stored params
      if meta && objectAttribute[1]
        operator = meta.operator
        value = meta.value
        model = toCamelCase(objectAttribute[0])
        config = elements[attribute]

        valueHuman = []
        if _.isArray(value)
          for data in value
            r = @humanTextLookup(config, data)
            valueHuman.push r
        else
          valueHuman.push @humanTextLookup(config, value)

        if valueHuman.join
          valueHuman = valueHuman.join(', ')
        rules.push "#{App.i18n.translateContent('Where')} <b>#{App.i18n.translateContent(model)} -> #{App.i18n.translateContent(config.display)}</b> #{App.i18n.translateContent(operator)} <b>#{valueHuman}</b>."

    return [none] if _.isEmpty(rules)
    rules

  @humanTextLookup: (config, value) ->
    return value if !App[config.relation]
    return value if !App[config.relation].exists(value)
    data = App[config.relation].fullLocal(value)
    return value if !data
    if data.displayName
      return App.i18n.translateContent(data.displayName())
    valueHuman.push App.i18n.translateContent(data.name)
