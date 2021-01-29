class App.ControllerForm extends App.Controller
  fullFormSubmitLabel: 'Submit'
  fullFormSubmitAdditionalClasses: ''
  fullFormButtonsContainerClass: ''
  fullFormAdditionalButtons: [] # [{className: 'js-class', text: 'Label'}]

  constructor: (params) ->
    super
    for key, value of params
      @[key] = value

    if !@handlers
      @handlers = []

    if @handlersConfig
      for key, value of @handlersConfig
        if value && value.run
          @handlers.push value.run

    @handlers.push @showHideToggle
    @handlers.push @requiredMandantoryToggle

    if !@model
      @model = {}
    if !@attributes
      @attributes = []

    @idPrefix = Math.floor( Math.random() * 999999 ).toString()
    if @model.className
      @idPrefix = "#{@model.className}_#{@idPrefix}"

    # set empty class attributes if needed
    if !@form
      @form = @formGen()

    # add alert placeholder
    @form.prepend('<div class="alert alert--danger js-danger js-alert hide" role="alert"></div>')
    @form.prepend('<div class="alert alert--success js-success hide" role="alert"></div>')

    # Fix for Issue #2510 - Zammad Customers shown as Agents in IE
    # Previously the handlers are called directly, before the DOM elements are ready, thereby causing a race condition under IE11.
    # Now we only dispatch the handlers after the DOM is ready.
    if @handlers.length
      $(@dispatchHandlers)

    # if element is given, prepend form to it
    if @el
      @el.prepend(@form)

    # if element to replace is given, replace form with
    if @elReplace
      @elReplace.html(@form)

    # remove alert on input
    @form.on('input', @hideAlert)

    @finishForm = true
    @form

  dispatchHandlers: =>
    params = App.ControllerForm.params(@form)
    for attribute in @attributes
      for handler in @handlers
        handler(params, attribute, @attributes, @idPrefix, @form, @)

  showAlert: (message) =>
    if Array.isArray(message)
      translated = App.i18n.translateInline(message[0], message.slice(1))
    else
      translated = App.i18n.translateInline(message)

    @form.find('.alert--danger').first().removeClass('hide').html(translated)

  hideAlert: =>
    @form.find('.alert--danger').addClass('hide').html()

  html: =>
    @form.html()

  formGen: =>
    App.Log.debug 'ControllerForm', 'formGen', @model.configure_attributes

    # check if own fieldset should be generated
    # forced when the form is a grid form because flex-wrap doesn't work on fieldsets
    # source: https://github.com/philipwalton/flexbugs#9-some-html-elements-cant-be-flex-containers
    if @noFieldset || @grid
      fieldset = @el
    else
      fieldset = $('<fieldset></fieldset>')

    return fieldset if _.isEmpty(@model)

    # collect form attributes
    @attributes = []
    if @model.attributesGet
      attributesClean = @model.attributesGet(@screen)
    else
      attributesClean = App.Model.attributesGet(@screen, @model.configure_attributes)

    for attributeName, attribute of attributesClean

      # ignore read only or not rendered attributes attributes
      if !attribute.readonly && !attribute.skipRendering

        # check generic filter
        if @filter && !attribute.filter
          if @filter[ attributeName ]
            attribute.filter = @filter[ attributeName ]

        @attributes.push attribute

    attributeCount = 0

    for attribute in @attributes
      attributeCount = attributeCount + 1

      if @isDisabled == true
        attribute.disabled = true

      # add item
      item = @formGenItem(attribute, @idPrefix, fieldset, attributeCount)
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
          attribute.name = attribute.name + '_confirm'
          item = @formGenItem(attribute, @idPrefix, fieldset, attributeCount)
          item.appendTo(fieldset)

    if @fullForm
      if !@formClass
        @formClass = ''

      fieldset = $("<form class='form #{@formClass}' autocomplete='off'>").prepend(fieldset)
      container = $("<div class='form-buttons #{@fullFormButtonsContainerClass}'>")

      for buttonConfig in @fullFormAdditionalButtons
        btn = $("<button class='btn #{buttonConfig.className}'>").text(buttonConfig.text)
        if buttonConfig.disabled
          btn.prop('disabled', true)
        container.append(btn)

      $("<button type=submit class='btn #{@fullFormSubmitAdditionalClasses}\' value=\"#{@fullFormSubmitLabel}\"></button>")
        .text(App.i18n.translateContent(@fullFormSubmitLabel))
        .appendTo(container)

      container.appendTo(fieldset)

      #fieldset = $("<form class=\"#{@formClass}\" autocomplete=\"off\"><div class='horizontal #{@fullFormButtonsContainerClass}'><input type=submit class=\"btn #{@fullFormSubmitAdditionalClasses}\" value=\"#{label}\"></div></form>").prepend(fieldset)
      #fieldset = $("<form class=\"#{@formClass}\" autocomplete=\"off\"><input type=submit class=\"btn #{@fullFormSubmitAdditionalClasses}\" value=\"#{label}\"></form>").prepend(fieldset)

    # bind form events
    if @events
      for eventSelector, callback of @events
        do (eventSelector, callback) ->
          evs = eventSelector.split(' ')
          fieldset.find(evs[1]).bind(evs[0], (e) -> callback(e))

    # bind tool tips
    fieldset.find('.js-helpMessage').tooltip()

    # return form
    fieldset

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

  formGenItem: (attribute_config, idPrefix, form, attributeCount) ->
    attribute = clone(attribute_config, true)

    # create item id
    attribute.id = "#{idPrefix}_#{attribute.name}"

    # set label class name
    attribute.label_class = @model.labelClass

    # set autofocus
    if @autofocus && attributeCount is 1
      attribute.autofocus = 'autofocus'

    # set required option
    if attribute.required is true
      attribute.null = false
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
      if attribute.type is 'hidden'
        attribute.autocomplete = ''
      else
        attribute.autocomplete = 'autocomplete="off"'
    else
      attribute.autocomplete = 'autocomplete="' + attribute.autocomplete + '"'

    # set default values
    if attribute.value is undefined && 'default' of attribute
      attribute.value = attribute.default

    # set params value
    if @params

      parts = attribute.name.split '::'

      if parts.length > 1
        deepValue = parts.reduce((memo, elem) ->
          memo?[elem]
        , @params)

        if deepValue isnt undefined
          attribute.value = deepValue

      # set params value to default
      if attribute.name of @params
        attribute.value = @params[attribute.name]

    # set new value
    if 'newValue' of attribute
      attribute.value = attribute.newValue

    App.Log.debug 'ControllerForm', 'formGenItem-before', attribute

    if App.UiElement[attribute.tag]
      item = App.UiElement[attribute.tag].render(attribute, @params, @)
    else
      throw "Invalid UiElement.#{attribute.tag}"

    if attribute.only_shown_if_selectable
      count = Object.keys(attribute.options).length
      if !attribute.null && (attribute.nulloption && count is 2) || (!attribute.nulloption && count is 1)
        attribute.transparent = true
        attributesNew = clone(attribute)
        attributesNew.type = 'hidden'
        attributesNew.value = ''
        for item in attribute.options
          if item.value && item.value isnt ''
            attributesNew.value = item.value
        item = $( App.view('generic/input')(attribute: attributesNew) )

    if @handlers
      item.bind('change', (e) =>
        params = App.ControllerForm.params($(e.target))
        for handler in @handlers
          handler(params, attribute, @attributes, idPrefix, form, @)
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
                data = App[action.bind.relation].find(value)
                value = data.name

              # check if value is used in condition
              if _.contains(action.bind.value, value)
                if action.change.action is 'hide'
                  ui.hide(action.change.name)
                else
                  ui.show(action.change.name)
            )

    if !attribute.display || attribute.transparent

      # hide/show item
      #if attribute.hide
      #  @.hide(attribute.name)

      return item
    else
      placeholderObjects = {}
      if @model.className && @params && ( attribute.type is 'url' || !_.isEmpty(attribute.linktemplate) ) && !_.isEmpty(@params[attribute.name])
        placeholderObjects = { attribute: attribute, session: App.Session.get(), config: App.Config.all() }
        placeholderObjects[@model.className.toLowerCase()] = @params

      fullItem = $(
        App.view('generic/attribute')(
          attribute: attribute,
          item:      '',
          bookmarkable: @bookmarkable
          placeholderObjects: placeholderObjects
          className: @model.className
        )
      )
      fullItem.find('.controls').prepend(item)

      # hide/show item
      if attribute.hide
        @.hide(attribute.name, fullItem)

      return fullItem

  show: (name, el = @form) ->
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

  hide: (name, el = @form) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').closest('.form-group').addClass('hide')
      el.find('[name="' + key + '"]').addClass('is-hidden')
      el.find('[data-name="' + key + '"]').closest('.form-group').addClass('hide')
      el.find('[data-name="' + key + '"]').addClass('is-hidden')

  mandantory: (name, el = @form) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').attr('required', true)
      el.find('[name="' + key + '"]').parents('.form-group').find('label span').html('*')

  optional: (name, el = @form) ->
    if !_.isArray(name)
      name = [name]
    for key in name
      el.find('[name="' + key + '"]').attr('required', false)
      el.find('[name="' + key + '"]').parents('.form-group').find('label span').html('')

  showHideToggle: (params, changedAttribute, attributes, _classname, form, ui) ->
    for attribute in attributes
      if attribute.shown_if
        hit = false
        for refAttribute, refValue of attribute.shown_if
          if params[refAttribute]
            if _.isArray(refValue)
              for item in refValue
                if params[refAttribute].toString() is item.toString()
                  hit = true
            else if params[refAttribute].toString() is refValue.toString()
              hit = true
        if hit
          ui.show(attribute.name, form)
        else
          ui.hide(attribute.name, form)

  requiredMandantoryToggle: (params, changedAttribute, attributes, _classname, form, ui) ->
    for attribute in attributes
      if attribute.required_if
        hit = false
        for refAttribute, refValue of attribute.required_if
          if params[refAttribute]
            if _.isArray(refValue)
              for item in refValue
                if params[refAttribute].toString() is item.toString()
                  hit = true
            else if params[refAttribute].toString() is refValue.toString()
              hit = true
        if hit
          ui.mandantory(attribute.name, form)
        else
          ui.optional(attribute.name, form)

  validate: (params) ->
    App.Model.validate(
      model:  @model
      params: params
      screen: @screen
    )

  # get all params of the form
  # set clearAccessories to true to remove inline image resizing handles
  @params: (form, clearAccessories = false) ->
    param = {}

    lookupForm = @findForm(form)

    if clearAccessories
      # remove inline image resizing handles
      lookupForm.find('.richtext.form-control').trigger('click')

    # get contenteditable
    for element in lookupForm.find('[contenteditable]')
      name = $(element).data('name')

      if name
        param[name] = $(element).ceg()

    # get form elements
    array = lookupForm.serializeArrayWithType()

    # array to names
    for item in array

      # check if item is-hidden and should not be used
      if lookupForm.find('[name="' + item.name + '"]').hasClass('is-hidden') || lookupForm.find('div[data-name="' + item.name + '"]').hasClass('is-hidden')
        delete param[item.name]
        continue

      # collect all params, push it to an array item.value already exists
      value = item.value
      if item.value
        value = item.value.trim()

      if item.type is 'boolean'
        if value is ''
          value = undefined
        else if value is undefined
          value = false
        else if value is 'true'
          value = true
        else if value is 'false'
          value = false
      if item.type is 'integer'
        if value is ''
          value = undefined
        else
          value = parseInt(value)
      if param[item.name] isnt undefined
        if typeof param[item.name] is 'string' || typeof param[item.name] is 'boolean' || typeof param[item.name] is 'number'
          param[item.name] = [param[item.name], value]
        else
          param[item.name].push value
      else
        param[item.name] = value

    # verify if we have not checked checkboxes
    uncheckParam = {}
    lookupForm.find('input[type=checkbox]').each( (index) ->
      type = $(@).data('field-type')
      checked = $(@).prop('checked')
      name = $(@).attr('name')
      if name && !checked && !(name of param)
        if !(name of uncheckParam)
          if type is 'boolean'
            uncheckParam[name] = false
          else
            uncheckParam[name] = undefined
        else
          uncheckParam[name] = []
      true
    )

    # verify if we have not checked radios
    lookupForm.find('input[type=radio]').each( (index) ->
      type = $(@).data('field-type')
      checked = $(@).prop('checked')
      name = $(@).attr('name')
      if name && !checked && !(name of param)
        if type is 'boolean'
          uncheckParam[name] = false
        else
          uncheckParam[name] = undefined
      true
    )

    # apply empty checkboxes & radio values to params
    for key, value of uncheckParam
      if !(key of param)
        param[key] = value

    # data type conversion
    for key of param

      # get {date}
      if key.substr(0,6) is '{date}'
        newKey = key.substr(6, key.length)
        if lookupForm.find("[data-name=\"#{newKey}\"]").hasClass('is-hidden')
          param[newKey] = null
        else if param[key]
          try
            time = new Date( Date.parse("#{param[key]}T00:00:00Z") )
            format = (number) ->
              if parseInt(number) < 10
                number = "0#{number}"
              number
            if time is 'Invalid Date'
              throw "Invalid Date #{param[key]}"
            param[newKey] = "#{time.getUTCFullYear()}-#{format(time.getUTCMonth()+1)}-#{format(time.getUTCDate())}"
          catch err
            param[newKey] = "invalid #{param[key]}"
            console.log('ERR', err)
        else
          param[newKey] = null
        delete param[key]

      # get {datetime}
      else if key.substr(0,10) is '{datetime}'
        newKey = key.substr(10, key.length)
        if lookupForm.find("[data-name=\"#{newKey}\"]").hasClass('is-hidden')
          param[newKey] = null
        else if param[key]
          try
            time = new Date( Date.parse(param[key]) )
            if time is 'Invalid Datetime'
              throw "Invalid Datetime #{param[key]}"
            param[newKey] = time.toISOString().replace(/:\d\d\.\d\d\dZ$/, ':00.000Z')
          catch err
            param[newKey] = "invalid #{param[key]}"
            console.log('ERR', err)
        else
          param[newKey] = null
        delete param[key]

    # split :: fields, build objects
    inputSelectObject = {}
    for key of param
      parts = key.split '::'
      if parts[0] && parts[1] isnt undefined
        if parts[1] isnt undefined && !inputSelectObject[ parts[0] ]
          inputSelectObject[ parts[0] ] = {}
        if parts[2] isnt undefined && !inputSelectObject[ parts[0] ][ parts[1] ]
          inputSelectObject[ parts[0] ][ parts[1] ] = {}
        if parts[3] isnt undefined && !inputSelectObject[ parts[0] ][ parts[1] ][ parts[2] ]
          inputSelectObject[ parts[0] ][ parts[1] ][ parts[2] ] = {}

        if parts[3] isnt undefined
          inputSelectObject[ parts[0] ][ parts[1] ][ parts[2] ][ parts[3] ] = param[ key ]
          delete param[ key ]
        else if parts[2] isnt undefined
          inputSelectObject[ parts[0] ][ parts[1] ][ parts[2] ] = param[ key ]
          delete param[ key ]
        else if parts[1] isnt undefined
          inputSelectObject[ parts[0] ][ parts[1] ] = param[ key ]
          delete param[ key ]

    # set new object params
    for key of inputSelectObject
      param[ key ] = inputSelectObject[ key ]

    # data type conversion
    for key of param

      # get {business_hours}
      if key.substr(0,16) is '{business_hours}'
        newKey = key.substr(16, key.length)
        if lookupForm.find("[data-name=\"#{newKey}\"]").hasClass('is-hidden')
          param[newKey] = null
        else if param[key]
          newParams = {}
          for day, value of param[key]
            newParams[day] = {}
            newParams[day].active = false
            if value.active is 'true'
              newParams[day].active = true
            newParams[day].timeframes = []
            if _.isArray(value.start)
              for pos of value.start
                newParams[day].timeframes.push [ value.start[pos], value.end[pos] ]
            else
              newParams[day].timeframes.push [ value.start, value.end ]
          param[newKey] = newParams
        else
          param[newKey] = undefined
        delete param[key]

    #App.Log.notice 'ControllerForm', 'formParam', form, param
    param

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

  @disable: (form, type = 'form') ->
    lookupForm = @findForm(form)

    if lookupForm && type is 'form'
      if lookupForm.is('button, input, select, textarea, div, span')
        App.Log.debug 'ControllerForm', 'disable item...', lookupForm
        lookupForm.prop('readonly', true)
        lookupForm.prop('disabled', true)
        return
      App.Log.debug 'ControllerForm', 'disable form...', lookupForm

      # set forms to read only during communication with backend
      lookupForm.find('button, input, select, textarea').prop('readonly', true)

      # disable radio and checkbox buttons
      lookupForm.find('input[type=checkbox], input[type=radio]').prop('disabled', true)

      # disable additionals submits
      lookupForm.find('button').prop('disabled', true)
    else
      App.Log.debug 'ControllerForm', 'disable item...', form
      form.prop('readonly', true)
      form.prop('disabled', true)

  @enable: (form, type = 'form') ->

    lookupForm = @findForm(form)

    if lookupForm && type is 'form'
      if lookupForm.is('button, input, select, textarea, div, span')
        App.Log.debug 'ControllerForm', 'disable item...', lookupForm
        lookupForm.prop('readonly', false)
        lookupForm.prop('disabled', false)
        return
      App.Log.debug 'ControllerForm', 'enable form...', lookupForm

      # enable fields again
      lookupForm.find('button, input, select, textarea').prop('readonly', false)

      # enable radio and checkbox buttons
      lookupForm.find('input[type=checkbox], input[type=radio]').prop('disabled', false)

      # enable submits again
      lookupForm.find('button').prop('disabled', false)
    else
      App.Log.debug 'ControllerForm', 'enable item...', form
      form.prop('readonly', false)
      form.prop('disabled', false)

  @validate: (data) ->

    lookupForm = @findForm(data.form)

    # remove all errors
    lookupForm.find('.has-error').removeClass('has-error')
    lookupForm.find('.help-inline').html('')

    # show new errors
    for key, msg of data.errors

      # generic validation
      itemGeneric = lookupForm.find('[name="' + key + '"]').closest('.form-group')
      itemGeneric.addClass('has-error')
      itemGeneric.find('.help-inline').html(msg)

      # use meta fields
      itemMeta = lookupForm.find('[data-name="' + key + '"]').closest('.form-group')
      itemMeta.addClass('has-error')
      itemMeta.find('.help-inline').html(msg)

      # use native fields
      itemGeneric = lookupForm.find('[name="' + key + '"]').closest('.form-control')
      itemGeneric.trigger('validate')
      itemMeta = lookupForm.find('[data-name="' + key + '"]').closest('.form-control')
      itemMeta.trigger('validate')

    # set autofocus by delay to make validation testable
    App.Delay.set(
      ->
        lookupForm.find('.has-error').find('input, textarea, select').first().focus()
      200
      'validate'
    )
