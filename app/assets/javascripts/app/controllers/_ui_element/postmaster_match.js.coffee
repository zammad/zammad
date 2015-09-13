class App.UiElement.postmaster_match
  @render: (attribute, params, form_controller) ->
    addItem = (key, displayName, el, defaultValue = '') =>
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
      control = el.closest('.postmaster_match')
      control.find('.list').append(itemInput)
      control.find('.addSelection select').val('')
      control.find('.addSelection select option[value="' + key + '"]').prop('disabled', true)
      control.find('.addSelection select option[value="' + key + '"]').hide()

    # scaffold of match elements
    item = $('
      <div class="postmaster_match">
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
        value:    'subject'
        name:     'Subject'
      },
      {
        value:    'body'
        name:     'Body'
      },
      {
        value:    ''
        name:     '-'
        disable:  true
      },
      {
        value:    'x-any-recipient'
        name:     'Any Recipient'
      },
      {
        value:    ''
        name:     '-'
        disable:  true
      },
      {
        value:    ''
        name:     '- ' + App.i18n.translateInline('expert settings') + ' -'
        disable:  true
      },
      {
        value:    ''
        name:     '-'
        disable:  true
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
        value:    'list-archive'
        name:     'List-Archive'
      },
      {
        value:    'mailing-list'
        name:     'Mailing-List'
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
    for listItem in loopData
      listItem.value = "#{ attribute.name }::#{listItem.value}"
    add = { name: '', display: '', tag: 'select', multiple: false, null: false, nulloption: true, options: loopData, translate: true, required: false }
    item.find('.addSelection').append( form_controller.formGenItem( add ) )

    # bind add click
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
