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

    App.Log.debug 'ControllerForm', 'formGenItem-before', attribute

    if App.UiElement[attribute.tag]
      item = App.UiElement[attribute.tag].render(attribute, @params, @)

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
              param[ namespace[0] ] = 'invalid'
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
              param[ namespace[0] ] = 'invalid'
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
      App.Log.debug 'ControllerForm', 'disable form...', lookupForm

      # set forms to read only during communication with backend
      lookupForm.find('button, input, select, textarea').attr('readonly', true)

      # disable additionals submits
      lookupForm.find('button.btn').attr('disabled', true)
    else
      App.Log.notice 'ControllerForm', 'disable item...', form
      form.attr('readonly', true)
      form.attr('disabled', true)

  @enable: (form) ->

    lookupForm = @findForm(form)

    if lookupForm
      App.Log.debug 'ControllerForm', 'enable form...', lookupForm

      # enable fields again
      lookupForm.find('button, input, select, textarea').attr('readonly', false)

      # enable submits again
      lookupForm.find('button.btn').attr('disabled', false)
    else
      App.Log.notice 'ControllerForm', 'enable item...', form
      form.attr('readonly', false)
      form.attr('disabled', false)

  @validate: (data) ->

    lookupForm = @findForm(data.form)

    # remove all errors
    lookupForm.find('.has-error').removeClass('has-error')
    lookupForm.find('.help-inline').html('')

    # show new errors
    for key, msg of data.errors

      # use native fields
      item = lookupForm.find('[name="' + key + '"]').closest('.form-group')
      item.addClass('has-error')
      item.find('.help-inline').html(msg)

      # use meta fields
      item = lookupForm.find('[data-name="' + key + '"]').closest('.form-group')
      item.addClass('has-error')
      item.find('.help-inline').html(msg)

    # set autofocus by delay to make validation testable
    App.Delay.set(
      ->
        lookupForm.find('.has-error').find('input, textarea, select').first().focus()
      200
      'validate'
    )
