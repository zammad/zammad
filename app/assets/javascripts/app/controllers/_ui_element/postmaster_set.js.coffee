class App.UiElement.postmaster_set
  @render: (attribute, params, form_controller) ->
    addItem = (key, displayName, el, defaultValue = '') =>
      collection = undefined
      for listItem in loopData
        if listItem.value is key
          collection = listItem
      if collection.relation
        add = { name: key, display: displayName, tag: 'select', multiple: false, null: false, nulloption: true, relation: collection.relation, translate: true, default: defaultValue }
      else if collection.options
        add = { name: key, display: displayName, tag: 'select', multiple: false, null: false, nulloption: true, options: collection.options, translate: true, default: defaultValue }
      else
        add = { name: key, display: displayName, tag: 'input', null: false, default: defaultValue }
      itemInput = $( form_controller.formGenItem( add ).append('<svg class="icon icon-diagonal-cross remove"><use xlink:href="#icon-diagonal-cross"></use></svg>' ) )

      # remove on click
      itemInput.find('.remove').bind('click', (e) ->
        e.preventDefault()
        key = $(e.target).closest('.form-group').find('select, input').attr('name')
        return if !key
        $(e.target).closest('.controls').find('.addSelection select option[value="' + key + '"]').show()
        $(e.target).closest('.controls').find('.addSelection select option[value="' + key + '"]').prop('disabled', false)
        $(e.target).closest('.form-group').remove()
      )

      # add new item
      control = el.closest('.perform_set')
      control.find('.list').append(itemInput)
      control.find('.addSelection select').val('')
      control.find('.addSelection select option[value="' + key + '"]').prop('disabled', true)
      control.find('.addSelection select option[value="' + key + '"]').hide()

    # scaffold of perform elements
    item = $('
      <div class="perform_set">
        <hr>
        <div class="list"></div>
        <hr>
        <div>
          <div class="addSelection"></div>
          <svg class="icon icon-plus add"><use xlink:href="#icon-plus"></use></svg>
        </div>
      </div>')


    # select shown attributes
    loopData = [
      {
        value:    'x-zammad-ticket-priority_id'
        name:     'Ticket Priority'
        relation: 'TicketPriority'
      },
      {
        value:    'x-zammad-ticket-state_id'
        name:     'Ticket State'
        relation: 'TicketState'
      },
      {
        value:    'x-zammad-ticket-customer'
        name:     'Ticket Customer'
      },
      {
        value:    'x-zammad-ticket-group_id'
        name:     'Ticket Group'
        relation: 'Group'
      },
      {
        value:    'x-zammad-ticket-owner'
        name:     'Ticket Owner'
      },
      {
        value:    ''
        name:     '-'
        disable:  true
      },
      {
        value:    'x-zammad-article-internal'
        name:     'Article Internal'
        options:  { true: 'Yes', false: 'No'}
      },
      {
        value:    'x-zammad-article-type_id'
        name:     'Article Type'
        relation: 'TicketArticleType'
      },
      {
        value:    'x-zammad-article-sender_id'
        name:     'Article Sender'
        relation: 'TicketArticleSender'
      },
      {
        value:    ''
        name:     '-'
        disable:  true
      },
      {
        value:    'x-zammad-ignore'
        name:     'Ignore Message'
        options:  { true: 'Yes', false: 'No'}
      },
    ]
    for listItem in loopData
      listItem.value = "#{ attribute.name }::#{listItem.value}"
    add = { name: '', display: '', tag: 'select', multiple: false, null: false, nulloption: true, options: loopData, translate: true, required: false }
    item.find('.addSelection').append( form_controller.formGenItem( add ) )

    item.find('.add').bind('click', (e) ->
      e.preventDefault()
      name        = $(@).closest('.controls').find('.addSelection').find('select').val()
      displayName = $(@).closest('.controls').find('.addSelection').find('select option:selected').html()
      return if !name
      addItem( name, displayName, $(@) )
    )

    # show default values
    loopDataValue = {}
    if attribute.value
      for key, value of attribute.value
        displayName = key
        for listItem in loopData
          if listItem.value is "#{ attribute.name }::#{key}"
            addItem( "#{ attribute.name }::#{key}", listItem.name, item.find('.add'), value )

    item