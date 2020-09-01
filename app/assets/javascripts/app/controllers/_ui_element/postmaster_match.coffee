# coffeelint: disable=camel_case_classes
class App.UiElement.postmaster_match
  @defaults: ->
    groups =
      general:
        name: 'Basic Settings'
        options: [
          {
            value:    'from'
            name:     'From'
          },
          {
            value:    'to'
            name:     'To'
          },
          {
            value:    'cc'
            name:     'Cc'
          },
          {
            value:    'x-any-recipient'
            name:     'Any Recipient'
          },
          {
            value:    'subject'
            name:     'Subject'
          },
          {
            value:    'body'
            name:     'Body'
          },
        ]
      expert:
        name: 'Expert Settings'
        options: [
          {
            value:    'x-spam'
            name:     'X-Spam'
          },
          {
            value:    'x-spam-flag'
            name:     'X-Spam-Flag'
          },
          {
            value:    'x-spam-level'
            name:     'X-Spam-Level'
          },
          {
            value:    'x-spam-score'
            name:     'X-Spam-Score'
          },
          {
            value:    'x-spam-status'
            name:     'X-Spam-Status'
          },
          {
            value:    'x-dspam-result'
            name:     'X-DSPAM-Result'
          },
          {
            value:    'x-dspam-confidence'
            name:     'X-DSPAM-Confidence'
          },
          {
            value:    'x-dspam-probability'
            name:     'X-DSPAM-Probability'
          },
          {
            value:    'x-dspam-signature'
            name:     'X-DSPAM-Signature'
          },
          {
            value:    'importance'
            name:     'Importance'
          },
          {
            value:    'x-priority'
            name:     'X-Priority'
          },

          {
            value:    'organization'
            name:     'Organization'
          },

          {
            value:    'x-original-to'
            name:     'X-Original-To'
          },
          {
            value:    'delivered-to'
            name:     'Delivered-To'
          },
          {
            value:    'envelope-to'
            name:     'Envelope-To'
          },
          {
            value:    'return-path'
            name:     'Return-Path'
          },
          {
            value:    'mailing-list'
            name:     'Mailing-List'
          },
          {
            value:    'list-id'
            name:     'List-Id'
          },
          {
            value:    'list-unsubscribe'
            name:     'List-Unsubscribe'
          },
          {
            value:    'list-archive'
            name:     'List-Archive'
          },
          {
            value:    'message-id'
            name:     'Message-Id'
          },
          {
            value:    'in-reply-to'
            name:     'In-Reply-To'
          },
          {
            value:    'auto-submitted'
            name:     'Auto-Submitted'
          },
          {
            value:    'x-loop'
            name:     'X-Loop'
          },
        ]

    groups

  @render: (attribute, params = {}) ->

    groups = @defaults()

    selector = @buildAttributeSelector(groups, attribute)

    # scaffold of match elements
    item = $( App.view('generic/postmaster_match')(attribute: attribute) )
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
      return if $(e.currentTarget).hasClass('is-disabled')
      $(e.target).closest('.js-filterElement').remove()
      @rebuildAttributeSelectors(item)
    )

    # change attribute selector
    item.find('.js-attributeSelector select').bind('change', (e) =>
      key = $(e.target).find('option:selected').attr('value')
      elementRow = $(e.target).closest('.js-filterElement')
      @rebuildAttributeSelectors(item, elementRow, key, attribute)
      @rebuildOperater(item, elementRow, key, groups, undefined, attribute)
      @buildValue(item, elementRow, key, groups, undefined, undefined, attribute)
    )

    # change operator
    item.find('.js-operator select').bind('change', (e) =>
      key = $(e.target).find('.js-attributeSelector option:selected').attr('value')
      operator = $(e.target).find('option:selected').attr('value')
      elementRow = $(e.target).closest('.js-filterElement')
      @buildValue(item, elementRow, key, groups, undefined, operator, attribute)
    )

    # build initial params
    if _.isEmpty(params[attribute.name])
      item.find('.js-filterElement .js-attributeSelector select').trigger('change')
    else
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
        @rebuildOperater(item, elementClone, key, groups, operator, attribute)
        @buildValue(item, elementClone, key, groups, value, operator, attribute)
        elementLast.after(elementClone)

      item.find('.js-attributeSelector select').trigger('change')

      # remove first dummy row
      if selectorExists
        item.find('.js-filterElement').first().remove()

    item

  @buildValue: (elementFull, elementRow, key, groups, value, operator, attribute) ->

    # do nothing if item already exists
    name = "#{attribute.name}::#{key}::value"
    return if elementRow.find("[name=\"#{name}\"]").get(0)
    config =
      name: name
      tag: 'input'
      type: 'text'
      value: value
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

  @buildOperator: (elementFull, elementRow, key, groups, current_operator, attribute) ->
    selection = $("<select class=\"form-control\" name=\"#{attribute.name}::#{key}::operator\"></select>")

    for operator in ['contains', 'contains not']
      operatorName = App.i18n.translateInline(operator)
      selected = ''
      if current_operator is operator
        selected = 'selected="selected"'
      selection.append("<option value=\"#{operator}\" #{selected}>#{operatorName}</option>")
    selection

  @rebuildOperater: (elementFull, elementRow, key, groups, current_operator, attribute) ->
    return if !key

    # do nothing if item already exists
    name = "#{attribute.name}::#{key}::operator"
    return if elementRow.find("[name=\"#{name}\"]").get(0)

    # render new operator
    operator = @buildOperator(elementFull, elementRow, key, groups, current_operator, attribute)
    elementRow.find('.js-operator select').replaceWith(operator)
