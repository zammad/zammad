
# coffeelint: disable=camel_case_classes
class App.UiElement.object_manager_attribute extends App.UiElement.ApplicationUiElement
  @render: (attribute, params = {}) ->

    # if we have already changed settings, use them in edit screen
    if params.data_option_new && !_.isEmpty(params.data_option_new)
      params.data_option = params.data_option_new

    item = $(App.view('object_manager/attribute')(attribute: attribute))

    updateDataMap = (localParams, localAttribute, localAttributes, localClassname, localForm, localA) =>
      localItem = localForm.closest('.js-data')
      element = $(App.view("object_manager/attribute/#{localParams.data_type}")(
        attribute: attribute
        params: params
      ))
      @[localParams.data_type](element, localParams, params, attribute)
      localItem.find('.js-dataMap').html(element)
      localItem.find('.js-dataScreens').html(@dataScreens(attribute, localParams, params))

    options =
      datetime: 'Datetime'
      date: 'Date'
      input: 'Text'
      select: 'Select'
      tree_select: 'Tree Select'
      boolean: 'Boolean'
      integer: 'Integer'

    # if attribute already exists, do not allow to change it anymore
    if params.data_type
      for key, value of options
        if key isnt params.data_type
          delete options[key]

    configureAttributes = [
      { name: attribute.name, display: '', tag: 'select', null: false, options: options, translate: true, default: 'input', disabled: attribute.disabled },
    ]
    dataType = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      handlers: [
        updateDataMap,
      ]
      params: params
    )
    item.find('.js-dataType').html(dataType.form)
    item.find('.js-boolean').data('field-type', 'boolean')
    item

  @dataScreens: (attribute, localParams, params) ->
    object = params.object
    objects =
      Ticket:
        'ticket.customer':
          create_middle:
            shown: true
            required: false
          edit:
            shown: true
            required: false
        'ticket.agent':
          create_middle:
            shown: true
            required: false
          edit:
            shown: true
            required: false
      User:
        'ticket.customer':
          create:
            shown: true
            required: false
          view:
            shown: true
          signup:
            shown: false
            required: false
        'ticket.agent':
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
          invite_customer:
            shown: false
            required: false
        'admin.user':
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
          invite_agent:
            shown: false
            required: false
          invite_customer:
            shown: false
            required: false
      Organization:
        'ticket.customer':
          view:
            shown: true
        'ticket.agent':
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
        'admin.organization':
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
      Group:
        'admin.group':
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
    init = false
    if params && !params.id
      init = true

    data = objects[object]
    if init
      for role, screenOptions of data
        for screen, options of screenOptions
          for key, defaultValue of options
            params.screens ||= {}
            params.screens[screen] ||= {}
            params.screens[screen][role] ||= {}
            params.screens[screen][role][key] = defaultValue

    item = $(App.view('object_manager/screens')(
      attribute: attribute
      data: objects[object]
      params: params
      init: init
    ))
    item.find('.js-boolean').data('field-type', 'boolean')
    item

  @input: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: 'Default', tag: 'input', type: 'text', null: true, default: '' },
    ]
    inputDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::type', display: 'Type', tag: 'select', null: false, default: 'text', options: {text: 'Text', tel: 'Phone', email: 'Email', url: 'Url'}, translate: true },
    ]
    inputType = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::maxlength', display: 'Maxlength', tag: 'integer', null: false, default: 120 },
    ]
    inputMaxlength = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputDefault').html(inputDefault.form)
    item.find('.js-inputType').html(inputType.form)
    item.find('.js-inputMaxlength').html(inputMaxlength.form)

  @datetime: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::future', display: 'Allow future', tag: 'boolean', null: false, default: true },
    ]
    datetimeFuture = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::past', display: 'Allow past', tag: 'boolean', null: false, default: true },
    ]
    datetimePast = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::diff', display: 'Default time Diff (minutes)', tag: 'integer', null: false, default: 24 },
    ]
    datetimeDiff = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-datetimeFuture').html(datetimeFuture.form)
    item.find('.js-datetimePast').html(datetimePast.form)
    item.find('.js-datetimeDiff').html(datetimeDiff.form)

  @date: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::future', display: 'Allow future', tag: 'boolean', null: false, default: true },
    ]
    dateFuture = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::past', display: 'Allow past', tag: 'boolean', null: false, default: true },
    ]
    datePast = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::diff', display: 'Default time Diff (hours)', tag: 'integer', null: false, default: 24 },
    ]
    dateDiff = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-dateFuture').html(dateFuture.form)
    item.find('.js-datePast').html(datePast.form)
    item.find('.js-dateDiff').html(dateDiff.form)

  @integer: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: 'Default', tag: 'integer', null: true, default: '', min: 1 },
    ]
    integerDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::min', display: 'Minimal', tag: 'integer', null: false, default: 0, min: 1 },
    ]
    integerMin = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::max', display: 'Maximal', tag: 'integer', null: false, default: 999999999, min: 2 },
    ]
    integerMax = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-integerDefault').html(integerDefault.form)
    item.find('.js-integerMin').html(integerMin.form)
    item.find('.js-integerMax').html(integerMax.form)

  @select: (item, localParams, params) ->
    item.find('.js-add').on('click', (e) ->
      addRow   = $(e.target).closest('tr')
      key      = addRow.find('.js-key').val()
      value    = addRow.find('.js-value').val()
      addRow.find('.js-selected[value]').attr('value', key)
      selected = addRow.find('.js-selected').prop('checked')
      newRow   = item.find('.js-template').clone().removeClass('js-template')
      newRow.find('.js-key').val(key)
      newRow.find('.js-value').val(value)
      newRow.find('.js-value[value]').attr('name', "data_option::options::#{key}")
      newRow.find('.js-selected').prop('checked', selected)
      newRow.find('.js-selected').val(key)
      newRow.find('.js-selected').attr('name', 'data_option::default')
      item.find('.js-Table tr').last().before(newRow)
      addRow.find('.js-key').val('')
      addRow.find('.js-value').val('')
      addRow.find('.js-selected').prop('checked', false)
    )
    item.on('change', '.js-key', (e) ->
      key = $(e.target).val()
      valueField = $(e.target).closest('tr').find('.js-value[name]')
      valueField.attr('name', "data_option::options::#{key}")
    )
    item.on('click', '.js-remove', (e) ->
      $(e.target).closest('tr').remove()
    )
    lastSelected = undefined
    item.on('click', '.js-selected', (e) ->
      checked = $(e.target).prop('checked')
      value = $(e.target).attr('value')
      if checked && lastSelected && lastSelected is value
        $(e.target).prop('checked', false)
        lastSelected = false
        return
      lastSelected = value
    )

  @buildRow: (element, child, level = 0, parentElement) ->
    newRow = element.find('.js-template').clone().removeClass('js-template')
    newRow.find('.js-key').attr('level', level)
    newRow.find('.js-key').val(child.name)
    newRow.find('td').first().css('padding-left', "#{(level * 20) + 10}px")
    if level is 5
      newRow.find('.js-addChild').addClass('hide')

    if parentElement
      parentElement.after(newRow)
      return

    element.find('.js-treeTable').append(newRow)
    if child.children
      for subChild in child.children
        @buildRow(element, subChild, level + 1)

  @tree_select: (item, localParams, params, attribute) ->
    params.data_option ||= {}
    params.data_option.options ||= []
    if _.isEmpty(params.data_option.options)
      @buildRow(item, {})
    else
      for child in params.data_option.options
        @buildRow(item, child)

    item.on('click', '.js-addRow', (e) =>
      e.stopPropagation()
      e.preventDefault()
      addRow = $(e.currentTarget).closest('tr')
      level  = parseInt(addRow.find('.js-key').attr('level'))
      @buildRow(item, {}, level, addRow)
    )

    item.on('click', '.js-addChild', (e) =>
      e.stopPropagation()
      e.preventDefault()
      addRow = $(e.currentTarget).closest('tr')
      level  = parseInt(addRow.find('.js-key').attr('level')) + 1
      @buildRow(item, {}, level, addRow)
    )

    item.on('click', '.js-remove', (e) ->
      e.stopPropagation()
      e.preventDefault()
      e.stopPro
      element = $(e.target).closest('tr')
      level  = parseInt(element.find('.js-key').attr('level'))
      subElements = 0
      nextElement = element
      elementsToDelete = [element]
      loop
        nextElement = nextElement.next()
        break if !nextElement.get(0)
        nextLevel = parseInt(nextElement.find('.js-key').attr('level'))
        break if nextLevel <= level
        subElements += 1
        elementsToDelete.push nextElement
      return if subElements isnt 0 && !confirm("Delete #{subElements} sub elements?")
      for element in elementsToDelete
        element.remove()
    )

  @boolean: (item, localParams, params) ->
    lastSelected = undefined
    item.on('click', '.js-selected', (e) ->
      checked = $(e.target).prop('checked')
      value = $(e.target).attr('value')
      if checked && lastSelected && lastSelected is value
        $(e.target).prop('checked', false)
        lastSelected = false
        return
      lastSelected = value
    )

  @autocompletion: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: 'Default', tag: 'input', type: 'text', null: true, default: '' },
    ]
    autocompletionDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::url', display: 'Url (AJAX Endpoint)', tag: 'input', type: 'url', null: false, default: '', placeholder: 'https://example.com/serials' },
    ]
    autocompletionUrl = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::method', display: 'Method (AJAX Endpoint)', tag: 'input', type: 'url', null: false, default: '', placeholder: 'GET' },
    ]
    autocompletionMethod = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )

    item.find('.js-autocompletionDefault').html(autocompletionDefault.form)
    item.find('.js-autocompletionUrl').html(autocompletionUrl.form)
    item.find('.js-autocompletionMethod').html(autocompletionMethod.form)
