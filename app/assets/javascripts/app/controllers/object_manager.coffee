# coffeelint: disable=duplicate_key
treeParams = (e, params) ->
  tree = []
  lastLevels = []
  previousValueLevels = []

  $(e.target).closest('.modal').find('.js-treeTable .js-key').each( ->
    $element = $(@)
    level = parseInt($element.attr('level'))
    name = $element.val().trim()
    item =
      name: name

    if level is 0
      tree.push item
    else if lastLevels[level-1]
      lastLevels[level-1].children ||= []
      lastLevels[level-1].children.push item
    else
      console.log('ERROR', item)

    valueLevels = []
    # add previous level values
    if level > 0
      for previousLevel in [0..level - 1]
        valueLevels.push(previousValueLevels[previousLevel])

    # add current level value
    valueLevels.push(name)

    item.value = valueLevels.join('::')
    lastLevels[level] = item
    previousValueLevels = valueLevels

  )
  if tree[0]
    if !params.data_option
      params.data_option = {}
    params.data_option.options = tree
  params

multiselectParams = (params) ->
  return params if !params.data_type || params.data_type isnt 'multiselect'

  if typeof params.data_option.default is 'string'
    params.data_option.default = new Array(params.data_option.default)
  params

setSelectDefaults = (el) ->
  data_type = el.find('select[name=data_type]').val()
  return if !/^((multi)?select|multi_tree_select)$/.test(data_type) && data_type isnt 'boolean'

  el.find('.js-value, .js-valueTrue, .js-valueFalse').each(->
    element = $(@)
    return true if element.val()

    if element.hasClass('js-valueTrue') || element.hasClass('js-valueFalse')
      element.val(element.attr('placeholder'))
    else
      key_value = element.closest('tr').find('.js-key').val()
      element.val(key_value)
  )

customsortDataOptions = ({target}, params) ->
  return params if !params.data_option || params.data_option.customsort isnt 'on'

  options = []
  $(target).closest('.modal').find('table.js-Table tr.input-data-row').each( ->
    $element = $(@)
    name = $element.find('input.js-value').val().trim()
    value = $element.find('input.js-key').val().trim()
    options.push({name, value})
  )
  params.data_option.options = options
  params

class ObjectManager extends App.ControllerTabs
  requiredPermission: 'admin.object'
  constructor: ->
    super

    # get data
    @startLoading()
    @ajax(
      id:    'object_manager_attributes_list'
      type:  'GET'
      url:   "#{@apiPath}/object_manager_attributes_list"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        @build(data.objects)
    )

  build: (objects) =>
    App.ObjectManagerAttribute.fetchFull(=>
      @tabs = []
      for object in objects
        item =
          name:       object
          target:     "c-#{object}"
          controller: Items
          params:
            object: object
        @tabs.push item

      @render()
    )

class Items extends App.ControllerSubContent
  header: __('Object Manager')
  events:
    'click .js-delete':  'destroy'
    'click .js-new':     'new'
    'click .js-edit':    'edit'
    'click .js-discard': 'discard'
    'click .js-execute': 'execute'

  constructor: ->
    super
    @subscribeId = App.ObjectManagerAttribute.subscribe(@render)
    @render()

  release: =>
    if @subscribeId
      App.ObjectManagerAttribute.unsubscribe(@subscribeId)

  render: =>
    items = App.ObjectManagerAttribute.search(
      filter:
        object: @object
      sortBy: 'position'
    )

    itemsToChange = []
    for item in App.ObjectManagerAttribute.search(sortBy: 'object')
      if item.to_create is true || item.to_delete is true || item.to_migrate is true || item.to_config is true
        itemsToChange.push item

    @html App.view('object_manager/index')(
      head:          @object
      items:         items
      itemsToChange: itemsToChange
    )

  new: (e) =>
    e.preventDefault()
    new New(
      pageData:
        head:      @object
        title:     __('Attribute')
        home:      'object_manager'
        object:    'ObjectManagerAttribute'
        objects:   'ObjectManagerAttributes'
        navupdate: '#object_manager'
      genericObject: 'ObjectManagerAttribute'
      container:     @el.closest('.content')
      item:
        object: @object
    )

  edit: (e) =>
    e.preventDefault()
    id = $(e.target).closest('tr').data('id')
    new Edit(
      pageData:
        head:      @object
        title:     __('Attribute')
        home:      'object_manager'
        object:    'ObjectManagerAttribute'
        objects:   'ObjectManagerAttributes'
        navupdate: '#object_manager'
      genericObject: 'ObjectManagerAttribute'
      container:     @el.closest('.content')
      callback:      @render
      id:            id
    )

  destroy: (e) ->
    e.stopPropagation()
    e.preventDefault()
    id   = $(e.target).closest('tr').data('id')
    item = App.ObjectManagerAttribute.find(id)
    ui = @
    @ajax(
      id:    "object_manager_attributes/#{id}"
      type:  'DELETE'
      url:   "#{@apiPath}/object_manager_attributes/#{id}"
      success: (data) =>
        @render()
      error: (jqXHR, textStatus, errorThrown) ->
        ui.log 'errors'
        # this code is unreachable so alert will do fine
        alert(jqXHR.responseJSON.error)
    )

  discard: (e) ->
    e.preventDefault()
    @ajax(
      id:    'object_manager_attributes_discard_changes'
      type:  'POST'
      url:   "#{@apiPath}/object_manager_attributes_discard_changes"
      success: (data) =>
        @render()
    )

  execute: (e) ->
    e.preventDefault()
    @ajax(
      id:    'object_manager_attributes_execute_migrations'
      type:  'POST'
      url:   "#{@apiPath}/object_manager_attributes_execute_migrations"
      success: (data) =>
        @render()
    )

class New extends App.ControllerGenericNew

  onSubmit: (e) =>
    setSelectDefaults(@el)

    params = @formParam(e.target)
    params = treeParams(e, params)
    params = multiselectParams(params)
    params = customsortDataOptions(e, params)

    # show attributes for create_middle in two column style
    if params.screens && params.screens.create_middle
      for role, value of params.screens.create_middle
        value.item_class = 'column'

    params.object = @pageData.head
    object = new App[@genericObject]
    object.load(params)

    # validate
    errors = object.validate()
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    # disable form
    @formDisable(e)

    # save object
    ui = @
    object.save(
      done: ->
        if ui.callback
          item = App[ui.genericObject].fullLocal(@id)
          ui.callback(item)
        ui.close()

      fail: (settings, details) ->
        ui.log 'errors', details
        ui.formEnable(e)
        ui.controller.showAlert(details.error_human || details.error || __('The object could not be created.'))
    )

class Edit extends App.ControllerGenericEdit

  content: =>
    @item = App[@genericObject].find(@id)
    @head = @pageData.head || @pageData.object

    # set disabled attributes
    configure_attributes = clone(App[@genericObject].configure_attributes)
    for attribute in configure_attributes
      if attribute.name is 'name'
        attribute.disabled = true
      #if attribute.name is 'data_type'
      #  attribute.disabled = true

    @controller = new App.ControllerForm(
      model:
        configure_attributes: configure_attributes
      params:     @item
      screen:     @screen || 'edit'
      autofocus:  true
    )
    @controller.form

  onSubmit: (e) =>
    setSelectDefaults(@el)

    params = @formParam(e.target)
    params = treeParams(e, params)
    params = multiselectParams(params)
    params = customsortDataOptions(e, params)

    # show attributes for create_middle in two column style
    if params.screens && params.screens.create_middle
      for role, value of params.screens.create_middle
        value.item_class = 'column'

    params.object = @pageData.head
    @item.load(params)

    # validate
    errors = @item.validate(
      controllerForm: @controller
    )
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    # disable form
    @formDisable(e)

    # save object
    ui = @
    @item.save(
      done: ->
        if ui.callback
          item = App[ui.genericObject].fullLocal(@id)
          ui.callback(item)
        ui.close()

      fail: (settings, details) ->
        ui.log 'errors'
        ui.formEnable(e)
        ui.controller.showAlert(details.error_human || details.error || __('The object could not be updated.'))
    )

App.Config.set('SystemObject', { prio: 1700, parent: '#system', name: __('Objects'), target: '#system/object_manager', controller: ObjectManager, permission: ['admin.object'] }, 'NavBarAdmin')
