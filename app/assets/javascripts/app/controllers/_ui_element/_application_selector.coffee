# coffeelint: disable=camel_case_classes
class App.UiElement.ApplicationSelector
  @defaults: (attribute = {}, params = {}) ->
    defaults = ['ticket.state_id']

    groups =
      ticket:
        name: __('Ticket')
        model: 'Ticket'
      article:
        name: __('Article')
        model: 'TicketArticle'
      customer:
        name: __('Customer')
        model: 'User'
      organization:
        name: __('Organization')
        model: 'Organization'

    if attribute.executionTime
      groups.execution_time =
        name: __('Execution Time')

    operators_type =
      '^datetime$': [__('today'), __('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)')]
      '^timestamp$': [__('today'), __('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)')]
      '^date$': [__('today'), 'before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)']
      'boolean$': [__('is'), __('is not')]
      'integer$': [__('is'), __('is not'), __('is less than'), __('is greater than')]
      '^radio$': [__('is'), __('is not')]
      '^select$': [__('is'), __('is not')]
      '^multiselect$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
      '^tree_select$': [__('is'), __('is not')]
      '^multi_tree_select$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
      '^autocompletion_ajax_external_data_source$': [__('is'), __('is not')]
      '^input$': [__('contains'), __('contains not'), __('is any of'), __('is none of'), __('starts with one of'), __('ends with one of')]
      '^richtext$': [__('contains'), __('contains not')]
      '^textarea$': [__('contains'), __('contains not')]
      '^tag$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]

    if attribute.hasChanged
      operators_type =
        '^datetime$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        '^timestamp$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        '^date$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        'boolean$': [__('is'), __('is not'), __('has changed')]
        'integer$': [__('is'), __('is not'), __('is less than'), __('is greater than'), __('has changed')]
        '^radio$': [__('is'), __('is not'), __('has changed')]
        '^select$': [__('is'), __('is not'), __('has changed')]
        '^multiselect$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
        '^tree_select$': [__('is'), __('is not'), __('has changed')]
        '^multi_tree_select$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
        '^autocompletion_ajax_external_data_source$': [__('is'), __('is not'), __('has changed')]
        '^input$': [__('contains'), __('contains not'), __('has changed'), __('is any of'), __('is none of'), __('starts with one of'), __('ends with one of')]
        '^richtext$': [__('contains'), __('contains not'), __('has changed')]
        '^textarea$': [__('contains'), __('contains not'), __('has changed')]
        '^tag$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]

    if attribute.hasRegexOperators && App.Config.get('ticket_conditions_allow_regular_expression_operators')
      operators_type['^input$'].push(__('matches regex'), __('does not match regex'))

    operators_name =
      '_id$': [__('is'), __('is not')]
      '_ids$': [__('is'), __('is not')]
      'active$': [__('is'), __('is not')]

    if attribute.hasChanged
      operators_name =
        '_id$': [__('is'), __('is not'), __('has changed')]
        '_ids$': [__('is'), __('is not'), __('has changed')]
        'active$': [__('is'), __('is not'), __('has changed')]

    # merge config
    elements = {}

    if attribute.article is false
      delete groups.article

    if attribute.action
      elements['ticket.action'] =
        name: 'action'
        display: __('Action')
        tag: 'select'
        null: false
        translate: true
        options:
          create:                  __('created')
          update:                  __('updated')
          'update.merged_into':    __('merged into')
          'update.received_merge': __('received merge')
        operator: [__('is'), __('is not')]

    for groupKey, groupMeta of groups
      if groupKey is 'article'
        if attribute.action
          elements['article.action'] =
            name: 'action'
            display: __('Action')
            tag: 'select'
            null: false
            translate: true
            options:
              create: 'created'
            operator: [__('is'), __('is not')]
          elements['article.time_accounting'] =
            name: 'time_accounting'
            display: __('Time Accounting')
            tag: 'select'
            null: false
            translate: true
            options:
              create: 'created'
            operator: [__('is set'), __('not set')]

      if groupKey is 'execution_time'
        if attribute.executionTime
          elements['execution_time.calendar_id'] =
            name: 'calendar_id'
            display: __('Calendar')
            tag: 'select'
            relation: 'Calendar'
            null: false
            translate: false
            operator: [__('is in working time'), __('is not in working time')]

      else
        attributesByObject = App.ObjectManagerAttribute.selectorAttributesByObject()
        configureAttributes = attributesByObject[groupMeta.model] || []
        for config in configureAttributes
          config.objectName    = groupMeta.model
          config.attributeName = config.name

          # ignore passwords and relations
          if config.type isnt 'password' && config.name.substr(config.name.length-4,4) isnt '_ids' && config.searchable isnt false
            config.default  = undefined
            if config.type is 'email' || config.type is 'tel' || config.type is 'url'
              config.type = 'text'
            if config.tag is 'select' or config.tag is 'autocompletion_ajax_external_data_source'
              config.multiple = true
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

    if attribute.hasReached
      [
        'ticket.pending_time',
        'ticket.escalation_at',
      ].forEach (element_name) ->
        new_operator = clone(elements[element_name]['operator'])
        new_operator.push(__('has reached'))
        if element_name == 'ticket.escalation_at'
          new_operator.push(__('has reached warning'))
        elements[element_name]['operator'] = new_operator

    if attribute.out_of_office
      elements['ticket.out_of_office_replacement_id'] =
        name: 'out_of_office_replacement_id'
        display: __('Out of office replacement')
        tag: 'autocompletion_ajax'
        relation: 'User'
        null: false
        translate: true
        operator: [__('is'), __('is not')]

    # Remove 'has changed' operator from attributes which don't support the operator.
    ['ticket.created_at', 'ticket.updated_at'].forEach (element_name) ->
      elements[element_name]['operator'] = elements[element_name]['operator'].filter (item) -> item != 'has changed'

    elements['ticket.mention_user_ids'] =
      name: 'mention_user_ids'
      display: __('Subscribe')
      tag: 'autocompletion_ajax'
      relation: 'User'
      null: false
      translate: true
      operator: [__('is'), __('is not')]

    [defaults, groups, elements]

  @rowContainer: (groups, elements, attribute) ->
    row = $( App.view('generic/application_selector_row')(
      attribute: attribute
      pre_condition: @HasPreCondition()
    ) )
    selector = @buildAttributeSelector(groups, elements)
    row.find('.js-attributeSelector').prepend(selector)
    row

  @emptyBody: (attribute) ->
    return $( App.view('generic/application_selector_empty')(
      attribute: attribute
    ) )

  @prepareParamValue: (item, elements, attribute, params) ->
    paramValue = {}

    for groupAndAttribute, meta of params[attribute.name]
      continue if !elements[groupAndAttribute]
      paramValue[groupAndAttribute] = meta

    paramValue

  @render: (attribute, params = {}) ->
    item = $( App.view('generic/application_selector')(attribute: attribute) )
    @renderItem(item, attribute, params)

  @renderItem: (item, attribute, params) ->
    [defaults, groups, elements] = @defaults(attribute, params)

    # add filter
    item.off('click.application_selector', '.js-add').on('click.application_selector', '.js-add', (e) =>
      element = $(e.target).closest('.js-filterElement')

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
      row = @rowContainer(groups, elements, attribute)

      emptyRow = item.find('div.horizontal-filter-body')
      if emptyRow.find('input.empty:hidden').length > 0 && @hasEmptySelectorAtStart()
        emptyRow.parent().replaceWith(row)
      else
        element.after(row)
        row.find('.js-attributeSelector select').trigger('change')

      @rebuildAttributeSelectors(item, row, field, elements, {}, attribute)
      @saveParams(item)

      if attribute.preview isnt false
        @preview(item)
    )

    # remove filter
    item.off('click.application_selector', '.filter-control.js-remove').on('click.application_selector', '.filter-control.js-remove', (e) =>
      return if $(e.currentTarget).hasClass('is-disabled')

      if @hasEmptySelectorAtStart()
        if item.find('.filter-control.js-remove').length > 1
          $(e.target).closest('.js-filterElement').remove()
        else
          $(e.target).closest('.js-filterElement').find('div.horizontal-filter-body').html(@emptyBody(attribute))
      else
        $(e.target).closest('.js-filterElement').remove()

      @updateAttributeSelectors(item)
      @saveParams(item)

      if attribute.preview isnt false
        @preview(item)
    )

    paramValue = @prepareParamValue(item, elements, attribute, params)

    # build initial params
    if !_.isEmpty(paramValue)
      @renderParamValue(item, attribute, params, paramValue)
    else
      if @hasEmptySelectorAtStart()
        row = @rowContainer(groups, elements, attribute)
        row.find('.horizontal-filter-body').html(@emptyBody(attribute))
        item.filter('.js-filter').append(row)
      else
        for groupAndAttribute in defaults

          # build and append
          row = @rowContainer(groups, elements, attribute)
          @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, {}, attribute)
          item.filter('.js-filter').append(row)

    # change attribute selector
    item.off('change.application_selector', '.js-attributeSelector select').on('change.application_selector', '.js-attributeSelector select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @updateAttributeSelectors(item)
      @saveParams(item)
    )

    # change operator selector
    item.off('change.application_selector', '.js-operator select').on('change.application_selector', '.js-operator select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      return if !groupAndAttribute
      @buildOperator(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @saveParams(item)
    )

    # change pre-condition selector
    item.off('change.application_selector', '.js-preCondition select').on('change.application_selector', '.js-preCondition select', =>
      @saveParams(item)
    )

    # change attribute value
    item.off('change.application_selector keyup.application_selector', '.js-value .form-control').on('change.application_selector keyup.application_selector', '.js-value .form-control', =>
      @saveParams(item)
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
    @saveParams(item)

    if attribute.preview isnt false
      @preview(item)

    item

  @renderParamValue: (item, attribute, params, paramValue) ->
    [defaults, groups, elements] = @defaults(attribute, params)

    for groupAndAttribute, meta of paramValue

      # build and append
      row = @rowContainer(groups, elements, attribute)
      @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, meta, attribute)
      item.filter('.js-filter').append(row)

  @saveParams: (item) ->
    @params = App.ControllerForm.params(item)

  @preview: (item) ->
    params = App.ControllerForm.params(item)
    App.Ajax.request(
      id:    'application_selector'
      type:  'POST'
      url:   "#{App.Config.get('api_path')}/tickets/selector"
      data:        JSON.stringify(params)
      processData: true,
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        item.find('.js-previewCounterContainer').removeClass('hide')
        item.find('.js-previewLoader').addClass('hide')
        @ticketTable(data.object_ids, data.object_count, item)
    )

  @ticketTable: (ticket_ids, ticket_count, item) ->
    item.find('.js-previewCounter').html(ticket_count)
    new App.TicketList(
      tableId:    'ticket-selector'
      el:         item.find('.js-previewTable')
      ticket_ids: ticket_ids
    )

  @showAlert: (head, message, item) ->
    alert = item.filter('.js-alert')
    alert.empty()
      .append($('<strong></strong>').text(App.i18n.translateContent(head)))
      .append('\xa0') # extra space
      .append(App.i18n.translateContent(message))
      .removeClass('hidden')

  @hideAlert: (item) ->
    alert = item.filter('.js-alert')
    alert.addClass('hidden')
      .empty()

  @buildAttributeSelector: (groups, elements) ->
    selection = $('<select class="form-control"></select>')
    for groupKey, groupMeta of groups
      groupKeyClass = groupKey.replace('.', '-')
      displayName = App.i18n.translatePlain(groupMeta.name)
      selection.closest('select').append("<optgroup label=\"#{displayName}\" class=\"js-#{groupKeyClass}\"></optgroup>")
      optgroup = selection.find("optgroup.js-#{groupKeyClass}")
      for elementKey, elementGroup of elements
        spacer = elementKey.split(/\./).slice(0, -1).join('.')
        if spacer is groupKey
          attributeConfig = elements[elementKey]
          if attributeConfig.operator
            displayName = App.i18n.translatePlain(attributeConfig.display)
            optgroup.append("<option value=\"#{elementKey}\">#{displayName}</option>")
    selection

  # disable - if we only have one attribute
  @disableRemoveForOneAttribute: (elementFull) ->
    if @hasEmptySelectorAtStart()
      if elementFull.find('div.horizontal-filter-body input.empty:hidden').length > 0 && elementFull.find('.filter-control.js-remove').length < 2
        elementFull.find('.filter-control.js-remove').addClass('is-disabled')
      else
        elementFull.find('.filter-control.js-remove').removeClass('is-disabled')
    else
      if elementFull.find('.js-attributeSelector select').length > 1
        elementFull.find('.filter-control.js-remove').removeClass('is-disabled')
      else
        elementFull.find('.filter-control.js-remove').addClass('is-disabled')

  @updateAttributeSelectors: (elementFull) ->
    if !@hasDuplicateSelector()

      # enable all
      elementFull.find('.js-attributeSelector select option').prop('disabled', false)

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

  @mapOperatorDisplayName: (operator) ->
    return operator

  @buildOperator: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')

    name = "#{attribute.name}::#{groupAndAttribute}::operator"

    if !meta.operator && currentOperator
      meta.operator = currentOperator

    selection = $("<select class=\"form-control\" name=\"#{name}\"></select>")

    attributeConfig = elements[groupAndAttribute]

    # Compatibility layer for renamed operators (#4709).
    meta.operator = @migrateOperator(attributeConfig, meta.operator)

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
        operatorName = App.i18n.translatePlain(@mapOperatorDisplayName(operator))
        selected = ''
        if !groupAndAttribute.match(/^ticket/) && _.contains(['has changed', 'just changed', 'is modified'], operator)
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
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')
    currentPreCondition = elementRow.find('.js-preCondition option:selected').attr('value')

    if !meta.pre_condition
      if currentPreCondition
        meta.pre_condition = currentPreCondition
      else if !_.isEmpty(meta.value)
        meta.pre_condition = 'specific'

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

    elementRow.find('.js-preCondition').removeClass('hide')
    name = "#{attribute.name}::#{groupAndAttribute}::pre_condition"

    selection = $("<select class=\"form-control\" name=\"#{name}\" ></select>")
    options = {}
    if preCondition is 'user'
      if attributeConfig.noCurrentUser isnt true
        options['current_user.id'] = App.i18n.translatePlain('current user')
      options['specific'] = App.i18n.translatePlain('specific user')
      if attributeConfig.noNotSet isnt true
        options['not_set'] = App.i18n.translatePlain('not set (not defined)')
    else if preCondition is 'org'
      if attributeConfig.noCurrentUser isnt true
        options['current_user.organization_id'] = App.i18n.translatePlain('current user organization')
      options['specific'] = App.i18n.translatePlain('specific organization')
      if attributeConfig.noNotSet isnt true
        options['not_set'] = App.i18n.translatePlain('not set (not defined)')

    for key, value of options
      selected = ''
      if key is meta.pre_condition
        selected = 'selected="selected"'
      selection.append("<option value=\"#{key}\" #{selected}>#{App.i18n.translatePlain(value)}</option>")
    elementRow.find('.js-preCondition').closest('.controls').removeClass('hide')
    elementRow.find('.js-preCondition select').replaceWith(selection)

    elementRow.find('.js-preCondition select').off('change.application_selector').on('change.application_selector', (e) ->
      toggleValue()
    )

    @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
    toggleValue()

  @buildValueConfigValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    return _.clone(attribute.value[groupAndAttribute]['value'])

  @buildValueName: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute, valueType) ->
    prefix = if valueType then "{#{valueType}}" else ''
    return "#{prefix}#{attribute.name}::#{groupAndAttribute}::value"

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    # build new item
    attributeConfig = elements[groupAndAttribute]
    config = _.clone(attributeConfig)

    if config.relation is 'User'
      config.tag = 'user_autocompletion'
    if config.relation is 'Organization'
      config.tag = 'autocompletion_ajax'

    if config.tag and @tokenfieldTagRegex() and config.tag.match(@tokenfieldTagRegex()) and _.contains(['is any of', 'is none of', 'starts with one of', 'ends with one of'], meta.operator)
      config.tag = 'tokenfield'

    # render ui element
    item = ''
    if config && App.UiElement[config.tag] && meta.operator isnt 'today'
      { valueType } = App.UiElement[config.tag]
      config = @buildValueConfigNameValue(config, elementFull, elementRow, groupAndAttribute, elements, meta, attribute, valueType)

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
      config = @buildValueConfigRelativeNameValue(config, elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

      item = App.UiElement['time_range'].render(config, {})

    elementRow.find('.js-value').removeClass('hide').html(item)

    # Hide pre-condition and value fields if the operator is one of the following:
    #   - has changed
    #   - has reached
    #   - has reached warning
    #   - changed to
    if _.contains(['has reached', 'has reached warning', 'has changed', 'just changed', 'is modified', 'not set', 'is set'], meta.operator)
      elementRow.find('.js-value').addClass('hide')
      elementRow.find('.js-preCondition').closest('.controls').addClass('hide')
    else
      elementRow.find('.js-value').removeClass('hide')

  @buildValueConfigNameValue: (config, elementFull, elementRow, groupAndAttribute, elements, meta, attribute, valueType) ->
    config['name'] = @buildValueName(elementFull, elementRow, groupAndAttribute, elements, meta, attribute, valueType)
    if attribute.value && attribute.value[groupAndAttribute]
      config['value'] = @buildValueConfigValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

    config

  @buildValueConfigRelativeNameValue: (config, elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    config['name'] = "#{attribute.name}::#{groupAndAttribute}"
    if attribute.value && attribute.value[groupAndAttribute]
      config['value'] = _.clone(attribute.value[groupAndAttribute])

    config

  @renderConfig: (config, meta) ->
    tagSearch = "#{config.tag}_search"
    return App.UiElement[tagSearch].render(config, {}) if App.UiElement[tagSearch]
    return App.UiElement[config.tag].render(config, {})

  @buildValueConfigMultiple: (config, meta) ->
    config.multiple = true
    config.nulloption = false
    return config

  @humanText: (condition) ->
    none = App.i18n.translateContent('No filter was configured.')
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

  @HasPreCondition: ->
    return true

  @hasEmptySelectorAtStart: ->
    return false

  @hasDuplicateSelector: ->
    return false

  @coreWorkflowCustomModulesActive: ->
    enabled = false
    for workflow in App.CoreWorkflow.all()
      continue if !workflow.changeable
      continue if !workflow.condition_saved['custom.module'] && !workflow.condition_selected['custom.module'] && !workflow.perform['custom.module']
      enabled = true
      break
    return enabled

  @tokenfieldTagRegex: ->
    new RegExp('^input$', 'i')

  @migrateOperator: (attributeConfig, operator) ->
    if attributeConfig.tag and @tokenfieldTagRegex() and attributeConfig.tag.match(@tokenfieldTagRegex())
      switch operator
        when 'is' then return 'is any of'
        when 'is not' then return 'is none of'
        when 'starts with' then return 'starts with one of'
        when 'ends with' then return 'ends with one of'

    operator
