# coffeelint: disable=camel_case_classes
class App.UiElement.postmaster_set
  @defaults: ->
    groups =
      general:
        name: 'Ticket'
        options: [
          {
            value:    'x-zammad-ticket-priority_id'
            name:     'Priority'
            relation: 'TicketPriority'
          },
          {
            value:    'x-zammad-ticket-state_id'
            name:     'State'
            relation: 'TicketState'
          },
          {
            value:    'x-zammad-ticket-customer_id'
            name:     'Customer'
            relation: 'User'
            tag:      'user_autocompletion'
            disableCreateUser: true,
          },
          {

            value:    'x-zammad-ticket-group_id'
            name:     'Group'
            relation: 'Group'
          },
          {
            value:    'x-zammad-ticket-owner_id'
            name:     'Owner'
            relation: 'User'
            tag:      'user_autocompletion'
            disableCreateUser: true,
          },
          {
            value:    'x-zammad-ignore'
            name:     'Ignore Message'
            options:  { true: 'yes', false: 'no'}
          },
        ]
      expert:
        name: 'Article'
        options: [
          {
            value:    'x-zammad-article-internal'
            name:     'Internal'
            options:  { true: 'yes', false: 'no'}
          },
          {
            value:    'x-zammad-article-type_id'
            name:     'Type'
            relation: 'TicketArticleType'
          },
          {
            value:    'x-zammad-article-sender_id'
            name:     'Sender'
            relation: 'TicketArticleSender'
          },
        ]

    groups

  @render: (attribute, params = {}) ->

    groups = @defaults()

    selector = @buildAttributeSelector(groups, attribute)

    # scaffold of match elements
    item = $( App.view('generic/postmaster_set')( attribute: attribute ) )
    item.find('.js-attributeSelector').prepend(selector)

    # add filter
    item.find('.js-add').bind('click', (e) ->
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

    # change attribute selector
    item.find('.js-attributeSelector select').bind('change', (e) =>
      key = $(e.target).find('option:selected').attr('value')
      elementRow = $(e.target).closest('.js-filterElement')

      @rebuildAttributeSelectors(item, elementRow, key, attribute)
      @buildValue(item, elementRow, key, groups, undefined, undefined, attribute)
    )

    # build inital params
    if !_.isEmpty(params[attribute.name])

      selectorExists = false
      for key, meta of params[attribute.name]
        selectorExists = true
        operator = meta.operator
        value = meta.value

        # get selector rows
        elementFirst = item.find('.js-filterElement').first()
        elementLast = item.find('.js-filterElement').last()

        # clone, rebuild and append
        elementClone = elementFirst.clone(true)
        @rebuildAttributeSelectors(item, elementClone, key, attribute)
        @buildValue(item, elementClone, key, groups, value, operator, attribute)
        elementLast.after(elementClone)

      # remove first dummy row
      if selectorExists
        item.find('.js-filterElement').first().remove()

    item

  @buildValue: (elementFull, elementRow, key, groups, value, operator, attribute) ->

    # do nothing if item already exists
    name = "#{attribute.name}::#{key}::value"
    return if elementRow.find("[name=\"#{name}\"]").get(0)
    config = {}
    for groupName, meta of groups
      for entry in meta.options
        if entry.value is key
          config = entry
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

  @buildAttributeSelector: (groups, attribute) ->
    selection = $('<select class="form-control"></select>')
    for groupKey, groupMeta of groups
      displayName = App.i18n.translateInline(groupMeta.name)
      selection.closest('select').append("<optgroup label=\"#{displayName}\" class=\"js-#{groupKey}\"></optgroup>")
      optgroup = selection.find("optgroup.js-#{groupKey}")
      for entry in groupMeta.options
        displayName = App.i18n.translateInline(entry.name)
        optgroup.append("<option value=\"#{entry.value}\">#{displayName}</option>")
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

