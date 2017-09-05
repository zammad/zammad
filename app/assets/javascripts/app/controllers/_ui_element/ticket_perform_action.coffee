# coffeelint: disable=camel_case_classes
class App.UiElement.ticket_perform_action
  @defaults: (attribute) ->
    defaults = ['ticket.state_id']

    groups =
      ticket:
        name: 'Ticket'
        model: 'Ticket'

    if attribute.notification
      groups.notification =
        name: 'Notification'
        model: 'Notification'

    # megre config
    elements = {}
    for groupKey, groupMeta of groups
      if !App[groupMeta.model]
        elements["#{groupKey}.email"] = { name: 'email', display: 'Email' }
      else

        for row in App[groupMeta.model].configure_attributes

          # ignore passwords and relations
          if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids'

            # ignore readonly attributes
            if !row.readonly
              config = _.clone(row)
              if config.tag is 'tag'
                config.operator = ['add', 'remove']
              elements["#{groupKey}.#{config.name}"] = config

    # add ticket deletion action
    if attribute.ticket_delete
      elements['ticket.action'] =
        name: 'action'
        display: 'Action'
        tag: 'select'
        null: false
        translate: true
        options:
          delete: 'Delete'

    [defaults, groups, elements]

  @render: (attribute, params = {}) ->

    [defaults, groups, elements] = @defaults(attribute)

    selector = @buildAttributeSelector(groups, elements)

    # return item
    item = $( App.view('generic/ticket_perform_action/index')( attribute: attribute ) )
    item.find('.js-attributeSelector').prepend(selector)

    # add filter
    item.find('.js-add').bind('click', (e) =>
      element = $(e.target).closest('.js-filterElement')
      elementClone = element.clone(true)
      element.after(elementClone)
      elementClone.find('.js-attributeSelector select').trigger('change')
      @updateAttributeSelectors(item)
    )

    # remove filter
    item.find('.js-remove').bind('click', (e) =>
      return if $(e.currentTarget).hasClass('is-disabled')
      $(e.target).closest('.js-filterElement').remove()
      @updateAttributeSelectors(item)
    )

    # change attribute selector
    item.find('.js-attributeSelector select').bind('change', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @updateAttributeSelectors(item)
    )

    # build inital params
    if !_.isEmpty(params[attribute.name])

      selectorExists = false
      for groupAndAttribute, meta of params[attribute.name]
        selectorExists = true

        # get selector rows
        elementFirst = item.find('.js-filterElement').first()
        elementLast = item.find('.js-filterElement').last()

        # clone, rebuild and append
        elementClone = elementFirst.clone(true)
        @rebuildAttributeSelectors(item, elementClone, groupAndAttribute, elements, meta, attribute)
        elementLast.after(elementClone)

      # remove first dummy row
      if selectorExists
        item.find('.js-filterElement').first().remove()

    else
      for groupAndAttribute in defaults

        # get selector rows
        elementFirst = item.find('.js-filterElement').first()
        elementLast = item.find('.js-filterElement').last()

        # clone, rebuild and append
        elementClone = elementFirst.clone(true)
        @rebuildAttributeSelectors(item, elementClone, groupAndAttribute, elements, {}, attribute)

        elementLast.after(elementClone)
      item.find('.js-filterElement').first().remove()

    # change attribute selector
    item.find('.js-attributeSelector select').bind('change', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute, elements, {}, attribute)
      @updateAttributeSelectors(item)
    )

    # change operator selector
    item.on('change', '.js-operator select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      @buildOperator(item, elementRow, groupAndAttribute, elements, {}, attribute)
    )

    item

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
          displayName = App.i18n.translateInline(attributeConfig.display)
          optgroup.append("<option value=\"#{elementKey}\">#{displayName}</option>")
    selection

  @updateAttributeSelectors: (elementFull) ->

    # enable all
    elementFull.find('.js-attributeSelector select option').removeAttr('disabled')

    # disable all used attributes
    elementFull.find('.js-attributeSelector select').each(->
      keyLocal = $(@).val()
      elementFull.find('.js-attributeSelector select option[value="' + keyLocal + '"]').attr('disabled', true)
    )

    # disable - if we only have one attribute
    if elementFull.find('.js-attributeSelector select').length > 1
      elementFull.find('.js-remove').removeClass('is-disabled')
    else
      elementFull.find('.js-remove').addClass('is-disabled')

  @rebuildAttributeSelectors: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->

    # set attribute
    if groupAndAttribute
      elementRow.find('.js-attributeSelector select').val(groupAndAttribute)

    if groupAndAttribute is 'notification.email'
      elementRow.find('.js-setAttribute').html('')
      @buildRecipientList(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
    else
      elementRow.find('.js-setNotification').html('')
      if !elementRow.find('.js-setAttribute div').get(0)
        attributeSelectorElement = $( App.view('generic/ticket_perform_action/attribute_selector')(
          attribute: attribute
          name: name
          meta: meta || {}
        ))
        elementRow.find('.js-setAttribute').html(attributeSelectorElement)
      @buildOperator(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @buildOperator: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')

    if !meta.operator
      meta.operator = currentOperator

    name = "#{attribute.name}::#{groupAndAttribute}::operator"

    selection = $("<select class=\"form-control\" name=\"#{name}\"></select>")
    attributeConfig = elements[groupAndAttribute]
    if !attributeConfig.operator
      elementRow.find('.js-operator').addClass('hide')
    else
      elementRow.find('.js-operator').removeClass('hide')
    if attributeConfig.operator
      for operator in attributeConfig.operator
        operatorName = App.i18n.translateInline(operator)
        selected = ''
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

    # force to use auto complition on user lookup
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
      elementRow.find('.js-preCondition').addClass('hide')
      toggleValue()
      @buildValue(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)
      return

    elementRow.find('.js-preCondition').removeClass('hide')
    name = "#{attribute.name}::#{groupAndAttribute}::pre_condition"

    selection = $("<select class=\"form-control\" name=\"#{name}\" ></select>")
    options = {}
    if preCondition is 'user'
      options =
        'current_user.id': App.i18n.translateInline('current user')
        'specific': App.i18n.translateInline('specific user')
        #'set': App.i18n.translateInline('set')
    else if preCondition is 'org'
      options =
        'current_user.organization_id': App.i18n.translateInline('current user organization')
        'specific': App.i18n.translateInline('specific organization')
        #'set': App.i18n.translateInline('set')

    for key, value of options
      selected = ''
      if key is meta.pre_condition
        selected = 'selected="selected"'
      selection.append("<option value=\"#{key}\" #{selected}>#{App.i18n.translateInline(value)}</option>")
    elementRow.find('.js-preCondition').removeClass('hide')
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
      config.multiple = false
      config.nulloption = false
      if config.tag is 'checkbox'
        config.tag = 'select'
      tagSearch = "#{config.tag}_search"
      if App.UiElement[tagSearch]
        item = App.UiElement[tagSearch].render(config, {})
      else
        item = App.UiElement[config.tag].render(config, {})
    if meta.operator is 'before (relative)' || meta.operator is 'within next (relative)' || meta.operator is 'within last (relative)' || meta.operator is 'after (relative)'
      config['name'] = "#{attribute.name}::#{groupAndAttribute}"
      if attribute.value && attribute.value[groupAndAttribute]
        config['value'] = _.clone(attribute.value[groupAndAttribute])
      item = App.UiElement['time_range'].render(config, {})

    elementRow.find('.js-value').removeClass('hide').html(item)

  @buildRecipientList: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->

    return if elementRow.find('.js-setNotification .js-body').get(0)

    options =
      'article_last_sender': 'Article Last Sender'
      'ticket_owner': 'Owner'
      'ticket_customer': 'Customer'
      'ticket_agents': 'All Agents'

    name = "#{attribute.name}::notification.email"

    # meta.recipient was a string in the past (single-select) so we convert it to array if needed
    if !_.isArray(meta.recipient)
      meta.recipient = [meta.recipient]

    column_select_options = []
    for key, value of options
      selected = undefined
      for recipient in meta.recipient
        if key is recipient
          selected = true
      column_select_options.push({ value: key, name: App.i18n.translateInline(value), selected: selected })

    column_select = new App.ColumnSelect
      attribute:
        name:    "#{name}::recipient"
        options: column_select_options

    selection = column_select.element()

    notificationElement = $( App.view('generic/ticket_perform_action/notification_email')(
      attribute: attribute
      name: name
      meta: meta || {}
    ))
    notificationElement.find('.js-recipient select').replaceWith(selection)
    notificationElement.find('.js-body div[contenteditable="true"]').ce(
      mode: 'richtext'
      placeholder: 'message'
      maxlength: 2000
    )
    new App.WidgetPlaceholder(
      el: notificationElement.find('.js-body div[contenteditable="true"]').parent()
      objects: [
        {
          prefix: 'ticket'
          object: 'Ticket'
          display: 'Ticket'
        },
        {
          prefix: 'user'
          object: 'User'
          display: 'Current User'
        },
      ]
    )

    elementRow.find('.js-setNotification').html(notificationElement)

  @humanText: (condition) ->
    none = App.i18n.translateContent('No filter.')
    return [none] if _.isEmpty(condition)
    [defaults, groups, operators, elements] = @defaults()
    rules = []
    for attribute, value of condition

      objectAttribute = attribute.split(/\./)

      # get stored params
      if meta && objectAttribute[1]
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
        rules.push "#{App.i18n.translateContent('Set')} <b>#{App.i18n.translateContent(model)} -> #{App.i18n.translateContent(config.display)}</b> #{App.i18n.translateContent('to')} <b>#{valueHuman}</b>."

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
