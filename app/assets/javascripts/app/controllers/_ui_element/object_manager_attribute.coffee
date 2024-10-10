
# coffeelint: disable=camel_case_classes
class App.UiElement.object_manager_attribute extends App.UiElement.ApplicationUiElement
  @render: (attribute, params = {}) ->

    # if we have already changed settings, use them in edit screen
    if params.data_option_new && !_.isEmpty(params.data_option_new)
      params.data_option = params.data_option_new

    if /^(multi)?select$/.test(attribute.value) && params.data_option? && params.data_option.options?
      params.data_option.mapped = @mapDataOptions(params.data_option)

    item = $(App.view('object_manager/attribute')(attribute: attribute))

    updateDataMap = (localParams, localAttribute, localAttributes, localClassname, localForm, localA) =>
      return if !localParams.data_type
      element = $(App.view("object_manager/attribute/#{localParams.data_type}")(
        attribute: attribute
        params: params
      ))
      @[localParams.data_type](element, localParams, params, attribute)
      localItem = localForm.closest('.js-data')
      localItem.find('.js-dataMap').html(element)
      localItem.find('.js-dataScreens').html(@dataScreens(attribute, localParams, params))
      callback = undefined
      if @["#{localParams.data_type}_callback"]
        callback = @["#{localParams.data_type}_callback"]

      @addDragAndDrop(localItem, callback)

    options = [
      {
        name: __('Text field'),
        value: 'input',
      },
      {
        name: __('Textarea field'),
        value: 'textarea',
      },
      {
        name: __('Boolean field'),
        value: 'boolean',
      },
      {
        name: __('Integer field'),
        value: 'integer',
      },
      {
        name: __('Date field'),
        value: 'date',
      },
      {
        name: __('Date & time field'),
        value: 'datetime',
      },
      {
        name: __('Single selection field'),
        value: 'select',
      },
      {
        name: __('Multiple selection field'),
        value: 'multiselect',
      },
      {
        name: __('Single tree selection field'),
        value: 'tree_select',
      },
      {
        name: __('Multiple tree selection field'),
        value: 'multi_tree_select',
      },
      {
        name: __('External data source field'),
        value: 'autocompletion_ajax_external_data_source',
        filterCallback: -> App.Config.get('column_type_json_supported')
      },
    ]

    # if attribute already exists, do not allow to change it anymore
    if params.data_type
      options = _.filter(options, (option) -> option.value is params.data_type)
      attribute.disabled = true

    # Filter out unsupported options by executing an optional callback.
    filterOptions = (options) -> _.filter(options, (option) ->
      return option.filterCallback() if typeof option.filterCallback is 'function'

      true
    )

    configureAttributes = [
      { name: attribute.name, display: '', tag: 'select', null: false, options: options, translate: true, default: 'input', disabled: attribute.disabled, filter: filterOptions },
    ]
    dataType = new App.ControllerForm(
      el: item.find('.js-dataType')
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      handlers: [
        updateDataMap,
      ]
      params: params
    )
    item.find('.js-boolean').data('field-type', 'boolean')
    item.find('.js-dataType [name="data_type"]').trigger('change')
    item

  @dataScreens: (attribute, localParams, params) ->
    # TODO: find a better place for these translation markers, since they are used only in keys below!
    #   __('shown')
    #   __('required')
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

  @addOptionTranslate: (item, params) ->
    params.data_option ||= {}
    if params.data_option.translate is undefined
      params.data_option.translate = false

    configureAttributes = [
      { name: 'data_option::translate', display: __('Translate field contents'), tag: 'boolean', null: true, default: false },
    ]
    inputTranslate = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputTranslate').html(inputTranslate.form)

  @input: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: __('Default'), tag: 'input', type: 'text', null: true, default: '' },
    ]
    inputDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::type', display: __('Type'), tag: 'select', null: false, default: 'text', options: {text: __('Text'), tel: 'Phone', email: 'Email', url: 'Url'}, translate: true },
    ]
    inputType = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::maxlength', display: __('Max. length'), tag: 'integer', null: false, default: 120 },
    ]
    inputMaxlength = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      # coffeelint: disable=no_interpolation_in_single_quotes
      { name: 'data_option::linktemplate', display: __('Link template'), tag: 'input', type: 'text', null: true, default: '', placeholder: __('https://example.com/?q=#{object.attribute_name} - use ticket, user or organization as object') },
      # coffeelint: enable=no_interpolation_in_single_quotes
    ]
    inputLinkTemplate = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputDefault').html(inputDefault.form)
    item.find('.js-inputType').html(inputType.form)
    item.find('.js-inputMaxlength').html(inputMaxlength.form)
    item.find('.js-inputLinkTemplate').html(inputLinkTemplate.form)

    item.find("select[name='data_option::type']").on('change', (e) ->
      value = $(e.target).val()
      if value is 'url'
        inputLinkTemplate.hide('data_option::linktemplate', undefined, true)
      else
        inputLinkTemplate.show('data_option::linktemplate')
    )
    item.find("select[name='data_option::type']").trigger('change')

  @textarea: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: __('Default'), tag: 'input', type: 'text', null: true, default: '' },
    ]
    inputDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::maxlength', display: __('Max. length'), tag: 'integer', null: false, default: 500 },
    ]
    inputMaxlength = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::rows', display: __('Rows'), tag: 'integer', null: false, default: 4 },
    ]
    inputRows = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )

    item.find('.js-inputDefault').html(inputDefault.form)
    item.find('.js-inputMaxlength').html(inputMaxlength.form)
    item.find('.js-inputRows').html(inputRows.form)

  @datetime: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::future', display: __('Allow future'), tag: 'boolean', null: false, default: true },
    ]
    datetimeFuture = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::past', display: __('Allow past'), tag: 'boolean', null: false, default: true },
    ]
    datetimePast = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::diff', display: __('Default time diff (minutes)'), tag: 'integer', null: true },
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
      { name: 'data_option::diff', display: __('Default time diff (hours)'), tag: 'integer', null: true },
    ]
    dateDiff = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-dateDiff').html(dateDiff.form)

  @integer: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: __('Default'), tag: 'integer', null: true, default: '', min: 1 },
    ]
    integerDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::min', display: __('Minimal'), tag: 'integer', null: false, default: 0, min: -2147483647, max: 2147483647 },
    ]
    integerMin = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::max', display: __('Maximal'), tag: 'integer', null: false, min: -2147483647, max: 2147483647, default: 999999999 },
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
    configureAttributes = [
      # coffeelint: disable=no_interpolation_in_single_quotes
      { name: 'data_option::linktemplate', display: __('Link template'), tag: 'input', type: 'text', null: true, default: '', placeholder: 'https://example.com/?q=#{ticket.attribute_name}' },
      # coffeelint: enable=no_interpolation_in_single_quotes
    ]
    inputLinkTemplate = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputLinkTemplate').html(inputLinkTemplate.form)
    @addOptionTranslate(item, params)

  @multiselect: (item, localParams, params) ->
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
    configureAttributes = [
      # coffeelint: disable=no_interpolation_in_single_quotes
      { name: 'data_option::linktemplate', display: 'Link-Template', tag: 'input', type: 'text', null: true, default: '', placeholder: 'https://example.com/?q=#{ticket.attribute_name}' },
      # coffeelint: enable=no_interpolation_in_single_quotes
    ]
    inputLinkTemplate = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputLinkTemplate').html(inputLinkTemplate.form)
    @addOptionTranslate(item, params)

  @setRowLevel: (element, level) ->
    reorderElement = element.find('td:nth-child(1)')
    reorderElement.css('padding-left', "#{(level * 20) + 10}px")
    reorderElement.closest('tr').attr('level', level)
    element.find('.js-key').attr('level', level)
    element.find('td:nth-child(2)').first().css('padding-left', "#{(level * 20) + 10}px")

  @buildRow: (element, child, level = 0, parentElement) ->
    newRow = element.find('.js-template').clone().removeClass('js-template')
    newRow.find('.js-key').attr('level', level)
    newRow.find('.js-key').val(child.name)
    @setRowLevel(newRow, level)
    if level is 5
      newRow.find('.js-addChild').addClass('hide')

    if parentElement
      parentElement.after(newRow)
      return

    element.find('.js-treeTable').append(newRow)
    if child.children
      for subChild in child.children
        @buildRow(element, subChild, level + 1)

  @findParent: (element, level, mode) ->
    parent = $(element).closest('tr')
    parent.nextAll().each(->
      if parseInt($(@).find('.js-key').attr('level')) > level && mode is 'first'
        parent = $(@)
        return true
      if parseInt($(@).find('.js-key').attr('level')) >= level && mode is 'last'
        parent = $(@)
        return true
      return false
    )

    return parent

  @multi_tree_select: (item, localParams, params, attribute) =>
    @tree_select(item, localParams, params, attribute)

  @multi_tree_select_callback: (event, ui) =>
    @tree_select_callback(event, ui)

  @tree_select: (item, localParams, params, attribute) ->
    item.find('td.table-draggable').attr('title', App.i18n.translateInline('Use double click to change level of the row.'))

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
      level  = parseInt($(e.currentTarget).closest('tr').find('.js-key').attr('level'))
      addRow = @findParent(e.currentTarget, level, 'first')
      @buildRow(item, {}, level, addRow)
    )

    item.on('click', '.js-addChild', (e) =>
      e.stopPropagation()
      e.preventDefault()
      level  = parseInt($(e.currentTarget).closest('tr').find('.js-key').attr('level')) + 1
      addRow = @findParent(e.currentTarget, level, 'last')
      @buildRow(item, {}, level, addRow)
    )

    item.on('click', '.js-remove', (e) =>
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

      @ensureOneOption(item)
    )

    if item.find('.js-addChild').length > 0
      setRowLevel      = @setRowLevel
      fixUnalignedRows = @fixUnalignedRows
      item.on('dblclick', '.icon-draggable', ->
        row       = $(@).closest('tr')
        itemLevel = parseInt(row.attr('level'))        || 0
        prevLevel = parseInt(row.prev().attr('level')) || 0

        if itemLevel + 1 <= prevLevel + 1
          nextLevel = itemLevel + 1
        else
          nextLevel = 0

        setRowLevel(row, nextLevel)
        fixUnalignedRows(item.find('tbody.table-sortable tr'))
      )
      @addOptionTranslate(item, params)

  @tree_select_callback: (event, ui) =>

    # align row with the last element
    row = ui.item.first()
    rowPrevLevel = parseInt(row.prev().attr('level')) || 0
    @setRowLevel(row, rowPrevLevel)

    # fix unaligned elements
    items = row.closest('tbody').find('tr')
    @fixUnalignedRows(items)

  @fixUnalignedRows: (items) =>
    setRowLevel  = @setRowLevel
    allowedLevel = [0]
    items.each(->
      itemLevel = parseInt($(@).attr('level')) || 0
      prevRow   = $(@).prev()
      prevLevel = parseInt(prevRow.attr('level')) || 0

      # always fix first row to 0
      return setRowLevel($(@), 0) if prevRow.length == 0

      # allow all upper levels which happend before and the next depth level
      if itemLevel == 0 || itemLevel == allowedLevel[allowedLevel.length - 1] + 1 || _.contains(allowedLevel, itemLevel)

        # reset allowed levels if the depth goes up
        if itemLevel < prevLevel
          allowedLevel = _.range(itemLevel + 1)

        # add item level if not set
        if !_.contains(allowedLevel, itemLevel)
          allowedLevel.push(itemLevel)

        # goto next element (row level is allowed)
        return true

      # row level is not allowed, so set the level of th previous row
      setRowLevel($(@), Math.max(prevLevel, Math.min(prevLevel + 1, itemLevel)))
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
    @addOptionTranslate(item, params)

  @autocompletion: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: __('Default'), tag: 'input', type: 'text', null: true, default: '' },
    ]
    autocompletionDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::url', display: __('URL (AJAX endpoint)'), tag: 'input', type: 'url', null: false, default: '', placeholder: 'https://example.com/serials' },
    ]
    autocompletionUrl = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::method', display: __('Method (AJAX endpoint)'), tag: 'input', type: 'url', null: false, default: '', placeholder: __('GET') },
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

  @autocompletion_ajax_external_data_source: (item, localParams, params) ->
    configureAttributes = [
      # coffeelint: disable=no_interpolation_in_single_quotes
      { name: 'data_option::search_url', display: __('Search URL'), tag: 'input', type: 'text', null: false, default: '', placeholder: 'https://example.com/search?query=#{search.term}' },
      # coffeelint: disable=no_interpolation_in_single_quotes
    ]
    inputSearchURL = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputSearchURL').html(inputSearchURL.form)

    configureAttributes = [
      { name: 'data_option::verify_ssl', display: __('SSL verification'), tag: 'boolean', null: true, default: true, translate: true, },
    ]
    inputSSLVerify = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputSSLVerify').html(inputSSLVerify.form)

    toggleSslVerifyAlert = (e) ->
      elem           = $(e.target)
      isAlertVisible = elem.val() != 'true'

      elem.closest('.js-dataOption').find('.js-sslVerifyAlert').toggleClass('hide', !isAlertVisible)

    item.find('select[name="data_option::verify_ssl"]')
      .off('change.toggleSslVerifyAlert').on('change.toggleSslVerifyAlert', toggleSslVerifyAlert)

    toggleSslVerifyAlert(target: item.find('select[name="data_option::verify_ssl"]'))

    configureAttributes = [
      { name: 'data_option::http_auth_type', display: __('HTTP Authentication'), tag: 'select', null: true, nulloption: true, default: '', options: { basic_auth: __('Basic Authentication'), bearer_token: __('Authentication Token') }, translate: true },
    ]

    inputHTTPAuthType = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputHTTPAuthType').html(inputHTTPAuthType.form)

    configureAttributes = [
      { name: 'data_option::http_basic_auth_username', display: __('HTTP Basic Authentication username'), tag: 'input', type: 'text', null: true, default: '', placeholder: '' },
    ]
    inputHTTPBasicAuthUsername = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputHTTPBasicAuthUsername').html(inputHTTPBasicAuthUsername.form)

    configureAttributes = [
      { name: 'data_option::http_basic_auth_password', display: __('HTTP Basic Authentication password'), tag: 'input', type: 'text', null: true, default: '', placeholder: '' },
    ]
    inputHTTPBasicAuthPassword = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputHTTPBasicAuthPassword').html(inputHTTPBasicAuthPassword.form)

    configureAttributes = [
      { name: 'data_option::bearer_token_auth', display: __('HTTP Authentication token'), tag: 'input', type: 'text', null: true, default: '', placeholder: '' },
    ]
    inputBearerTokenAuth = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputBearerTokenAuth').html(inputBearerTokenAuth.form)

    toggleHTTPAuthFields = (value) ->
      switch value
        when 'basic_auth'
          inputHTTPBasicAuthUsername.show('data_option::http_basic_auth_username')
          inputHTTPBasicAuthPassword.show('data_option::http_basic_auth_password')
          inputHTTPBasicAuthPassword.show('data_option::http_basic_auth_password_confirm')
          inputBearerTokenAuth.hide('data_option::bearer_token_auth', undefined, true)
        when 'bearer_token'
          inputHTTPBasicAuthUsername.hide('data_option::http_basic_auth_username', undefined, true)
          inputHTTPBasicAuthPassword.hide('data_option::http_basic_auth_password', undefined, true)
          inputHTTPBasicAuthPassword.hide('data_option::http_basic_auth_password_confirm', undefined, true)
          inputBearerTokenAuth.show('data_option::bearer_token_auth')
        else
          inputHTTPBasicAuthUsername.hide('data_option::http_basic_auth_username', undefined, true)
          inputHTTPBasicAuthPassword.hide('data_option::http_basic_auth_password', undefined, true)
          inputHTTPBasicAuthPassword.hide('data_option::http_basic_auth_password_confirm', undefined, true)
          inputBearerTokenAuth.hide('data_option::bearer_token_auth', undefined, true)

    item.find("select[name='data_option::http_auth_type']").on('change', (e) ->
      value = $(e.target).val()
      toggleHTTPAuthFields(value)
    )

    toggleHTTPAuthFields(params?.data_option?.http_auth_type)

    configureAttributes = [
      { name: 'data_option::search_result_list_key', display: __('Search result list key'), tag: 'input', type: 'text', null: true, default: '', placeholder: '' },
    ]
    inputSearchResultListKey = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputSearchResultListKey').html(inputSearchResultListKey.form)

    configureAttributes = [
      { name: 'data_option::search_result_value_key', display: __('Search result value key'), tag: 'input', type: 'text', null: true, default: '', placeholder: '' },
    ]
    inputSearchResultValueKey = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputSearchResultValueKey').html(inputSearchResultValueKey.form)

    configureAttributes = [
      { name: 'data_option::search_result_label_key', display: __('Search result label key'), tag: 'input', type: 'text', null: true, default: '', placeholder: '' },
    ]
    inputSearchResultLabelKey = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputSearchResultLabelKey').html(inputSearchResultLabelKey.form)

    configureAttributes = [
      # coffeelint: disable=no_interpolation_in_single_quotes
      { name: 'data_option::linktemplate', display: __('Link template'), tag: 'input', type: 'text', null: true, default: '', placeholder: 'https://example.com/?q=#{ticket.attribute_name}' },
      # coffeelint: disable=no_interpolation_in_single_quotes
    ]
    inputLinkTemplate = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputLinkTemplate').html(inputLinkTemplate.form)

    configureAttributes = [
      { id: 'inputSearchTerm', name: 'query', display: __('Preview'), tag: 'input', type: 'text', null: true, default: '', placeholder: __('Search…') },
    ]
    inputSearchTerm = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
    )
    item.find('.js-inputSearchTerm').html(inputSearchTerm.form)

    debouncedPreviewExternalDataSource = _.debounce(@previewExternalDataSource, 300)

    item.off('input.previewExternalDataSource').on('input.previewExternalDataSource', (e) ->
      debouncedPreviewExternalDataSource(e, params.object)
    )

  @previewExternalDataSource: (e, object) =>
    item = $(e.target).closest('.js-dataMap')

    @resetExternalDataSourcePreview(item)

    params = App.ControllerForm.params($(e.target).closest('form'))

    return if not params.query?.trim()

    item.find('.js-previewInfo')
      .addClass('hide')

    item.find('.js-loading')
      .removeClass('hide')

    data = _.extend({},
      data_option: params.data_option,
      query: params.query,
      limit: 10,
    )

    App.Ajax.request(
      id:   'previewExternalDataSource'
      type: 'POST'
      url:  "#{App.Config.get('api_path')}/external_data_source/preview"
      data: JSON.stringify(data)
      success: ({ data, parsed_items, response_body, success, error }, status, xhr) ->
        item.find('.js-loading')
          .addClass('hide')

        if response_body
          configureAttributes = [
            { id: 'searchResultResponse', name: 'search_result_response', display: __('Search result response'), tag: 'code_editor', null: true, disabled: true, lineNumbers: false, height: 160, value: JSON.stringify(response_body, null, 2) },
          ]
          searchResultResponse = new App.ControllerForm(
            model:
              configure_attributes: configureAttributes
            noFieldset: true
          )
          item.find('.js-searchResultResponse').html(searchResultResponse.form)

        if parsed_items
          configureAttributes = [
            { id: 'searchResultList', name: 'search_result_list', display: __('Search result list'), tag: 'code_editor', null: true, disabled: true, lineNumbers: false, height: 160, value: JSON.stringify(parsed_items, null, 2) },
          ]
          searchResultList = new App.ControllerForm(
            model:
              configure_attributes: configureAttributes
            noFieldset: true
          )
          item.find('.js-searchResultList').html(searchResultList.form)

        if data
          table = $('<table class="settings-list settings-list--stretch"><thead><tr /></thead><tbody /></table>')

          if _.isEmpty(data)
            $('<th />')
              .text(App.i18n.translatePlain('No Entries'))
              .appendTo(table.find('thead tr'))

            table.addClass('settings-list--placeholder')

            item.find('.js-searchResultSample').html(table)

          else
            $('<th />')
              .text(App.i18n.translatePlain('Value'))
              .appendTo(table.find('thead tr'))

            $('<th />')
              .text(App.i18n.translatePlain('Label'))
              .appendTo(table.find('thead tr'))

            if params.data_option?.linktemplate
              $('<th />')
                .text(App.i18n.translatePlain('Link'))
                .addClass('centered')
                .appendTo(table.find('thead tr'))

            _.each(data, (searchItem) ->
              resultValue = $('<td />')
                .addClass('search-result-value')
                .text(searchItem.value)

              resultLabel = $('<td />')
                .addClass('search-result-label')
                .text(searchItem.label)

              if params.data_option?.linktemplate
                objects =
                  user: App.Session.get()
                  config: App.Config.all()

                  # NB: Simulate the current attribute to certain extent.
                  "#{object.toLowerCase()}":
                    "#{params.name}":
                      searchItem.value

                link = App.Utils.replaceTags(params.data_option?.linktemplate, objects)

                resultLinkIcon = $(App.Utils.icon('external'))
                resultLinkAnchor = $('<a />')
                  .addClass('settings-list-control')
                  .attr('href', link)
                  .attr('target', '_blank')
                  .append(resultLinkIcon)
                resultLink = $('<td />')
                  .addClass('search-result-link settings-list-controls')
                  .append(resultLinkAnchor)
              else
                $('<span />')
                  .text(searchItem.label)

              $('<tr />')
                .attr('data-id', searchItem.value)
                .append(resultValue)
                .append(resultLabel)
                .append(resultLink)
                .appendTo(table.find('tbody'))
            )

            item.find('.js-searchResultSample').html(table)

        if not success
          item.find('.js-previewError')
            .text(App.i18n.translatePlain(error))
            .removeClass('hide')

      error: (data, status, message) ->
        item.find('.js-previewError')
          .text(App.i18n.translatePlain('An error occurred: %s', message))
          .removeClass('hide')

        item.find('.js-loading')
          .addClass('hide')
    )

  @resetExternalDataSourcePreview: (item) ->
    item.find('.js-searchResultResponse')
      .empty()
    item.find('.js-searchResultList')
      .empty()
    item.find('.js-searchResultSample')
      .empty()
    item.find('.js-previewError')
      .addClass('hide')
    item.find('.js-loading')
      .addClass('hide')
    item.find('.js-previewInfo')
      .removeClass('hide')

  @addDragAndDrop: (item, callback) ->
    dndOptions =
        tolerance:            'pointer'
        distance:             15
        opacity:              0.6
        forcePlaceholderSize: true
        items:                'tr.input-data-row'
        helper: (e, tr) ->
          originals = tr.children()
          helper = tr.clone()
          helper.children().each (index) ->
            # Set helper cell sizes to match the original sizes
            $(@).width( originals.eq(index).outerWidth() )
          return helper
        stop: callback

    item.find('tbody.table-sortable').sortable(dndOptions)

  @mapDataOptions: ({options, customsort}) ->
    if _.isArray(options)
      mappedOptions = options.map(({name, value}) ->
        value = '' if !value || !value.toString
        name = '' if !name || !name.toString
        [value.toString(), name.toString()]
      )
    else
      mappedOptions = _.map(
        options, (value, key) ->
          key = '' if !key || !key.toString
          value = '' if !value || !value.toString
          [key.toString(), value.toString()]
      )
    return mappedOptions if customsort? && customsort is 'on'

    mappedOptions.sort( (a, b) -> a[1].localeCompare(b[1]) )

  @ensureOneOption: (item) ->
    return if $(item).find('tbody tr').length > 1
    @buildRow(item, {})
