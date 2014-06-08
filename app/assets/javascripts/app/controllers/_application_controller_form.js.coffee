class App.ControllerForm extends App.Controller
  constructor: (params) ->
    for key, value of params
      @[key] = value
    @attribute_count = 0

    if !@form
      @form = @formGen()
    if @el
      @el.prepend( @form )

    # trigger change to rebuild shown/hidden item and update sub selections
    if typeof @form is 'object'
      @form.find('input').trigger('change')
      @form.find('textarea').trigger('change')
      @form.find('select').trigger('change')

  html: =>
    @form.html()

  formGen: ->
    App.Log.debug 'ControllerForm', 'formGen', @model.configure_attributes

    fieldset = $('<fieldset></fieldset>')

    for attribute_clean in @model.configure_attributes
      attribute = _.clone( attribute_clean )

      if !attribute.readonly && ( !@required || @required && attribute[@required] )

        @attribute_count = @attribute_count + 1

        # add item
        item = @formGenItem( attribute, @model.className, fieldset )
        item.appendTo(fieldset)

        # if password, add confirm password item
        if attribute.type is 'password'

          # set selected value passed on current params
          if @params
            if attribute.name of @params
              attribute.value = @params[attribute.name]

          # rename display and name to _confirm
          if !attribute.single
            attribute.display = attribute.display + ' (confirm)'
            attribute.name = attribute.name + '_confirm';
            item = @formGenItem( attribute, @model.className, fieldset )
            item.appendTo(fieldset)

    if @fullForm
      if !@formClass
        @formClass = ''
      fieldset = $('<form class="' + @formClass + '"><button class="btn">' + App.i18n.translateContent('Submit') + '</button></form>').prepend( fieldset )

    # return form
    return fieldset

  ###

  # input text field with max. 100 size
  attribute_config = {
    name:     'subject'
    display:  'Subject'
    tag:      'input'
    type:     'text'
    limit:    100
    null:     false
    default:  defaults['subject']
    class:    'span7'
  }

  # colection as relation with auto completion
  attribute_config = {
    name:           'customer_id'
    display:        'Customer'
    tag:            'autocompletion'
    # auto completion params, endpoints, ui,...
    type:           'text'
    limit:          100
    null:           false
    relation:       'User'
    autocapitalize: false
    help:           'Select the customer of the Ticket or create one.'
    link:           '<a href="" class="customer_new">&raquo;</a>'
    callback:       @userInfo
    class:          'span7'
  }

  # colection as relation
  attribute_config = {
    name:       'priority_id'
    display:    'Priority'
    tag:        'select'
    multiple:   false
    null:       false
    relation:   'TicketPriority'
    default:    defaults['priority_id']
    translate:  true
    class:      'medium'
  }


  # colection as options
  attribute_config = {
    name:       'priority_id'
    display:    'Priority'
    tag:        'select'
    multiple:   false
    null:       false
    options: [
      {
        value:    5
        name:     'very hight'
        selected: false
        disable:  false
      },
      {
        value:    3
        name:     'normal'
        selected: true
        disable:  false
      },
    ]
    default:    3
    translate:  true
    class:      'medium'
  }


  ###

  formGenItem: (attribute_config, classname, form ) ->
    attribute = _.clone( attribute_config )

    # create item id
    attribute.id = classname + '_' + attribute.name

    # set autofocus
    if @autofocus && @attribute_count is 1
      attribute.autofocus = 'autofocus'

    # set required option
    if !attribute.null
      attribute.required = 'required'
    else
      attribute.required = ''

    # set multible option
    if attribute.multiple
      attribute.multiple = 'multiple'
    else
      attribute.multiple = ''

    # set autocapitalize option
    if attribute.autocapitalize is undefined || attribute.autocapitalize
      attribute.autocapitalize = ''
    else
      attribute.autocapitalize = 'autocapitalize="off"'

    # set autocomplete option
    if attribute.autocomplete is undefined
      attribute.autocomplete = ''
    else
      attribute.autocomplete = 'autocomplete="' + attribute.autocomplete + '"'

    # set default values
    if attribute.value is undefined && 'default' of attribute
      attribute.value = attribute.default

    # set params value
    if @params

      # check if we have a references
      parts = attribute.name.split '::'
      if parts[0] && parts[1]
        if @params[ parts[0] ] && @params[ parts[0] ][ parts[1] ]
          attribute.value = @params[ parts[0] ][ parts[1] ]

      # set params value to default
      if attribute.name of @params
        attribute.value = @params[attribute.name]

      if attribute.tag is 'autocompletion'
        if @params[ attribute.name + '_autocompletion_value_shown' ]
          attribute.valueShown = @params[ attribute.name + '_autocompletion_value_shown' ]

    App.Log.debug 'ControllerForm', 'formGenItem-before', attribute

    # build options list based on config
    @_getConfigOptionList( attribute )

    # build options list based on relation
    @_getRelationOptionList( attribute )

    # add null selection if needed
    @_addNullOption( attribute )

    # sort attribute.options
    @_sortOptions( attribute )

    # finde selected/checked item of list
    @_selectedOptions( attribute )

    # disable item of list
    @_disabledOptions( attribute )

    # filter attributes
    @_filterOption( attribute )

    if attribute.tag is 'boolean'

      # build options list
      if _.isEmpty(attribute.options)
        attribute.options = [
          { name: 'active', value: true }
          { name: 'inactive', value: false }
        ]

      # update boolean types
      for record in attribute.options
        record.value = '{boolean}::' + record.value

      # finde selected item of list
      for record in attribute.options
        if record.value is '{boolean}::' + attribute.value
          record.selected = 'selected'

      # return item
      item = $( App.view('generic/select')( attribute: attribute ) )

    # select
    else if attribute.tag is 'select'
      item = $( App.view('generic/select')( attribute: attribute ) )

    # timezone
    else if attribute.tag is 'timezone'
      attribute.options = []
      timezones = App.Config.get('timezones')

      # build list based on config
      for timezone_value, timezone_diff of timezones
        if timezone_diff > 0
          timezone_diff = '+' + timezone_diff
        item =
          name:  "#{timezone_value} (GMT#{timezone_diff})"
          value: timezone_value
        attribute.options.push item

      # finde selected item of list
      for record in attribute.options
        if record.value is attribute.value
          record.selected = 'selected'

      item = $( App.view('generic/select')( attribute: attribute ) )

    # postmaster_match
    else if attribute.tag is 'postmaster_match'
      addItem = (key, displayName, el, defaultValue = '') =>
        add = { name: key, display: displayName, tag: 'input', null: false, default: defaultValue }
        itemInput = $( @formGenItem( add ).append('<a href=\"#\" class=\"glyphicon glyphicon-minus remove\"></a>' ) )

        # remove on click
        itemInput.find('.remove').bind('click', (e) ->
          e.preventDefault()
          key = $(e.target).parent().find('select, input').attr('name')
          return if !key
          $(e.target).parent().parent().parent().find('.addSelection select option[value="' + key + '"]').show()
          $(e.target).parent().parent().parent().find('.addSelection select option[value="' + key + '"]').prop('disabled', false)
          $(e.target).parent().parent().parent().find('.list [name="' + key + '"]').parent().parent().remove()
        )

        # add new item
        el.parent().parent().parent().find('.list').append(itemInput)
        el.parent().parent().parent().find('.addSelection select').val('')
        el.parent().parent().parent().find('.addSelection select option[value="' + key + '"]').prop('disabled', true)
        el.parent().parent().parent().find('.addSelection select option[value="' + key + '"]').hide()

      # scaffold of match elements
      item = $('
        <div class="postmaster_match">
          <hr>
          <div class="list"></div>
          <hr>
          <div>
            <div class="addSelection"></div>
            <div class="add"><a href="#" class="glyphicon glyphicon-plus"></a></div>
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
      item.find('.addSelection').append( @formGenItem( add ) )

      # bind add click
      item.find('.add').bind('click', (e) ->
        e.preventDefault()
        name        = $(@).parent().parent().find('.addSelection').find('select').val()
        displayName = $(@).parent().parent().find('.addSelection').find('select option:selected').html()
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
              addItem( "#{ attribute.name }::#{key}", listItem.name, item.find('.add a'), value )

    # postmaster_set
    else if attribute.tag is 'postmaster_set'
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
        itemInput = $( @formGenItem( add ).append('<a href=\"#\" class=\"glyphicon glyphicon-minus remove\"></a>' ) )

        # remove on click
        itemInput.find('.remove').bind('click', (e) ->
          e.preventDefault()
          key = $(e.target).parent().find('select, input').attr('name')
          return if !key
          $(e.target).parent().parent().parent().find('.addSelection select option[value="' + key + '"]').show()
          $(e.target).parent().parent().parent().find('.addSelection select option[value="' + key + '"]').prop('disabled', false)
          $(e.target).parent().parent().parent().find('.list [name="' + key + '"]').parent().parent().remove()
        )

        # add new item
        el.parent().parent().parent().find('.list').append(itemInput)
        el.parent().parent().parent().find('.addSelection select').val('')
        el.parent().parent().parent().find('.addSelection select option[value="' + key + '"]').prop('disabled', true)
        el.parent().parent().parent().find('.addSelection select option[value="' + key + '"]').hide()

      # scaffold of perform elements
      item = $('
        <div class="perform_set">
          <hr>
          <div class="list"></div>
          <hr>
          <div>
            <div class="addSelection"></div>
            <div class="add"><a href="#" class="glyphicon glyphicon-plus"></a></div>
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
      item.find('.addSelection').append( @formGenItem( add ) )

      item.find('.add').bind('click', (e) ->
        e.preventDefault()
        name        = $(@).parent().parent().find('.addSelection').find('select').val()
        displayName = $(@).parent().parent().find('.addSelection').find('select option:selected').html()
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
              addItem( "#{ attribute.name }::#{key}", listItem.name, item.find('.add a'), value )

    # select
    else if attribute.tag is 'input_select'
      item = $('<div class="input_select"></div>')

      # select shown attributes
      loopData = {}
      if @params && @params[ attribute.name ]
        loopData = @params[ attribute.name ]
      loopData[''] = ''

      # show each attribote
      counter = 0
      for key of loopData
        counter =+ 1

        # clone to keep it untouched for next loop
        select = _.clone( attribute )
        input  = _.clone( attribute )

        # set field ids - not needed in this case
        select.id = ''
        input.id  = ''

        # rename to be able to identify this option later
        select.name = '{input_select}::' + select.name
        input.name  = '{input_select}::' + input.name

        # set sub attributes
        for keysub of attribute.select
          select[keysub] = attribute.select[keysub]
        for keysub of attribute.input
          input[keysub] = attribute.input[keysub]

        # set hide for + options
        itemClass = ''
        if key is ''
          itemClass = 'hide'
          select['nulloption'] = true

        # set selected value
        select.value = key
        input.value  = loopData[ key ]

        # build options list based on config
        @_getConfigOptionList( select )

        # build options list based on relation
        @_getRelationOptionList( select )

        # add null selection if needed
        @_addNullOption( select )

        # sort attribute.options
        @_sortOptions( select )

        # finde selected/checked item of list
        @_selectedOptions( select )

        pearItem = $("<div class=" + itemClass + "></div>")
        pearItem.append $( App.view('generic/select')( attribute: select ) )
        pearItem.append $( App.view('generic/input')( attribute: input ) )
        itemRemote = $('<a href="#" class="input_select_remove icon-minus"></a>')
        itemRemote.bind('click', (e) ->
          e.preventDefault()
          $(@).parent().remove()
        )
        pearItem.append( itemRemote )
        item.append( pearItem )

        if key is ''
          itemAdd = $('<div class="add"><a href="#" class="icon-plus"></a></div>')
          itemAdd.bind('click', (e) ->
            e.preventDefault()

            # copy
            newElement = $(@).prev().clone()
            newElement.removeClass('hide')

            # bind on remove
            newElement.find('.input_select_remove').bind('click', (e) ->
              e.preventDefault()
              $(@).parent().remove()
            )

            # prepend
            $(@).parent().find('.add').before( newElement )
          )
          item.append( itemAdd )

    # checkbox
    else if attribute.tag is 'checkbox'
      item = $( App.view('generic/checkbox')( attribute: attribute ) )

    # radio
    else if attribute.tag is 'radio'
      item = $( App.view('generic/radio')( attribute: attribute ) )

    # textarea
    else if attribute.tag is 'textarea'
      fileUploaderId = 'file-uploader-' + new Date().getTime() + '-' + Math.floor( Math.random() * 99999 )
      item = $( App.view('generic/textarea')( attribute: attribute ) + '<div class="file-uploader ' + attribute.class + '" id="' + fileUploaderId + '"></div>' )

      a = =>
        $( item[0] ).expanding()
        $( item[0] ).on('focus', ->
          $( item[0] ).expanding()
        )
      App.Delay.set( a, 80 )

      if attribute.upload

        # add file uploader
        u = =>
          @el.find('#' + fileUploaderId ).fineUploader(
            request:
              endpoint: App.Config.get('api_path') + '/ticket_attachment_new'
              params:
                form_id: @form_id
            text:
              uploadButton: '<i class="glyphicon glyphicon-paperclip"></i>'
            template: '<div class="qq-uploader">' +
                        '<pre class="btn qq-upload-icon qq-upload-drop-area"><span>{dragZoneText}</span></pre>' +
                        '<div class="btn btn-default qq-upload-icon2 qq-upload-button pull-right" style="">{uploadButtonText}</div>' +
                        '<ul class="qq-upload-list span5" style="margin-top: 10px;"></ul>' +
                      '</div>',
            classes:
              success: ''
              fail:    ''
            debug: false
          )
        App.Delay.set( u, 100, undefined, 'form_upload' )

    # article
    else if attribute.tag is 'article'
      item = $( App.view('generic/article')( attribute: attribute ) )


    # tag
    else if attribute.tag is 'tag'
      item = $( App.view('generic/input')( attribute: attribute ) )
      a = =>
        $('#' + attribute.id ).tokenfield()
        $('#' + attribute.id ).parent().css('height', 'auto')
      App.Delay.set( a, 120, undefined, 'tags' )

    # autocompletion
    else if attribute.tag is 'autocompletion'
      item = $( App.view('generic/autocompletion')( attribute: attribute ) )

      a = =>
        local_attribute = '#' + attribute.id
        local_attribute_full = '#' + attribute.id + '_autocompletion'
        @callback = attribute.callback

        # call calback on init
        if @callback && attribute.value && @params
          @callback( @params )

        b = (event, item) =>
          # set html form attribute
          $(local_attribute).val(item.id)
          $(local_attribute + '_autocompletion_value_shown').val(item.value)

          # call calback
          if @callback
            params = App.ControllerForm.params(form)
            @callback( params )
        ###
        $(@local_attribute_full).tagsInput(
          autocomplete_url: '/users/search',
          height: '30px',
          width: '530px',
          auto: {
            source: '/users/search',
            minLength: 2,
            select: ( event, ui ) ->
              #@log 'notice', 'selected', event, ui
              b(event, ui.item)
          }
        )
        ###
        $(local_attribute_full).autocomplete(
          source: attribute.source,
          minLength: attribute.minLengt || 3,
          select: ( event, ui ) =>
            b(event, ui.item)
        )
      App.Delay.set( a, 280, undefined, 'form_autocompletion' )

    # working_hour
    else if attribute.tag is 'working_hour'
      if !attribute.value
        attribute.value = {}
      item = $( App.view('generic/working_hour')( attribute: attribute ) )

    # working_hour
    else if attribute.tag is 'time_before_last'
      if !attribute.value
        attribute.value = {}
      item = $( App.view('generic/time_before_last')( attribute: attribute ) )
      item.find( "[name=\"#{attribute.name}::direction\"]").find("option[value=\"#{attribute.value.direction}\"]").attr( 'selected', 'selected' )
      item.find( "[name=\"#{attribute.name}::count\"]").find("option[value=\"#{attribute.value.count}\"]").attr( 'selected', 'selected' )
      item.find( "[name=\"#{attribute.name}::area\"]").find("option[value=\"#{attribute.value.area}\"]").attr( 'selected', 'selected' )

    # ticket attribute selection
    else if attribute.tag is 'ticket_attribute_selection'

      # list of possible attributes
      item = $(
        App.view('generic/ticket_attribute_selection')(
          attribute: attribute
        )
      )

      addShownAttribute = ( key, value ) =>
        console.log( 'addShownAttribute', key, value )
        parts = key.split(/::/)
        key   = parts[0]
        type  = parts[1]
        if key is 'tickets.number'
          attribute_config = {
            name:       attribute.name + '::tickets.number'
            display:    'Number'
            tag:        'input'
            type:       'text'
            null:       false
            value:      value
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.title'
          attribute_config = {
            name:       attribute.name + '::tickets.title'
            display:    'Title'
            tag:        'input'
            type:       'text'
            null:       false
            value:      value
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.group_id'
          attribute_config = {
            name:       attribute.name + '::tickets.group_id'
            display:    'Group'
            tag:        'select'
            multiple:   true
            null:       false
            nulloption: false
            relation:   'Group'
            value:      value
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.owner_id' || key is 'tickets.customer_id'
          display = 'Owner'
          name    = 'owner_id'
          if key is 'customer_id'
            display = 'Customer'
            name    = 'customer_id'
          attribute_config = {
            name:       attribute.name + '::tickets.' + name
            display:    display
            tag:        'select'
            multiple:   true
            null:       false
            nulloption: false
            relation:   'User'
            value:      value || null
            class:      'medium'
            remove:     true
            filter:     ( all, type ) ->
              return all if type isnt 'collection'
              all = _.filter( all, (item) ->
                return if item.id is 1
                return item
              )
              all.unshift( {
                id: ''
                name:  '--'
              } )
              all.unshift( {
                id: 1
                name:  '*** not set ***'
              } )
              all.unshift( {
                id: 'current_user.id'
                name:  '*** current user ***'
              } )
              all
          }
        else if key is 'tickets.organization_id'
          attribute_config = {
            name:       attribute.name + '::tickets.organization_id'
            display:    'Organization'
            tag:        'select'
            multiple:   true
            null:       false
            nulloption: false
            relation:   'Organization'
            value:      value || null
            class:      'medium'
            remove:     true
            filter:     ( all, type ) ->
              return all if type isnt 'collection'
              all.unshift( {
                id: ''
                name:  '--'
              } )
              all.unshift( {
                id: 'current_user.organization_id'
                name:  '*** organization of current user ***'
              } )
              all
          }
        else if key is 'tickets.state_id'
          attribute_config = {
            name:       attribute.name + '::tickets.state_id'
            display:    'State'
            tag:        'select'
            multiple:   true
            null:       false
            nulloption: false
            relation:   'TicketState'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.priority_id'
          attribute_config = {
            name:       attribute.name + '::tickets.priority_id'
            display:    'Priority'
            tag:        'select'
            multiple:   true
            null:       false
            nulloption: false
            relation:   'TicketPriority'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.created_at' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.created_at'
            display:    'Created (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.created_at' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.created_at'
            display:    'Created (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.close_time' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.close_time'
            display:    'Closed (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.close_time' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.close_time'
            display:    'Closed (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.updated_at' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.updated_at'
            display:    'Updated (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.updated_at' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.updated_at'
            display:    'Updated (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.escalation_time' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.escalation_time'
            display:    'Escalation (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else if key is 'tickets.escalation_time' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.escalation_time'
            display:    'Escatlation (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            class:      'medium'
            remove:     true
          }
        else
          attribute_config = {
            name:       attribute.name + '::' + key
            display:    'FIXME!'
            tag:        'input'
            type:       'text'
            value:      value
            class:      'medium'
            remove:     true
          }
        itemSub = @formGenItem( attribute_config )
        itemSub.find('.icon-minus').bind('click', (e) ->
          e.preventDefault()
          $(@).parent().parent().parent().remove()
        )
#        itemSub.append('<a href=\"#\" class=\"icon-minus\"></a>')
        item.find('.ticket_attribute_item').append( itemSub )


      # list of shown attributes
      show = []
      if attribute.value
        for key, value of attribute.value
          addShownAttribute( key, value )

      # list of existing attributes
      attribute_config = {
        name:       'ticket_attribute_list'
        display:    'Add Attribute'
        tag:        'select'
        multiple:   false
        null:       false
#        nulloption: true
        options: [
          {
            value:    ''
            name:     '-- Ticket --'
            selected: false
            disable:  true
          },
#          {
#            value:    'tickets.number'
#            name:     'Number'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'tickets.title'
#            name:     'Title'
#            selected: true
#            disable:  false
#          },
          {
            value:    'tickets.group_id'
            name:     'Group'
            selected: false
            disable:  false
          },
          {
            value:    'tickets.state_id'
            name:     'State'
            selected: false
            disable:  false
          },
          {
            value:    'tickets.priority_id'
            name:     'Priority'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.owner_id'
            name:     'Owner'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.customer_id'
            name:     'Customer'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.organization_id'
            name:     'Organization'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.created_at::<>'
            name:     'Created (before/last)'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.created_at::><'
            name:     'Created (between)'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.close_time::<>'
            name:     'Closed (before/last)'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.close_time::><'
            name:     'Closed (between)'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.updated_at::<>'
            name:     'Updated (before/last)'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.updated_at::><'
            name:     'Updated (between)'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.escalation_time::<>'
            name:     'Escalation (before/last)'
            selected: true
            disable:  false
          },
          {
            value:    'tickets.escalation_time::><'
            name:     'Escalation (between)'
            selected: true
            disable:  false
          },

#          {
#            value:    'tag'
#            name:     'Tag'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'tickets.created_before'
#            name:     'Erstell vor'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'tickets.created_after'
#            name:     'Erstell nach'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'tickets.created_between'
#            name:     'Erstell zwischen'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'tickets.closed_before'
#            name:     'Geschlossen vor'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'tickets.closed_after'
#            name:     'Geschlossen nach'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'tickets.closed_between'
#            name:     'Geschlossen zwischen'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    '-a'
#            name:     '-- ' + App.i18n.translateInline('Article') + ' --'
#            selected: false
#            disable:  true
#          },
#          {
#            value:    'ticket_articles.from'
#            name:     'From'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'ticket_articles.to'
#            name:     'To'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'ticket_articles.cc'
#            name:     'Cc'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'ticket_articles.subject'
#            name:     'Subject'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'ticket_articles.body'
#            name:     'Text'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    '-c'
#            name:     '-- ' + App.i18n.translateInline('Customer') + ' --'
#            selected: false
#            disable:  true
#          },
#          {
#            value:    'customers.id'
#            name:     'Kunde'
#            selected: true
#            disable:  false
#          },
#          {
#            value:    'organization.id'
#            name:     'Organization'
#            selected: true
#            disable:  false
#          },
        ]
        default:    ''
        translate:  true
        class:      'medium'
        add:        true
      }
      list = @formGenItem( attribute_config )

      list.find('.icon-plus').bind('click', (e) ->
        e.preventDefault()

        value = $(e.target).parents().find('[name=ticket_attribute_list]').val()
        addShownAttribute( value, '' )
      )
      item.find('.ticket_attribute_list').prepend( list )

    # input
    else
      item = $( App.view('generic/input')( attribute: attribute ) )

    if attribute.onchange
      if typeof attribute.onchange is 'function'
        attribute.onchange(attribute)
      else
        for i of attribute.onchange
          a = i.split(/__/)
          if a[1]
            if a[0] is attribute.name
              @attribute = attribute
              @classname = classname
              @attributes_clean = attributes_clean
              @change = a
              b = =>
#                console.log 'aaa', @attribute
                attribute = @attribute
                change = @change
                classname = @classname
                attributes_clean = @attributes_clean
                ui = @
                $( '#' + @attribute.id ).bind('change', ->
                  ui.log 'change', @, attribute, change
                  ui.log change[0] + ' has changed - changing ' + change[1]

                  item = $( ui.formGenItem(attribute, classname, attributes_clean) )
                  ui.log item, classname
                )
              App.Delay.set( b, 100, undefined, 'form_change' )
#            if attribute.onchange[]

    ui = @
    item.bind('change', ->
      if ui.form_data
        params = App.ControllerForm.params(@)
        for i of ui.form_data
          a = i.split(/__/)
          if a[1] && a[0] is attribute.name
            newListAttribute  = i
            changedAttribute  = a[0]
            toChangeAttribute = a[1]

            # get new option list
            newListAttributes = ui['form_data'][newListAttribute][ params['group_id'] ]

            # find element to replace
            for item in ui.model.configure_attributes
              if item.name is toChangeAttribute
                item.display = false
                item['filter'][toChangeAttribute] = newListAttributes
                if params[changedAttribute]
                  item.default = params[toChangeAttribute]
                if !item.default
                  delete item['default']
                newElement = ui.formGenItem( item, classname, form )

            # replace new option list
            form.find('[name="' + toChangeAttribute + '"]').replaceWith( newElement )
    )

    # bind dependency
    if @dependency
      for action in @dependency

        # bind on element if name is matching
        if action.bind && action.bind.name is attribute.name
          ui = @
          do (action, attribute) ->
            item.bind('change', ->
              value = $(@).val()

              # lookup relation if needed
              if action.bind.relation
                data = App[action.bind.relation].find( value )
                value = data.name

              # check if value is used in condition
              if _.contains( action.bind.value, value )
                if action.change.action is 'hide'
                  ui._hide(action.change.name)
                else
                  ui._show(action.change.name)
            )

    if !attribute.display

      # hide/show item
      #if attribute.hide
      #  @._hide(attribute.name)

      return item
    else
      fullItem = $(
        App.view('generic/attribute')(
          attribute: attribute,
          item:      '',
        )
      )
      fullItem.find('.controls').prepend( item )

      # hide/show item
      if attribute.hide
        @._hide(attribute.name, fullItem)

      return fullItem

  _show: (name, el = @el) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').parents('.form-group').removeClass('hide')
      el.find('[name="' + key + '"]').removeClass('is-hidden')

  _hide: (name, el = @el) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').parents('.form-group').addClass('hide')
      el.find('[name="' + key + '"]').addClass('is-hidden')

  # sort attribute.options
  _sortOptions: (attribute) ->

    return if !attribute.options
    return if _.isArray( attribute.options )
    options_by_name = []
    for i in attribute.options
      options_by_name.push i['name'].toString().toLowerCase()
    options_by_name = options_by_name.sort()

    options_new = []
    options_new_used = {}
    for i in options_by_name
      for ii, vv in attribute.options
        if !options_new_used[ ii['value'] ] && i.toString().toLowerCase() is ii['name'].toString().toLowerCase()
          options_new_used[ ii['value'] ] = 1
          options_new.push ii
    attribute.options = options_new

  _addNullOption: (attribute) ->
    return if !attribute.options
    return if !attribute.nulloption
    if _.isArray( attribute.options )
      attribute.options.unshift( { name: '-', value: '' } )
    else
      attribute.options[''] = '-'

  _getConfigOptionList: (attribute) ->
    return if !attribute.options
    selection = attribute.options
    attribute.options = []
    if _.isArray( selection )
      for row in selection
        if attribute.translate
          row.name = App.i18n.translateInline( row.name )
        attribute.options.push row
    else
      order = _.sortBy(
        _.keys(selection), (item) ->
          selection[item].toString().toLowerCase()
      )
      for key in order
        name_new = selection[key]
        if attribute.translate
          name_new = App.i18n.translateInline( name_new )
        attribute.options.push {
          name:  name_new
          value: key
        }

  _getRelationOptionList: (attribute) ->

    # build options list based on relation
    return if !attribute.relation
    return if !App[attribute.relation]

    attribute.options = []

    list = []
    if attribute.filter
      App.Log.debug 'ControllerForm', '_getRelationOptionList:filter', attribute.filter

      # function based filter
      if typeof attribute.filter is 'function'
        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-function'

        all = App[ attribute.relation ].search( sortBy: attribute.sortBy )

        list = attribute.filter( all, 'collection' )

      # data based filter
      else if attribute.filter[ attribute.name ]
        filter = attribute.filter[ attribute.name ]

        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-data', filter

        # check all records
        for record in App[ attribute.relation ].search( sortBy: attribute.sortBy )

          # check all filter attributes
          for key in filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key
              list.push record

      # no data filter matched
      else
        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-data no filter matched'
        list = App[ attribute.relation ].search( sortBy: attribute.sortBy )
    else
      App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-no filter defined'
      list = App[ attribute.relation ].search( sortBy: attribute.sortBy )

    App.Log.debug 'ControllerForm', '_getRelationOptionList', attribute, list

    # build options list
    @_buildOptionList( list, attribute )

  # build options list
  _buildOptionList: (list, attribute) ->

    for item in list

      # if active or if active doesn't exist
      if item.active || !( 'active' of item )
        name_new = '?'
        if item.displayName
          name_new = item.displayName()
        else if item.name
          name_new = item.name
        if attribute.translate
          name_new = App.i18n.translateInline(name_new)
        attribute.options.push {
          name:  name_new,
          value: item.id,
          note:  item.note,
        }

  # execute filter
  _filterOption: (attribute) ->
    return if !attribute.filter
    return if !attribute.options

    return if typeof attribute.filter isnt 'function'
    App.Log.debug 'ControllerForm', '_filterOption:filter-function'

    attribute.options = attribute.filter( attribute.options, attribute )

  # set selected attributes
  _selectedOptions: (attribute) ->

    return if !attribute.options

    check = (value, record) ->
      if typeof value is 'string' || typeof value is 'number' || typeof value is 'boolean'

        # if name or value is matching
        if record.value.toString() is value.toString() || record.name.toString() is value.toString()
          record.selected = 'selected'
          record.checked = 'checked'
#          if record.name.toString() is attribute.value.toString()
#            record.selected = 'selected'
#            record.checked = 'checked'

      else if ( value && record.value && _.include( value, record.value ) ) || ( value && record.name && _.include( value, record.name ) )
        record.selected = 'selected'
        record.checked = 'checked'

    for record in attribute.options

      if _.isArray( attribute.value )
        for value in attribute.value
          check( value, record )

      if typeof attribute.value is 'string' || typeof attribute.value is 'number' || typeof attribute.value is 'boolean'
        check( attribute.value, record )

  # set disabled attributes
  _disabledOptions: (attribute) ->

    return if !attribute.options
    return if !_.isArray( attribute.options )

    for record in attribute.options
      if record.disable is true
        record.disabled = 'disabled'
      else
        record.disabled = ''

  validate: (params) ->
    App.Model.validate(
      model: @model,
      params: params,
    )

  # get all params of the form
  @params: (form) ->
    param = {}

    # create jquery object if not already exists
    if form instanceof jQuery
      # do nothing
    else
      form = $(form)

    # find form if current is <form>
    if form.is('form')
      form = form

    # find form based on sub elements
    else if form.find('form')[0]
      form = $( form.find('form')[0] )

    # find form based on parents next <form>
    else if form.parents('form')[0]
      form = $( form.parents('form')[0] )

    else
      App.Log.error 'ControllerForm', 'no form found!', form

    # get form elements
    array = form.serializeArray()

    # 1:1 and boolean params
    for key in array

      # check if item is-hidden and should not be used
      if form.find('[name="' + key.name + '"]').hasClass('is-hidden')
        continue

      # collect all other params
      if param[key.name]
        if typeof param[key.name] is 'string'
          param[key.name] = [ param[key.name], key.value]
        else
          param[key.name].push key.value
      else

        # check boolean
        attributeType = key.value.split '::'
        if attributeType[0] is '{boolean}'
          if attributeType[1] is 'true'
            key.value = true
          else
            key.value = false
#        else if attributeType[0] is '{boolean}'

        param[key.name] = key.value

    # check :: fields
    inputSelectObject = {}
    for key of param
      parts = key.split '::'
      if parts[0] && parts[1] && !parts[2]
        if !inputSelectObject[ parts[0] ]
          inputSelectObject[ parts[0] ] = {}
        inputSelectObject[ parts[0] ][ parts[1] ] = param[ key ]
        delete param[ key ]
      if parts[0] && parts[1] && parts[2]
        if !inputSelectObject[ parts[0] ]
          inputSelectObject[ parts[0] ] = {}
        if !inputSelectObject[ parts[0] ][ parts[1] ]
          inputSelectObject[ parts[0] ][ parts[1] ] = {}
        inputSelectObject[ parts[0] ][ parts[1] ][ parts[2] ] = param[ key ]
        delete param[ key ]

    # check {input_select}
    for key of param
      attributeType = key.split '::'
      name = attributeType[1]
#      console.log 'split', key, attributeType, param[ name ]
      if attributeType[0] is '{input_select}' && !param[ name ]

        # array need to be converted
        inputSelectData = param[ key ]
        inputSelectObject[ name ] = {}
        for x in [0..inputSelectData.length] by 2
#          console.log 'for by 111', x, inputSelectData, inputSelectData[x], inputSelectData[ x + 1 ]
          if inputSelectData[ x ]
            inputSelectObject[ name ][ inputSelectData[x] ] = inputSelectData[ x + 1 ]

        # remove {input_select} items
        delete param[ key ]

    # set new {input_select} items
    for key of inputSelectObject
      param[ key ] = inputSelectObject[ key ]

    #App.Log.notice 'ControllerForm', 'formParam', form, param
    return param

  @formId: ->
    formId = new Date().getTime() + Math.floor( Math.random() * 99999 )
    formId.toString().substr formId.toString().length-9, 9

  @disable: (form) ->
    App.Log.notice 'ControllerForm', 'disable...', $(form.target).parent()
    $(form.target).parent().find('button').attr('disabled', true)
    $(form.target).parent().find('[type="submit"]').attr('disabled', true)
    $(form.target).parent().find('[type="reset"]').attr('disabled', true)


  @enable: (form) ->
    App.Log.notice 'ControllerForm', 'enable...', $(form.target).parent()
    $(form.target).parent().find('button').attr('disabled', false)
    $(form.target).parent().find('[type="submit"]').attr('disabled', false)
    $(form.target).parent().find('[type="reset"]').attr('disabled', false)

  @validate: (data) ->

    # remove all errors
    $(data.form).parents().find('.has-error').removeClass('has-error')
    $(data.form).parents().find('.help-inline').html('')

    # show new errors
    for key, msg of data.errors
      $(data.form).parents().find('[name*="' + key + '"]').parents('div .form-group').addClass('has-error')
      $(data.form).parents().find('[name*="' + key + '"]').parent().find('.help-inline').html(msg)

    # set autofocus
    $(data.form).parents().find('.has-error').find('input, textarea').first().focus()

#    # enable form again
#    if $(data.form).parents().find('.has-error').html()
#      @formEnable(data.form)

