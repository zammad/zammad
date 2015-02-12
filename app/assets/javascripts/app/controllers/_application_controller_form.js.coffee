class App.ControllerForm extends App.Controller
  constructor: (params) ->
    for key, value of params
      @[key] = value

    if !@handlers
      @handlers = []
    @handlers.push @_showHideToggle
    @handlers.push @_requiredMandantoryToggle

    # set empty class attributes if needed
    if !@form
      @form = @formGen()
    if !@model
      @model = {}
    if !@attributes
      @attributes = []

    # if element is given, prepend form to it
    if @el
      @el.prepend( @form )

    # trigger change to rebuild shown/hidden item and update sub selections
    if typeof @form is 'object'
      @form.find('input').trigger('change')
      @form.find('textarea').trigger('change')
      @form.find('select').trigger('change')

    @finishForm = true
    @form

  html: =>
    @form.html()

  formGen: ->
    App.Log.debug 'ControllerForm', 'formGen', @model.configure_attributes

    # check if own fieldset should be generated
    if @noFieldset
      fieldset = @el
    else
      fieldset = $('<fieldset></fieldset>')

    # collect form attributes
    @attributes = []
    if @model.attributesGet
      attributesClean = @model.attributesGet(@screen)
    else
      attributesClean = App.Model.attributesGet(@screen, @model.configure_attributes )

    for attributeName, attribute of attributesClean

      # ignore read only attributes
      if !attribute.readonly

        # check generic filter
        if @filter && !attribute.filter
          if @filter[ attributeName ]
            attribute.filter = @filter[ attributeName ]

        @attributes.push attribute

    attribute_count = 0
    className       = @model.className + '_' + Math.floor( Math.random() * 999999 ).toString()

    for attribute in @attributes
      attribute_count = attribute_count + 1

      # add item
      item = @formGenItem( attribute, className, fieldset, attribute_count )
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
          item = @formGenItem( attribute, className, fieldset, attribute_count )
          item.appendTo(fieldset)

    if @fullForm
      if !@formClass
        @formClass = ''
      fieldset = $('<form class="' + @formClass + '"><button class="btn">' + App.i18n.translateContent('Submit') + '</button></form>').prepend( fieldset )

    # bind form events
    if @events
      for eventSelector, callback of @events
        do (eventSelector, callback) =>
          evs = eventSelector.split(' ')
          fieldset.find( evs[1] ).bind( evs[0], (e) => callback(e) )

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
    help:           'Select the customer of the ticket or create one.'
    helpLink:       '<a href="" class="customer_new">&raquo;</a>'
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

  formGenItem: (attribute_config, classname, form, attribute_count ) ->
    attribute = clone( attribute_config, true )

    # create item id
    attribute.id = classname + '_' + attribute.name

    # set label class name
    attribute.label_class = @model.labelClass

    # set autofocus
    if @autofocus && attribute_count is 1
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
          { name: 'yes', value: true }
          { name: 'no', value: false }
        ]

      # set data type
      if attribute.name
        attribute.name = '{boolean}' + attribute.name

      # finde selected item of list
      for record in attribute.options
        if record.value is attribute.value
          record.selected = 'selected'

      # return item
      item = $( App.view('generic/select')( attribute: attribute ) )

    else if attribute.tag is 'active'

      # active attribute is always required
      attribute.null = false

      # build options list
      attribute.options = [
        { name: 'active', value: true }
        { name: 'inactive', value: false }
      ]

      # set data type
      if attribute.name
        attribute.name = '{boolean}' + attribute.name

      # finde selected item of list
      for record in attribute.options
        if record.value is attribute.value
          record.selected = 'selected'

      # return item
      item = $( App.view('generic/select')( attribute: attribute ) )

    # select
    else if attribute.tag is 'select'
      item = $( App.view('generic/select')( attribute: attribute ) )

    # date
    else if attribute.tag is 'date'

      # set data type
      if attribute.name
        attribute.nameRaw = attribute.name
        attribute.name    = '{date}' + attribute.name
      if attribute.value
        if typeof( attribute.value ) is 'string'
          unixtime = new Date( Date.parse( "#{attribute.value}T00:00:00Z" ) )
        else
          unixtime = new Date( attribute.value )
        year     = unixtime.getUTCFullYear()
        month    = unixtime.getUTCMonth() + 1
        day      = unixtime.getUTCDate()
        hour     = unixtime.getUTCHours()
        minute   = unixtime.getUTCMinutes()
      item = $( App.view('generic/date')(
        attribute: attribute
        year:      year
        month:     month
        day:       day
      ) )

      setNewTime = (diff, el, reset) ->
        name = $(el).closest('.form-group').find('[data-name]').attr('data-name')

        # remove old validation
        item.find('.has-error').removeClass('has-error')
        item.closest('.form-group').find('.help-inline').html('')

        day    = item.closest('.form-group').find("[name=\"{date}#{name}___day\"]").val()
        month  = item.closest('.form-group').find("[name=\"{date}#{name}___month\"]").val()
        year   = item.closest('.form-group').find("[name=\"{date}#{name}___year\"]").val()
        format = (number) ->
          if parseInt(number) < 10
            number = "0#{number}"
          number
        if !reset && (year isnt '' && month isnt '' && day isnt '')
          time = new Date( Date.parse( "#{year}-#{format(month)}-#{format(day)}T00:00:00Z" ) )
          time.setMinutes( time.getMinutes() + diff + time.getTimezoneOffset() )
        else
          time = new Date()
          time.setMinutes( time.getMinutes() + diff )
        item.closest('.form-group').find("[name=\"{date}#{name}___day\"]").val( time.getDate() )
        item.closest('.form-group').find("[name=\"{date}#{name}___month\"]").val( time.getMonth()+1 )
        item.closest('.form-group').find("[name=\"{date}#{name}___year\"]").val( time.getFullYear() )

      item.find('.js-today').bind('click', (e) ->
        e.preventDefault()
        setNewTime(0, @, true)
      )
      item.find('.js-plus-day').bind('click', (e) ->
        e.preventDefault()
        setNewTime(60 * 24, @)
      )
      item.find('.js-minus-day').bind('click', (e) ->
        e.preventDefault()
        setNewTime(-60 * 24, @)
      )
      item.find('.js-plus-week').bind('click', (e) ->
        e.preventDefault()
        setNewTime(60 * 24 * 7, @)
      )
      item.find('.js-minus-week').bind('click', (e) ->
        e.preventDefault()
        setNewTime(-60 * 24 * 7, @)
      )

      item.find('input').bind('keyup blur focus change', (e) ->

        # do validation
        name = $(@).attr('name')
        if name
          fieldPrefix = name.split('___')[0]

        # remove old validation
        item.find('.has-error').removeClass('has-error')
        item.closest('.form-group').find('.help-inline').html('')

        day    = item.closest('.form-group').find("[name=\"#{fieldPrefix}___day\"]").val()
        month  = item.closest('.form-group').find("[name=\"#{fieldPrefix}___month\"]").val()
        year   = item.closest('.form-group').find("[name=\"#{fieldPrefix}___year\"]").val()

        # validate exists
        errors = {}
        if !day
          errors.day = 'missing'
        if !month
          errors.month = 'missing'
        if !year
          errors.year = 'missing'

        # ranges
        if day
          daysInMonth = 31
          if month && year
            daysInMonth = new Date(year, month, 0).getDate();

          if parseInt(day).toString() is 'NaN'
            errors.day = 'invalid'
          else if parseInt(day) > daysInMonth || parseInt(day) < 1
            errors.day = 'invalid'

        if month
          if parseInt(month).toString() is 'NaN'
            errors.month = 'invalid'
          else if parseInt(month) > 12 || parseInt(month) < 1
            errors.month = 'invalid'

        if year
          if parseInt(year).toString() is 'NaN'
            errors.year = 'invalid'
          else if parseInt(year) > 2100 || parseInt(year) < 2001
            errors.year = 'invalid'

        if !_.isEmpty(errors)

          # if field is required, if not do not show error
          if year is '' && day is '' && month
            if attribute.null
              e.preventDefault()
              e.stopPropagation()
              return
            else
              item.closest('.form-group').find('.help-inline').text( 'is required' )

          # show invalid options
          for key, value of errors
            item.closest('.form-group').addClass('has-error')
            item.closest('.form-group').find("[name=\"#{fieldPrefix}___#{key}\"]").addClass('has-error')
            #item.closest('.form-group').find('.help-inline').text( value )

          e.preventDefault()
          e.stopPropagation()
          return
      )


    # date
    else if attribute.tag is 'datetime'

      # set data type
      if attribute.name
        attribute.nameRaw = attribute.name
        attribute.name    = '{datetime}' + attribute.name
      if attribute.value
        if typeof( attribute.value ) is 'string'
          unixtime = new Date( Date.parse( attribute.value ) )
        else
          unixtime = new Date( attribute.value )
        year     = unixtime.getFullYear()
        month    = unixtime.getMonth() + 1
        day      = unixtime.getDate()
        hour     = unixtime.getHours()
        minute   = unixtime.getMinutes()
      item = $( App.view('generic/datetime')(
        attribute: attribute
        year:      year
        month:     month
        day:       day
        hour:      hour
        minute:    minute
      ) )

      setNewTime = (diff, el, reset) ->
        name = $(el).closest('.form-group').find('[data-name]').attr('data-name')

        # remove old validation
        item.find('.has-error').removeClass('has-error')
        item.closest('.form-group').find('.help-inline').html('')

        day    = item.closest('.form-group').find("[name=\"{datetime}#{name}___day\"]").val()
        month  = item.closest('.form-group').find("[name=\"{datetime}#{name}___month\"]").val()
        year   = item.closest('.form-group').find("[name=\"{datetime}#{name}___year\"]").val()
        hour   = item.closest('.form-group').find("[name=\"{datetime}#{name}___hour\"]").val()
        minute = item.closest('.form-group').find("[name=\"{datetime}#{name}___minute\"]").val()
        format = (number) ->
          if parseInt(number) < 10
            number = "0#{number}"
          number
        if !reset && (year isnt '' && month isnt '' && day isnt '' && hour isnt '' && day isnt '')
          time = new Date( Date.parse( "#{year}-#{format(month)}-#{format(day)}T#{format(hour)}:#{format(minute)}:00Z" ) )
          time.setMinutes( time.getMinutes() + diff + time.getTimezoneOffset() )
        else
          time = new Date()
          time.setMinutes( time.getMinutes() + diff )
        #console.log('T', time, time.getHours(), time.getMinutes())
        item.closest('.form-group').find("[name=\"{datetime}#{name}___day\"]").val( time.getDate() )
        item.closest('.form-group').find("[name=\"{datetime}#{name}___month\"]").val( time.getMonth()+1 )
        item.closest('.form-group').find("[name=\"{datetime}#{name}___year\"]").val( time.getFullYear() )
        item.closest('.form-group').find("[name=\"{datetime}#{name}___hour\"]").val( time.getHours() )
        item.closest('.form-group').find("[name=\"{datetime}#{name}___minute\"]").val( time.getMinutes() )

      item.find('.js-today').bind('click', (e) ->
        e.preventDefault()
        setNewTime(0, @, true)
      )
      item.find('.js-plus-hour').bind('click', (e) ->
        e.preventDefault()
        setNewTime(60, @)
      )
      item.find('.js-minus-hour').bind('click', (e) ->
        e.preventDefault()
        setNewTime(-60, @)
      )
      item.find('.js-plus-day').bind('click', (e) ->
        e.preventDefault()
        setNewTime(60 * 24, @)
      )
      item.find('.js-minus-day').bind('click', (e) ->
        e.preventDefault()
        setNewTime(-60 * 24, @)
      )
      item.find('.js-plus-week').bind('click', (e) ->
        e.preventDefault()
        setNewTime(60 * 24 * 7, @)
      )
      item.find('.js-minus-week').bind('click', (e) ->
        e.preventDefault()
        setNewTime(-60 * 24 * 7, @)
      )

      item.find('input').bind('keyup blur focus change', (e) ->

        # do validation
        name = $(@).attr('name')
        if name
          fieldPrefix = name.split('___')[0]

        # remove old validation
        item.find('.has-error').removeClass('has-error')
        item.closest('.form-group').find('.help-inline').html('')

        day    = item.closest('.form-group').find("[name=\"#{fieldPrefix}___day\"]").val()
        month  = item.closest('.form-group').find("[name=\"#{fieldPrefix}___month\"]").val()
        year   = item.closest('.form-group').find("[name=\"#{fieldPrefix}___year\"]").val()
        hour   = item.closest('.form-group').find("[name=\"#{fieldPrefix}___hour\"]").val()
        minute = item.closest('.form-group').find("[name=\"#{fieldPrefix}___minute\"]").val()

        # validate exists
        errors = {}
        if !day
          errors.day = 'missing'
        if !month
          errors.month = 'missing'
        if !year
          errors.year = 'missing'
        if !hour
          errors.hour = 'missing'
        if !minute
          errors.minute = 'missing'

        # ranges
        if day
          daysInMonth = 31
          if month && year
            daysInMonth = new Date(year, month, 0).getDate();

          if parseInt(day).toString() is 'NaN'
            errors.day = 'invalid'
          else if parseInt(day) > daysInMonth || parseInt(day) < 1
            errors.day = 'invalid'

        if month
          if parseInt(month).toString() is 'NaN'
            errors.month = 'invalid'
          else if parseInt(month) > 12 || parseInt(month) < 1
            errors.month = 'invalid'

        if year
          if parseInt(year).toString() is 'NaN'
            errors.year = 'invalid'
          else if parseInt(year) > 2100 || parseInt(year) < 2001
            errors.year = 'invalid'

        if hour
          if parseInt(hour).toString() is 'NaN'
            errors.hour = 'invalid'
          else if parseInt(hour) > 23 || parseInt(hour) < 0
            errors.hour = 'invalid'

        if minute
          if parseInt(minute).toString() is 'NaN'
            errors.minute = 'invalid'
          else if parseInt(minute) > 59
            errors.minute = 'invalid'

        if !_.isEmpty(errors)

          # if field is required, if not do not show error
          if year is '' && day is '' && month is '' && hour is '' && minute is ''
            if attribute.null
              e.preventDefault()
              e.stopPropagation()
              return
            else
              item.closest('.form-group').find('.help-inline').text( 'is required' )

          # show invalid options
          for key, value of errors
            item.closest('.form-group').addClass('has-error')
            item.closest('.form-group').find("[name=\"#{fieldPrefix}___#{key}\"]").addClass('has-error')
            #item.closest('.form-group').find('.help-inline').text( value )

          e.preventDefault()
          e.stopPropagation()
          return
      )

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
              addItem( "#{ attribute.name }::#{key}", listItem.name, item.find('.add a'), value )

    # checkbox
    else if attribute.tag is 'checkbox'
      item = $( App.view('generic/checkbox')( attribute: attribute ) )

    # radio
    else if attribute.tag is 'radio'
      item = $( App.view('generic/radio')( attribute: attribute ) )

    # richtext
    else if attribute.tag is 'richtext'
      item = $( App.view('generic/richtext')( attribute: attribute ) )
      item.find('[contenteditable]').ce(
        mode:      attribute.type
        maxlength: attribute.maxlength
      )
      if attribute.upload
        item.append( $( App.view('generic/attachment')( attribute: attribute ) ) )

        renderAttachment = (file) =>
          item.find('.attachments').append( App.view('generic/attachment_item')(
            fileName: file.filename
            fileSize: @humanFileSize( file.size )
            store_id: file.store_id
          ))
          item.on(
            'click'
            "[data-id=#{file.store_id}]", (e) =>
              @attachments = _.filter(
                @attachments,
                (item) ->
                  return if item.id isnt file.store_id
                  item
              )
              store_id = $(e.currentTarget).data('id')

              # delete attachment from storage
              App.Ajax.request(
                type:        'DELETE'
                url:         App.Config.get('api_path') + '/ticket_attachment_upload'
                data:        JSON.stringify( { store_id: store_id } ),
                processData: false
                success:     (data, status, xhr) =>
              )

              # remove attachment from dom
              element = $(e.currentTarget).closest('.attachments')
              $(e.currentTarget).closest('.attachment').remove()
              # empty .attachment (remove spaces) to keep css working, thanks @mrflix :-o
              if element.find('.attachment').length == 0
                element.empty()
          )

        @attachments           = []
        @progressBar           = item.find('.attachmentUpload-progressBar')
        @progressText          = item.find('.js-percentage')
        @attachmentPlaceholder = item.find('.attachmentPlaceholder')
        @attachmentUpload      = item.find('.attachmentUpload')
        @attachmentsHolder     = item.find('.attachments')
        @cancelContainer       = item.find('.js-cancel')

        u = => html5Upload.initialize(
          uploadUrl:              App.Config.get('api_path') + '/ticket_attachment_upload',
          dropContainer:          item.closest('form').get(0),
          cancelContainer:        @cancelContainer,
          inputField:             item.find( 'input' ).get(0),
          key:                    'File',
          data:                   { form_id: @form_id },
          maxSimultaneousUploads: 1,
          onFileAdded:            (file) =>

            file.on(

              onStart: =>
                @attachmentPlaceholder.addClass('hide')
                @attachmentUpload.removeClass('hide')
                @cancelContainer.removeClass('hide')
                console.log('upload start')

              onAborted: =>
                @attachmentPlaceholder.removeClass('hide')
                @attachmentUpload.addClass('hide')

              # Called after received response from the server
              onCompleted: (response) =>

                response = JSON.parse(response)
                @attachments.push response.data

                @attachmentPlaceholder.removeClass('hide')
                @attachmentUpload.addClass('hide')

                renderAttachment(response.data)
                console.log('upload complete', response.data )

              # Called during upload progress, first parameter
              # is decimal value from 0 to 100.
              onProgress: (progress, fileSize, uploadedBytes) =>
                @progressBar.width(parseInt(progress) + "%")
                @progressText.text(parseInt(progress))
                # hide cancel on 90%
                if parseInt(progress) >= 90
                  @cancelContainer.addClass('hide')
                console.log('uploadProgress ', parseInt(progress))
            )
        )
        App.Delay.set( u, 100, undefined, 'form_upload' )

    # textarea
    else if attribute.tag is 'textarea'
      fileUploaderId = 'file-uploader-' + new Date().getTime() + '-' + Math.floor( Math.random() * 99999 )
      item = $( App.view('generic/textarea')( attribute: attribute ) + '<div class="file-uploader ' + attribute.class + '" id="' + fileUploaderId + '"></div>' )

      a = =>
        visible = $( item[0] ).is(":visible")
        if visible && !$( item[0] ).expanding('active')
          $( item[0] ).expanding()
        $( item[0] ).on('focus', ->
          visible = $( item[0] ).is(":visible")
          if visible && !$( item[0] ).expanding('active')
            $( item[0] ).expanding()
        )
      App.Delay.set( a, 80 )

      if attribute.upload

        # add file uploader
        u = =>
          # only add upload item if html element exists
          if @el.find('#' + fileUploaderId )[0]
            @el.find('#' + fileUploaderId ).fineUploader(
              request:
                endpoint: App.Config.get('api_path') + '/ticket_attachment_upload'
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

    # user
    else if attribute.tag is 'user_autocompletion'
      completion = new App.UserOrganizationAutocompletion( attribute: attribute )
      item = completion.element()

    # autocompletion
    else if attribute.tag is 'autocompletion'
      item = $( App.view('generic/autocompletion')( attribute: attribute ) )

      a = =>
        local_attribute      = '#' + attribute.id
        local_attribute_full = '#' + attribute.id + '_autocompletion'
        @callback            = attribute.callback

        # call calback on init
        if @callback && attribute.value && @params
          @callback( @params )

        b = (event, item) =>
          # set html form attribute
          $(local_attribute).val(item.id).trigger('change')
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
        source = attribute.source
        if typeof(source) is 'string'
          source = source.replace('#{@apiPath}', App.Config.get('api_path') );
        $(local_attribute_full).autocomplete(
          source: source,
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

    # ticket attribute set
    else if attribute.tag is 'ticket_attribute_set'

      # list of possible attributes
      item = $(
        App.view('generic/ticket_attribute_manage')(
          attribute: attribute
        )
      )

      addShownAttribute = ( key, value ) =>
        parts = key.split(/::/)
        key   = parts[0]
        type  = parts[1]
        if key is 'tickets.title'
          attribute_config = {
            name:    attribute.name + '::tickets.title'
            display: 'Title'
            tag:     'input'
            type:    'text'
            null:    false
            value:   value
            remove:  true
          }
        else if key is 'tickets.group_id'
          attribute_config = {
            name:       attribute.name + '::tickets.group_id'
            display:    'Group'
            tag:        'select'
            multiple:   false
            null:       false
            nulloption: false
            relation:   'Group'
            value:      value
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
            multiple:   false
            null:       false
            nulloption: false
            relation:   'User'
            value:      value || null
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
            multiple:   false
            null:       false
            nulloption: false
            relation:   'Organization'
            value:      value || null
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
            multiple:   false
            null:       false
            nulloption: false
            relation:   'TicketState'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.priority_id'
          attribute_config = {
            name:       attribute.name + '::tickets.priority_id'
            display:    'Priority'
            tag:        'select'
            multiple:   false
            null:       false
            nulloption: false
            relation:   'TicketPriority'
            value:      value
            translate:  true
            remove:     true
          }
        else
          attribute_config = {
            name:       attribute.name + '::' + key
            display:    'FIXME!'
            tag:        'input'
            type:       'text'
            value:      value
            remove:     true
          }
        item.find('select[name=ticket_attribute_list] option[value="' + key + '"]').hide().prop('disabled', true)

        itemSub = @formGenItem( attribute_config )
        itemSub.find('.glyphicon-minus').bind('click', (e) ->
          e.preventDefault()
          value = $(e.target).closest('.controls').find('[name]').attr('name')
          if value
            value = value.replace("#{attribute.name}::", '')
            $(e.target).closest('.sub_attribute').find('select[name=ticket_attribute_list] option[value="' + value + '"]').show().prop('disabled', false)
          $(@).parent().parent().parent().remove()
        )
#        itemSub.append('<a href=\"#\" class=\"icon-minus\"></a>')
        item.find('.ticket_attribute_item').append( itemSub )

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
          {
            value:    'tickets.title'
            name:     'Title'
            selected: false
            disable:  false
          },
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
#         # {
#            value:    'tag'
#            name:     'Tag'
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
          {
            value:    '-c'
            name:     '-- ' + App.i18n.translateInline('Customer') + ' --'
            selected: false
            disable:  true
          },
          {
            value:    'customers.id'
            name:     'Customer'
            selected: true
            disable:  false
          },
          {
            value:    'organization.id'
            name:     'Organization'
            selected: true
            disable:  false
          },
        ]
        default:    ''
        translate:  true
        class:      'medium'
        add:        true
      }
      list = @formGenItem( attribute_config )
      list.find('.glyphicon-plus').bind('click', (e) ->
        e.preventDefault()
        value = $(e.target).closest('.controls').find('[name=ticket_attribute_list]').val()
        addShownAttribute( value, '' )
      )
      item.find('.ticket_attribute_list').prepend( list )

      # list of shown attributes
      show = []
      if attribute.value
        for key, value of attribute.value
          addShownAttribute( key, value )

    # ticket attribute selection
    else if attribute.tag is 'ticket_attribute_selection'

      # list of possible attributes
      item = $(
        App.view('generic/ticket_attribute_manage')(
          attribute: attribute
        )
      )

      addShownAttribute = ( key, value ) =>
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
            remove:     true
          }
        else if key is 'tickets.created_at' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.created_at'
            display:    'Created (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.created_at' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.created_at'
            display:    'Created (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.close_time' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.close_time'
            display:    'Closed (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.close_time' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.close_time'
            display:    'Closed (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.updated_at' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.updated_at'
            display:    'Updated (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.updated_at' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.updated_at'
            display:    'Updated (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.escalation_time' && ( type is '<>' || value.count )
          attribute_config = {
            name:       attribute.name + '::tickets.escalation_time'
            display:    'Escalation (before / last)'
            tag:        'time_before_last'
            value:      value
            translate:  true
            remove:     true
          }
        else if key is 'tickets.escalation_time' && ( type is '><' || 0 )
          attribute_config = {
            name:       attribute.name + '::tickets.escalation_time'
            display:    'Escatlation (between)'
            tag:        'time_range'
            value:      value
            translate:  true
            remove:     true
          }
        else
          attribute_config = {
            name:       attribute.name + '::' + key
            display:    'FIXME!'
            tag:        'input'
            type:       'text'
            value:      value
            remove:     true
          }

        item.find('select[name=ticket_attribute_list] option[value="' + key + '"]').hide().prop('disabled', true)

        itemSub = @formGenItem( attribute_config )
        itemSub.find('.glyphicon-minus').bind('click', (e) ->
          e.preventDefault()
          value = $(e.target).closest('.controls').find('[name]').attr('name')
          if value
            value = value.replace("#{attribute.name}::", '')
            $(e.target).closest('.sub_attribute').find('select[name=ticket_attribute_list] option[value="' + value + '"]').show().prop('disabled', false)
          $(@).parent().parent().parent().remove()
        )
#        itemSub.append('<a href=\"#\" class=\"icon-minus\"></a>')
        item.find('.ticket_attribute_item').append( itemSub )

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
          {
            value:    'tickets.number'
            name:     'Number'
            selected: false
            disable:  false
          },
          {
            value:    'tickets.title'
            name:     'Title'
            selected: false
            disable:  false
          },
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
          #{
          #  value:    'tickets.created_at::<>'
          #  name:     'Created (before/last)'
          #  selected: true
          #  disable:  false
          #},
          #{
          #  value:    'tickets.created_at::><'
          #  name:     'Created (between)'
          #  selected: true
          #  disable:  false
          #},
          #{
          #  value:    'tickets.close_time::<>'
          #  name:     'Closed (before/last)'
          #  selected: true
          #  disable:  false
          #},
          #{
          #  value:    'tickets.close_time::><'
          #  name:     'Closed (between)'
          #  selected: true
          #  disable:  false
          #},
          #{
          #  value:    'tickets.updated_at::<>'
          #  name:     'Updated (before/last)'
          #  selected: true
          #  disable:  false
          #},
          #{
          #  value:    'tickets.updated_at::><'
          #  name:     'Updated (between)'
          #  selected: true
          #  disable:  false
          #},
          #{
          #  value:    'tickets.escalation_time::<>'
          #  name:     'Escalation (before/last)'
          #  selected: true
          #  disable:  false
          #},
          #{
          #  value:    'tickets.escalation_time::><'
          #  name:     'Escalation (between)'
          #  selected: true
          #  disable:  false
          #},
#         # {
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
          {
            value:    '-c'
            name:     '-- ' + App.i18n.translateInline('Customer') + ' --'
            selected: false
            disable:  true
          },
          {
            value:    'customers.id'
            name:     'Customer'
            selected: true
            disable:  false
          },
          {
            value:    'organization.id'
            name:     'Organization'
            selected: true
            disable:  false
          },
        ]
        default:    ''
        translate:  true
        class:      'medium'
        add:        true
      }
      list = @formGenItem( attribute_config )

      list.find('.glyphicon-plus').bind('click', (e) ->
        e.preventDefault()
        value = $(e.target).closest('.controls').find('[name=ticket_attribute_list]').val()
        addShownAttribute( value, '' )
      )
      item.find('.ticket_attribute_list').prepend( list )

      # list of shown attributes
      show = []
      if attribute.value
        for key, value of attribute.value
          addShownAttribute( key, value )

    # timeplan
    else if attribute.tag is 'timeplan'
      item = $( App.view('generic/timeplan')( attribute: attribute ) )
      attribute_config = {
        name:     "#{attribute.name}::days"
        tag:      'select'
        multiple: true
        null:     false
        options:  [
          {
            value:    'mon'
            name:     'Monday'
            selected: false
            disable:  false
          },
          {
            value:    'tue'
            name:     'Tuesday'
            selected: false
            disable:  false
          },
          {
            value:    'wed'
            name:     'Wednesday'
            selected: false
            disable:  false
          },
          {
            value:    'thu'
            name:     'Thursday'
            selected: false
            disable:  false
          },
          {
            value:    'fri'
            name:     'Friday'
            selected: false
            disable:  false
          },
          {
            value:    'sat'
            name:     'Saturday'
            selected: false
            disable:  false
          },
          {
            value:    'sun'
            name:     'Sunday'
            selected: false
            disable:  false
          },
        ]
        default:  attribute.default?.days
      }
      item.find('.days').append( @formGenItem( attribute_config ) )

      hours = {}
      for hour in [0..23]
        localHour = "0#{hour}"
        hours[hour] = localHour.substr(localHour.length-2,2)
      attribute_config = {
        name:     "#{attribute.name}::hours"
        tag:      'select'
        multiple: true
        null:     false
        options:  hours
        default:  attribute.default?.hours
      }
      item.find('.hours').append( @formGenItem( attribute_config ) )

      minutes = {}
      for minute in [0..5]
        minutes["#{minute}0"] = "#{minute}0"
      attribute_config = {
        name:     "#{attribute.name}::minutes"
        tag:      'select'
        multiple: true
        null:     false
        options:  minutes
        default:  attribute.default?.miuntes
      }
      item.find('.minutes').append( @formGenItem( attribute_config ) )

    # input
    else
      item = $( App.view('generic/input')( attribute: attribute ) )

    if @handlers
      item.bind('change', (e) =>
        params = App.ControllerForm.params( $(e.target) )
        for handler in @handlers
          handler(params, attribute, @attributes, classname, form, @)
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
              if !value
                value = $(@).find('select, input').val()

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
          bookmarkable: @bookmarkable
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
      el.find('[name="' + key + '"]').closest('.form-group').removeClass('hide')
      el.find('[name="' + key + '"]').removeClass('is-hidden')
      el.find('[data-name="' + key + '"]').closest('.form-group').removeClass('hide')
      el.find('[data-name="' + key + '"]').removeClass('is-hidden')

    # hide old validation states
    if el
      el.find('.has-error').removeClass('has-error')
      el.find('.help-inline').html('')

  _hide: (name, el = @el) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').closest('.form-group').addClass('hide')
      el.find('[name="' + key + '"]').addClass('is-hidden')
      el.find('[data-name="' + key + '"]').closest('.form-group').addClass('hide')
      el.find('[data-name="' + key + '"]').addClass('is-hidden')

  _mandantory: (name, el = @el) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').attr('required', true)
      el.find('[name="' + key + '"]').parents('.form-group').find('label span').html('*')

  _optional: (name, el = @el) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').attr('required', false)
      el.find('[name="' + key + '"]').parents('.form-group').find('label span').html('')

  _showHideToggle: (params, changedAttribute, attributes, classname, form, ui) =>
    for attribute in attributes
      if attribute.shown_if
        hit = false
        for refAttribute, refValue of attribute.shown_if
          if params[refAttribute]
            if _.isArray( refValue )
              for item in refValue
                if params[refAttribute].toString() is item.toString()
                  hit = true
            else if params[refAttribute].toString() is refValue.toString()
              hit = true
        if hit
          ui._show(attribute.name)
        else
          ui._hide(attribute.name)

  _requiredMandantoryToggle: (params, changedAttribute, attributes, classname, form, ui) =>
    for attribute in attributes
      if attribute.required_if
        hit = false
        for refAttribute, refValue of attribute.required_if
          if params[refAttribute]
            if _.isArray( refValue )
              for item in refValue
                if params[refAttribute].toString() is item.toString()
                  hit = true
            else if params[refAttribute].toString() is refValue.toString()
              hit = true
        if hit
          ui._mandantory(attribute.name)
        else
          ui._optional(attribute.name)

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

      # data based filter
      else if attribute.filter && _.isArray attribute.filter

        App.Log.debug 'ControllerForm', '_getRelationOptionList:filter-array', attribute.filter

        # check all records
        for record in App[ attribute.relation ].search( sortBy: attribute.sortBy )

          # check all filter attributes
          for key in attribute.filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key || ( record['id'] && key && record['id'].toString() is key.toString() )
              list.push record

        # check if current value need to be added
        if @params[ attribute.name ]
          hit = false
          for value in list
            if value['id'].toString() is @params[ attribute.name ].toString()
              hit = true
          if !hit
            currentRecord = App[ attribute.relation ].find( @params[ attribute.name ] )
            list.push currentRecord

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

    # check if selected / checked need to be set
    check = (value, record) ->
      if typeof value is 'string' || typeof value is 'number' || typeof value is 'boolean'

        # if name or value is matching
        if record.value.toString() is value.toString() || record.name.toString() is value.toString()
          record.selected = 'selected'
          record.checked = 'checked'

      else if ( value && record.value && _.include( value, record.value ) ) || ( value && record.name && _.include( value, record.name ) )
        record.selected = 'selected'
        record.checked = 'checked'

    # lookup of any record
    for record in attribute.options

      if _.isArray( attribute.value )
        for value in attribute.value
          check( value, record )

      if typeof attribute.value is 'string' || typeof attribute.value is 'number' || typeof attribute.value is 'boolean'
        check( attribute.value, record )

    # if noting is selected / checked, use default as selected / checked
    selected = false
    for record in attribute.options
      if record.selected || record.checked
        selected = true
    if !selected
      for record in attribute.options
        if typeof attribute.default is 'string' || typeof attribute.default is 'number' || typeof attribute.default is 'boolean'
          check( attribute.default, record )

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
      model:  @model
      params: params
      screen: @screen
  )

  # get all params of the form
  @params: (form) ->
    param = {}

    lookupForm = @findForm(form)

    # get contenteditable
    for element in lookupForm.find('[contenteditable]')
      name = $(element).data('name')
      if name
        param[name] = $(element).ceg()

    # get form elements
    array = lookupForm.serializeArray()

    # array to names
    for key in array

      # check if item is-hidden and should not be used
      if lookupForm.find('[name="' + key.name + '"]').hasClass('is-hidden')
        param[key.name] = undefined
        continue

      # collect all params, push it to an array if already exists
      if param[key.name]
        if typeof param[key.name] is 'string'
          param[key.name] = [ param[key.name], key.value]
        else
          param[key.name].push key.value
      else
        param[key.name] = key.value

    # data type conversion
    for key of param

      # get boolean
      if key.substr(0,9) is '{boolean}'
        newKey          = key.substr( 9, key.length )
        param[ newKey ] = param[ key ]
        delete param[ key ]
        if param[ newKey ] && param[ newKey ].toString() is 'true'
          param[ newKey ] = true
        else
          param[ newKey ] = false

      # get {date}
      else if key.substr(0,6) is '{date}'
        newKey    = key.substr( 6, key.length )
        namespace = newKey.split '___'

        if !param[ namespace[0] ]
          dateKey = "{date}#{namespace[0]}___"
          year    = param[ "#{dateKey}year" ]
          month   = param[ "#{dateKey}month" ]
          day     = param[ "#{dateKey}day" ]

          if lookupForm.find('[data-name = "' + namespace[0] + '"]').hasClass('is-hidden')
            param[ namespace[0] ] = null
          else if year && month && day && day
            format = (number) ->
              if parseInt(number) < 10
                number = "0#{number}"
              number
            try
              time = new Date( Date.parse( "#{year}-#{format(month)}-#{format(day)}T00:00:00Z" ) )
              if time && time.toString() is 'Invalid Date'
                throw "Invalid Date #{year}-#{format(month)}-#{format(day)}"
              param[ namespace[0] ] = "#{time.getUTCFullYear()}-#{format(time.getUTCMonth()+1)}-#{format(time.getUTCDate())}"
            catch err
              param[ namespace[0] ] = undefined
              console.log('ERR', err)
          else
            param[ namespace[0] ] = undefined

        #console.log('T', time, time.getHours(), time.getMinutes())

          delete param[ "#{dateKey}year" ]
          delete param[ "#{dateKey}month" ]
          delete param[ "#{dateKey}day" ]

      # get {datetime}
      else if key.substr(0,10) is '{datetime}'
        newKey    = key.substr( 10, key.length )
        namespace = newKey.split '___'

        if !param[ namespace[0] ]
          datetimeKey = "{datetime}#{namespace[0]}___"
          year        = param[ "#{datetimeKey}year" ]
          month       = param[ "#{datetimeKey}month" ]
          day         = param[ "#{datetimeKey}day" ]
          hour        = param[ "#{datetimeKey}hour" ]
          minute      = param[ "#{datetimeKey}minute" ]

          if lookupForm.find('[data-name="' + namespace[0] + '"]').hasClass('is-hidden')
            param[ namespace[0] ] = null
          else if year && month && day && hour && minute
            format = (number) ->
              if parseInt(number) < 10
                number = "0#{number}"
              number
            try
              time = new Date( Date.parse( "#{year}-#{format(month)}-#{format(day)}T#{format(hour)}:#{format(minute)}:00Z" ) )
              if time && time.toString() is 'Invalid Date'
                throw "Invalid Date #{year}-#{format(month)}-#{format(day)}T#{format(hour)}:#{format(minute)}:00Z"
              time.setMinutes( time.getMinutes() + time.getTimezoneOffset() )
              param[ namespace[0] ] = time.toISOString()
            catch err
              param[ namespace[0] ] = undefined
              console.log('ERR', err)
          else
            param[ namespace[0] ] = undefined

        #console.log('T', time, time.getHours(), time.getMinutes())

          delete param[ "#{datetimeKey}year" ]
          delete param[ "#{datetimeKey}month" ]
          delete param[ "#{datetimeKey}day" ]
          delete param[ "#{datetimeKey}hour" ]
          delete param[ "#{datetimeKey}minute" ]

    # split :: fields, build objects
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

    # set new object params
    for key of inputSelectObject
      param[ key ] = inputSelectObject[ key ]

    #App.Log.notice 'ControllerForm', 'formParam', form, param
    return param

  @formId: ->
    formId = new Date().getTime() + Math.floor( Math.random() * 99999 )
    formId.toString().substr formId.toString().length-9, 9

  @findForm: (form) ->
    # check jquery event
    if form && form.target
      form = form.target

    # create jquery object if not already exists
    if form instanceof jQuery
      # do nothing
    else
      form = $(form)

    #console.log('FF', form)
    # get form
    if form.is('form') is true
      #console.log('direct from')
      return form
    else if form.find('form').is('form') is true
      #console.log('child from')
      return form.find('form')
    else if $(form).closest('form').is('form') is true
      #console.log('closest from')
      return form.closest('form')
    # use current content as form if form isn't already finished
    else if !@finishForm
      #console.log('finishForm')
      return form
    else
      App.Log.error 'ControllerForm', 'no form found!', form
    form

  @disable: (form) ->
    lookupForm = @findForm(form)

    if lookupForm
      App.Log.notice 'ControllerForm', 'disable...', lookupForm
      lookupForm.find('button').attr('disabled', true)
      lookupForm.find('[type="submit"]').attr('disabled', true)
      lookupForm.find('[type="reset"]').attr('disabled', true)
    else
      App.Log.notice 'ControllerForm', 'disable item...', form
      form.attr('disabled', true)

  @enable: (form) ->

    lookupForm = @findForm(form)

    if lookupForm
      App.Log.notice 'ControllerForm', 'enable...', lookupForm
      lookupForm.find('button').attr('disabled', false)
      lookupForm.find('[type="submit"]').attr('disabled', false)
      lookupForm.find('[type="reset"]').attr('disabled', false)
    else
      App.Log.notice 'ControllerForm', 'enable item...', form
      form.attr('disabled', false)

  @validate: (data) ->

    lookupForm = @findForm(data.form)

    # remove all errors
    lookupForm.find('.has-error').removeClass('has-error')
    lookupForm.find('.help-inline').html('')

    # show new errors
    for key, msg of data.errors
      item = lookupForm.find('[name="' + key + '"]').closest('.form-group')
      item.addClass('has-error')
      item.find('.help-inline').html(msg)

      item = lookupForm.find('[data-name="' + key + '"]').closest('.form-group')
      item.addClass('has-error')
      item.find('.help-inline').html(msg)

    # set autofocus
    lookupForm.find('.has-error').find('input, textarea, select').first().focus()
