class App.ControllerForm extends App.Controller
  constructor: (params) ->
    for key, value of params
      @[key] = value
    @attribute_count = 0

    @form = @formGen()
#    @log 'form', @form
    if @el
      @el.append( @form )

  html: =>
    @form.html()

  formGen: ->
    fieldset = $('<fieldset>')

    for attribute_clean in @model.configure_attributes
      attribute = _.clone( attribute_clean )

      if !attribute.readonly && ( !@required || @required && attribute[@required] )

        @attribute_count = @attribute_count + 1

        # add item
        item = @formGenItem( attribute, @model.className, fieldset )
        item.appendTo(fieldset)

        # if password, add confirm password item
        if attribute.type is 'password'

          attribute.display = attribute.display + ' (confirm)'
          attribute.name = attribute.name + '_confirm';

          item = @formGenItem( attribute, @model.className, fieldset )
          item.appendTo(fieldset)

    # return form
    return fieldset

  ###

  # input text field with max. 100 size
  attribute_config = {
    name:     'subject',
    display:  'Subject',
    tag:      'input',
    type:     'text',
    limit:    100,
    null:     false,
    default:  defaults['subject'],
    class:    'span7'
  }

  # colection as relation with auto completion
  attribute_config = {
    name:           'customer_id',
    display:        'Customer',
    tag:            'autocompletion',
    # auto completion params, endpoints, ui,...
    type:           'text',
    limit:          100,
    null:           false,
    relation:       'User',
    autocapitalize: false,
    help:           'Select the customer of the Ticket or create one.',
    link:           '<a href="" class="customer_new">&raquo;</a>',
    callback:       @userInfo
    class:          'span7',
  }

  # colection as relation
  attribute_config = {
    name:       'ticket_priority_id',
    display:    'Priority',
    tag:        'select',
    multiple:   false,
    null:       false,
    relation:   'TicketPriority',
    default:    defaults['ticket_priority_id'],
    translate:  true,
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

    # set value
    if @params
      if attribute.name of @params
        attribute.value = @params[attribute.name]

    # set default value
    else
      if 'default' of attribute
        attribute.value = attribute.default
      else
        attribute.value = ''

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

    # boolean
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

    # checkbox
    else if attribute.tag is 'checkbox'
      item = $( App.view('generic/checkbox')( attribute: attribute ) )

    # radio
    else if attribute.tag is 'radio'
      item = App.view('generic/radio')( attribute: attribute )

    # textarea
    else if attribute.tag is 'textarea'
      item = $( App.view('generic/textarea')( attribute: attribute ) )

    # autocompletion
    else if attribute.tag is 'autocompletion'
      item = $( App.view('generic/autocompletion')( attribute: attribute ) )

      a = ->
        @local_attribute = '#' + attribute.id
        @local_attribute_full = '#' + attribute.id + '_autocompletion'
        @callback = attribute.callback
  
        b = (event, key) =>

          # set html form attribute
          $(@local_attribute).val(key)

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
            select: ( event, ui ) =>
              @log 'selected', event, ui
              b(event, ui.item.id)
          }
        )
        ###
        @log '111111', @local_attribute_full, item
        $(@local_attribute_full).autocomplete(
          source: '/api/users/search',
          minLength: 2,
          select: ( event, ui ) =>
            @log 'selected', event, ui
            b(event, ui.item.id)
        )

      @delay(a, 600)


    # input
    else
      item = $( App.view('generic/input')( attribute: attribute ) )

    if attribute.onchange
      @log 'on change', attribute.name
      if typeof attribute.onchange is 'function'
        attribute.onchange(attribute)
      else
        for i of attribute.onchange
          a = i.split(/__/)
          if a[1]
            if a[0] is attribute.name
              @log 'aaa', i, a[0], attribute.id
              @attribute = attribute
              @classname = classname
              @attributes_clean = attributes_clean
              @change = a
              b = =>
                console.log 'aaa', @attribute
                attribute = @attribute
                change = @change
                classname = @classname
                attributes_clean = @attributes_clean
                ui = @
                $('#' + @attribute.id).bind('change', ->
                  ui.log 'change', @, attribute, change
                  ui.log change[0] + ' has changed - changing ' + change[1]

                  item = $( ui.formGenItem(attribute, classname, attributes_clean) )
                  ui.log item, classname
                )
              @delay(b, 800)
#            if attribute.onchange[]

    ui = @
#    item.bind('focus', ->
#      ui.log 'focus', attribute
#    );
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

    if !attribute.display
      return item
    else
      a = $( App.view('generic/attribute')(
        attribute: attribute,
        item:      '',
      ) )
      a.find('.controls').prepend( item )
      return a

  # sort attribute.options
  _sortOptions: (attribute) ->

    return if !attribute.options

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
    attribute.options[''] = '-'
    attribute.options.push {
      name:  '-',
      value: '',
    }


  _getConfigOptionList: (attribute) ->
    return if !attribute.options
    selection = attribute.options
    attribute.options = []
    for key of selection
      attribute.options.push {
        name:  selection[key],
        value: key,
      }


  _getRelationOptionList: (attribute) ->

    # build options list based on relation
    return if !attribute.relation
    return if !App[attribute.relation]

    attribute.options = []

    list = []
    if attribute.filter && attribute.filter[attribute.name]
      filter = attribute.filter[attribute.name]

      # check all records
      for record in App[attribute.relation].all()

        # check all filter attributes
        for key in filter

          # check all filter values as array
          # if it's matching, use it for selection
          if record['id'] is key
            list.push record
    else
      list = App[attribute.relation].all()

    # build options list
    @_buildOptionList( list, attribute )


  # build options list
  _buildOptionList: (list, attribute) ->

    list.forEach( (item) =>

      # if active or if active doesn't exist
      if item.active || !( 'active' of item )
        name = '???'
        if item.name
          name = item.name
        else if item.firstname
          name = item.firstname
          if item.lastname
            if name
             name = name + ' '
          name = name + item.lastname

        name_new = name
        if attribute.translate
          name_new = Ti(name)
        attribute.options.push {
          name:  name_new,
          value: item.id,
          note:  item.note,
        }
    )


  # set selected attributes
  _selectedOptions: (attribute) ->

    return if !attribute.options

    for record in attribute.options
      if typeof attribute.value is 'string' || typeof attribute.value is 'number' || typeof attribute.value is 'boolean'

        # if name or value is matching
        if record.value.toString() is attribute.value.toString() || record.name.toString() is attribute.value.toString()
          record.selected = 'selected'
          record.checked = 'checked'
#          if record.name.toString() is attribute.value.toString()
#            record.selected = 'selected'
#            record.checked = 'checked'

      else if ( attribute.value && record.value && _.include(attribute.value, record.value) ) || ( attribute.value && record.name && _.include(attribute.value, record.name) )
        record.selected = 'selected'
        record.checked = 'checked'

  validate: (params) ->
    App.Model.validate(
      model: @model,
      params: params,
    )

  # get all params of the form
  @params: (form) ->
    param = {}

    # find form based on sub elements
    if $(form).children()[0]
      form = $(form).children().parents('form')

    # find form based on parents next <form>
    else if $(form).parents('form')[0]
      form = $(form).parents('form')

    # find form based on parents next <form>, not really good!
    else if $(form).parents().find('form')[0]
      form = $(form).parents().find('form')
    else
      console.log 'ERROR, no form found!', form

    for key in form.serializeArray()
      if param[key.name]
        if typeof param[key.name] is 'string'
          param[key.name] = [ param[key.name], key.value]
        else
          param[key.name].push key.value
      else

        # check boolean
        boolean = key.value.split '::'
        if boolean[0] is '{boolean}'
          if boolean[1] is 'true'
            key.value = true
          else
            key.value = false

        param[key.name] = key.value

#    console.log 'formParam', form, param
    return param


  @disable: (form) ->
    console.log 'disable...', $(form.target).parent()
    $(form.target).parent().find('[type="submit"]').attr('disabled', true)
    $(form.target).parent().find('[type="reset"]').attr('disabled', true)


  @enable: (form) ->
    console.log 'enable...', $(form).parent()
    $(form).parent().find('[type="submit"]').attr('disabled', false)
    $(form).parent().find('[type="reset"]').attr('disabled', false)

  @validate: (data) ->

    # remove all errors
    $(data.form).parents().find('.error').removeClass('error')
    $(data.form).parents().find('.help-inline').html('')

    # show new errors
    for key, msg of data.errors
      $(data.form).parents().find('[name*="' + key + '"]').parents('div .control-group').addClass('error')
      $(data.form).parents().find('[name*="' + key + '"]').parent().find('.help-inline').html(msg)

    # set autofocus
    $(data.form).parents().find('.error').find('input, textarea').first().focus()

#    # enable form again
#    if $(data.form).parents().find('.error').html()
#      @formEnable(data.form)

