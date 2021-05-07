# coffeelint: disable=camel_case_classes
class App.UiElement.postmaster_set
  @defaults: ->
    groups =
      ticket:
        name: 'Ticket'
        model: 'Ticket'
        options: [
          {
            value:    'priority_id'
            name:     'Priority'
            relation: 'TicketPriority'
          }
          {
            value:    'state_id'
            name:     'State'
            relation: 'TicketState'
          }
          {
            value:    'tags'
            name:     'Tag'
            tag:      'tag'
          }
          {
            value:    'customer_id'
            name:     'Customer'
            relation: 'User'
            tag:      'user_autocompletion'
            disableCreateObject: true
          }
          {
            value:    'group_id'
            name:     'Group'
            relation: 'Group'
          }
          {
            value:    'owner_id'
            name:     'Owner'
            relation: 'User'
            tag:      'user_autocompletion'
            disableCreateObject: true
          }
        ]
      article:
        name: 'Article'
        options: [
          {
            value:    'x-zammad-article-internal'
            name:     'Internal'
            options:  { true: 'yes', false: 'no'}
          }
          {
            value:    'x-zammad-article-type_id'
            name:     'Type'
            relation: 'TicketArticleType'
          }
          {
            value:    'x-zammad-article-sender_id'
            name:     'Sender'
            relation: 'TicketArticleSender'
          }
        ]
      expert:
        name: 'Expert'
        options: [
          {
            value:    'x-zammad-ignore'
            name:     'Ignore Message'
            options:  { true: 'yes', false: 'no'}
          }
        ]

    elements = {}
    for groupKey, groupMeta of groups
      if groupMeta.model && App[groupMeta.model]
        for row in App[groupMeta.model].configure_attributes

          # ignore passwords and relations
          if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids'

            # ignore readonly attributes
            if !row.readonly
              config = _.clone(row)
              if config.tag is 'tag'
                config.operator = ['add', 'remove']
              elements["x-zammad-ticket-#{config.name}"] = config

    # add additional ticket attributes
    for row in App.Ticket.configure_attributes
      exists = false
      for item in groups.ticket.options
        if item.value is row.name
          exists = true

        # do not support this types
        else if row.tag is 'datetime' || row.tag is 'date' || row.tag is 'tag'
          exists = true

      # ignore passwords and relations
      if !exists && row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids'

        # ignore readonly attributes
        if !row.readonly
          item =
            value:    row.name
            name:     row.display
            relation: row.relation
            tag:      row.tag
            options:  row.options
          groups.ticket.options.push item

    for item in groups.ticket.options
      item.value = "x-zammad-ticket-#{item.value}"

    [elements, groups]

  @placeholder: (elementFull, attribute, params = {}, groups) ->
    item = $( App.view('generic/postmaster_set_row')(attribute: attribute) )
    selector = @buildAttributeSelector(elementFull, groups, attribute, item)
    item.find('.js-attributeSelector').prepend(selector)
    item

  @render: (attribute, params = {}) ->

    [elements, groups] = @defaults()

    # scaffold of match elements
    item = $( App.view('generic/postmaster_set')(attribute: attribute) )

    # add filter
    item.on('click', '.js-add', (e) =>
      element = $(e.target).closest('.js-filterElement')
      placeholder = @placeholder(item, attribute, params, groups)
      if element.get(0)
        element.after(placeholder)
      else
        item.append(placeholder)
      placeholder.find('.js-attributeSelector select').trigger('change')
    )

    # remove filter
    item.on('click', '.js-remove', (e) =>
      return if $(e.currentTarget).hasClass('is-disabled')
      $(e.target).closest('.js-filterElement').remove()
      @rebuildAttributeSelectors(item)
    )

    # change attribute selector
    item.on('change', '.js-attributeSelector select', (e) =>
      elementRow = $(e.target).closest('.js-filterElement')
      groupAndAttribute = elementRow.find('.js-attributeSelector option:selected').attr('value')
      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute, attribute)
      @buildOperator(item, elementRow, groupAndAttribute, elements, {},  attribute)
      @buildValue(item, elementRow, groupAndAttribute, groups, undefined, undefined, attribute)
    )

    # build initial params
    if _.isEmpty(params[attribute.name])
      element = @placeholder(item, attribute, params, groups)
      item.append(element)
      groupAndAttribute = element.find('.js-attributeSelector option:selected').attr('value')
      @rebuildAttributeSelectors(item, element, groupAndAttribute, attribute)
      @buildOperator(item, element, groupAndAttribute, elements, {},  attribute)
      @buildValue(item, element, groupAndAttribute, groups, undefined, undefined, attribute)
      return item

    else
      for key, meta of params[attribute.name]
        operator = meta.operator
        value = meta.value

        # build and append
        element = @placeholder(item, attribute, params, groups)
        groupAndAttribute = element.find('.js-attributeSelector option:selected').attr('value')
        @rebuildAttributeSelectors(item, element, key, attribute)
        @buildOperator(item, element, key, elements, {},  attribute)
        @buildValue(item, element, key, groups, value, operator, attribute)

        item.append(element)
      item.find('.js-attributeSelector select').trigger('change')

    item

  @buildValue: (elementFull, elementRow, key, groups, value, operator, attribute) ->

    # do nothing if item already exists
    name = "#{attribute.name}::#{key}::value"
    return if elementRow.find("[name=\"#{name}\"]").get(0)
    config = {}
    for groupName, meta of groups
      for entry in meta.options
        if entry.value is key
          config = clone(entry)
    if !config.tag
      if config.relation || config.options
        config['tag'] = 'select'
      else
        config['tag'] = 'input'
        config['type'] = 'text'
    config['name'] = name
    config['value'] = value
    item = App.UiElement[config.tag].render(config, {})
    elementRow.find('.js-value').html(item)

  @buildAttributeSelector: (elementFull, groups, attribute) ->

    # find first possible attribute
    selectedValue = ''
    elementFull.find('.js-attributeSelector select option').each(->
      if !selectedValue && !$(@).prop('disabled')
        selectedValue = $(@).val()
    )

    selection = $('<select class="form-control"></select>')
    for groupKey, groupMeta of groups
      displayName = App.i18n.translateInline(groupMeta.name)
      selection.closest('select').append("<optgroup label=\"#{displayName}\" class=\"js-#{groupKey}\"></optgroup>")
      optgroup = selection.find("optgroup.js-#{groupKey}")
      for entry in groupMeta.options
        displayName = App.i18n.translateInline(entry.name)
        selected = ''
        if entry.value is selectedValue
          selected = 'selected="selected"'
        optgroup.append("<option value=\"#{entry.value}\" #{selected}>#{displayName}</option>")
    selection

  @rebuildAttributeSelectors: (elementFull, elementRow, key, attribute) ->

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

    # set attribute
    if key
      elementRow.find('.js-attributeSelector select').val(key)

  @buildOperator: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')

    if !meta.operator
      meta.operator = currentOperator

    name = "#{attribute.name}::#{groupAndAttribute}::operator"

    selection = $("<select class=\"form-control\" name=\"#{name}\"></select>")
    attributeConfig = elements[groupAndAttribute]

    if !attributeConfig || !attributeConfig.operator
      elementRow.find('.js-operator').parent().addClass('hide')
    else
      elementRow.find('.js-operator').parent().removeClass('hide')
    if attributeConfig && attributeConfig.operator
      for operator in attributeConfig.operator
        operatorName = App.i18n.translateInline(operator)
        selected = ''
        if meta.operator is operator
          selected = 'selected="selected"'
        selection.append("<option value=\"#{operator}\" #{selected}>#{operatorName}</option>")
      selection

    elementRow.find('.js-operator select').replaceWith(selection)
