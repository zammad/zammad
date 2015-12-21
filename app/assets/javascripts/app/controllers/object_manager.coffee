# coffeelint: disable=duplicate_key
class Index extends App.ControllerTabs
  header: 'Object Manager'
  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @title 'Objects', true

    # get data
    @startLoading()
    @ajax(
      id:    'object_manager_attributes_list'
      type:  'GET'
      url:   @apiPath + '/object_manager_attributes_list'
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        @build(data.objects)
    )

  build: (objects) =>
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

class Items extends App.ControllerContent
  events:
    'click [data-type="delete"]': 'destroy'
    'click .js-up':               'move'
    'click .js-down':             'move'
    'click .js-new':              'new'
    'click .js-edit':             'edit'

  constructor: ->
    super
    # check authentication
    return if !@authenticate()

    @subscribeId = App.ObjectManagerAttribute.subscribe(@render)
    App.ObjectManagerAttribute.fetch()

    # ajax call

  release: =>
    if @subscribeId
      App.ObjectManagerAttribute.unsubscribe(@subscribeId)

  render: =>
    items = App.ObjectManagerAttribute.search(
      filter:
        object: @object
      sortBy: 'position'
    )

    @html App.view('object_manager/index')(
      head:  @object
      items: items
    )


    ###
    new App.ControllerTable(
      el:         @el.find('.table-overview')
      model:      App.ObjectManagerAttribute
      objects:    objects
      bindRow:
        events:
          'click': @edit
    )
    ###

  move: (e) =>
    e.preventDefault()
    e.stopPropagation()
    id        = $( e.target ).closest('tr').data('id')
    direction = 'up'
    if $( e.target ).hasClass('js-down')
      direction = 'down'
    console.log('M', id, direction)

    items = App.ObjectManagerAttribute.search(
      filter:
        object: @object
      sortBy: 'position'
    )
    count = 0
    for item in items
      if item.id is id
        if direction is 'up'
          itemToMove = items[ count - 1 ]
        else
          itemToMove = items[ count + 1 ]
        if itemToMove
          movePosition = itemToMove.position
          if movePosition is item.position
            if direction is 'up'
              movePosition -= 1
            else
              movePosition += 1
          itemToMove.position = item.position
          itemToMove.save()
          console.log(itemToMove, itemToMove.position, count)
          item.position = movePosition
          item.save()
          console.log(item, movePosition, count)
      count += 1

  new: (e) =>
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        title:     'Attribute'
        home:      'object_manager'
        object:    'ObjectManagerAttribute'
        objects:   'ObjectManagerAttributes'
        navupdate: '#object_manager'
      genericObject: 'ObjectManagerAttribute'
      container:     @el.closest('.content')
    )

  edit: (e) =>
    e.preventDefault()
    id = $( e.target ).closest('tr').data('id')
    new Edit(
      pageData:
        object: 'ObjectManagerAttribute'
      genericObject: 'ObjectManagerAttribute'
      callback:      @render
      id:            id
      container:     @el.closest('.content')
    )

  destroy: (e) ->
    e.preventDefault()
    sessionId = $( e.target ).data('session-id')
    @ajax(
      id:    'sessions/' + sessionId
      type:  'DELETE'
      url:   @apiPath + '/sessions/' + sessionId
      success: (data) =>
        @load()
    )

class Edit extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Edit'

  content: =>
    content = $( App.view('object_manager/edit')(
      head:  @object
      items: []
    ) )

    item = App.ObjectManagerAttribute.find(@id)

    options =
      input:    'Text (normal - one line)'
      select:   'Selection'
      datetime: 'Datetime'
      date:     'Date'
      textarea: 'Text (normal - multiline)'
      richtext: 'Text (richtext)'
      checkbox: 'Checkbox'
      boolean:  'Yes/No'

    configureAttributesTop = [
      { name: 'name',       display: 'Name',    tag: 'input',     type: 'text', limit: 100, 'null': false },
      { name: 'display',    display: 'Anzeige', tag: 'input',     type: 'text', limit: 100, 'null': false },
      { name: 'data_type',  display: 'Format',  tag: 'select',    multiple: false, nulloption: true, null: false, options: options, translate: true },
    ]
    controller = new App.ControllerForm(
      model:     { configure_attributes: configureAttributesTop, className: '' },
      params:    item
      #screen:   @screen || 'edit'
      el:        content.find('.js-top')
      autofocus: true
    )

    # input
    configureAttributesInput = [
      { name: 'data_option::type',            display: 'Type',            tag: 'select', multiple: false, nulloption: true, null: false, options: { text: 'text', email: 'email', url: 'url', email: 'email', password: 'password', phone: 'phone'}, translate: true },
      { name: 'data_option::maxlength',       display: 'Max. Length',     tag: 'input',  type: 'text', limit: 100, 'null': false },
      { name: 'data_option::null',            display: 'Required',        tag: 'select', multiple: false, nulloption: false, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::autocapitalize',  display: 'autocapitalize',  tag: 'select', multiple: false, nulloption: true, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::autocomplete',    display: 'autocomplete',    tag: 'select', multiple: false, nulloption: true, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::default',         display: 'Default',         tag: 'input', type: 'text', limit: 100, null: true },
      { name: 'data_option::note',            display: 'Note',            tag: 'input', type: 'text', limit: 100, null: true },
    ]
    controller = new App.ControllerForm(
      model:     { configure_attributes: configureAttributesInput, className: '' },
      params:    item
      el:        content.find('.js-input')
      autofocus: true
    )

    # textarea
    configureAttributesTextarea = [
      { name: 'data_option::maxlength',       display: 'Max. Length',     tag: 'input',  type: 'text', limit: 100, null: false },
      { name: 'data_option::null',            display: 'Required',        tag: 'select', multiple: false, nulloption: false, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::autocapitalize',  display: 'autocapitalize',  tag: 'select', multiple: false, nulloption: true, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::note',            display: 'autocomplete',    tag: 'input',  type: 'text', limit: 100, null: true },
    ]
    controller = new App.ControllerForm(
      model:     { configure_attributes: configureAttributesTextarea, className: '' },
      params:    item
      el:        content.find('.js-textarea')
      autofocus: true
    )

    # select
    configureAttributesSelect = [
      { name: 'data_option::nulloption',      display: 'Empty Selection', tag: 'select', multiple: false, nulloption: false, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::null',            display: 'Required',        tag: 'boolean', multiple: false, nulloption: false, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::relation',        display: 'Relation',        tag: 'input',  type: 'text', limit: 100, null: true },
      { name: 'data_option::options',         display: 'Options',         tag: 'hash',   multiple: true, null: false },
      { name: 'data_option::translate',       display: 'Übersetzen',      tag: 'select', multiple: false, nulloption: false, null: false, options: { true: 'No', false: 'Yes' }, translate: true },
      { name: 'data_option::note',            display: 'Note',            tag: 'input',  type: 'text', limit: 100, null: true },
    ]
    controller = new App.ControllerForm(
      model:      { configure_attributes: configureAttributesSelect, className: '' },
      params:     item
      el:         content.find('.js-select')
      autofocus:  true
    )

    ###
        :options => {
          'Incident' => 'Incident',
          'Problem'  => 'Problem',
          'Request for Change' => 'Request for Change',
        },
    ###

    content.find('[name=data_type]').on(
      'change',
      (e) ->
        dataType = $( e.target ).val()
        content.find('.js-middle > div').addClass('hide')
        content.find(".js-#{dataType}").removeClass('hide')
    )
    content.find('[name=data_type]').trigger('change')


    configureAttributesBottom = [
      { name: 'active', display: 'Active', tag: 'active', default: true },
    ]
    controller = new App.ControllerForm(
      model:   { configure_attributes: configureAttributesBottom, className: '' },
      params:  item
      #screen: @screen || 'edit'
      el:      content.find('.js-bottom')
    )

    controller.form

App.Config.set( 'SystemObject', { prio: 1700, parent: '#system', name: 'Objects', target: '#system/object_manager', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
