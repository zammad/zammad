# coffeelint: disable=camel_case_classes
class App.UiElement.ticket_perform_action
  @defaults: ->
    defaults = ['ticket.state_id']

    groups =
      ticket:
        name: 'Ticket'
        model: 'Ticket'

    # megre config
    elements = {}
    for groupKey, groupMeta of groups
      for row in App[groupMeta.model].configure_attributes

        # ignore passwords and relations
        if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids'

          # ignore readonly attributes
          if !row.readonly
            config = _.clone(row)
            elements["#{groupKey}.#{config.name}"] = config

    [defaults, groups, elements]

  @render: (attribute, params = {}) ->

    [defaults, groups, elements] = @defaults()

    selector = @buildAttributeSelector(groups, elements)

    # return item
    item = $( App.view('generic/ticket_perform_action')( attribute: attribute ) )
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
      groupAndAttribute = $(e.target).find('option:selected').attr('value')
      elementRow = $(e.target).closest('.js-filterElement')

      @rebuildAttributeSelectors(item, elementRow, groupAndAttribute)
      @buildValue(item, elementRow, groupAndAttribute, elements, undefined, attribute)
    )

    # build inital params
    if !_.isEmpty(params[attribute.name])

      selectorExists = false
      for groupAndAttribute, meta of params[attribute.name]
        selectorExists = true
        value = meta.value

        # get selector rows
        elementFirst = item.find('.js-filterElement').first()
        elementLast = item.find('.js-filterElement').last()

        # clone, rebuild and append
        elementClone = elementFirst.clone(true)
        @rebuildAttributeSelectors(item, elementClone, groupAndAttribute)
        @buildValue(item, elementClone, groupAndAttribute, elements, value, attribute)
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

    item

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, value, attribute) ->

    # do nothing if item already exists
    name = "#{attribute.name}::#{groupAndAttribute}::value"
    return if elementRow.find("[name=\"#{name}\"]").get(0)
    return if elementRow.find("[data-name=\"#{name}\"]").get(0)

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
        config.multiple = false
        config.nulloption = false
      if config.tag is 'checkbox'
        config.tag = 'select'
      tagSearch = "#{config.tag}_search"
      if App.UiElement[tagSearch]
        item = App.UiElement[tagSearch].render(config, {})
      else
        item = App.UiElement[config.tag].render(config, {})
    elementRow.find('.js-value').html(item)

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

  @rebuildAttributeSelectors: (elementFull, elementRow, groupAndAttribute) ->

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
    if groupAndAttribute
      elementRow.find('.js-attributeSelector select').val(groupAndAttribute)

  @humanText: (condition) ->
    none = App.i18n.translateContent('No filter.')
    return [none] if _.isEmpty(condition)
    [defaults, groups, elements] = @defaults()
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
