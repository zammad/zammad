class Index extends App.ControllerTabs
  constructor: ->
    super

    # get data
    @ajax(
      id:    'object_manager_attributes_list',
      type:  'GET',
      url:   @apiPath + '/object_manager_attributes_list',
      processData: true,
      success: (data, status, xhr) =>
        @build(data.objects)
    )

  build: (objects) =>
    @tabs = []
    for object in objects
      item =
        name:       object,
        target:     "c-#{object}",
        controller: Items,
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
    )

  edit: (e) =>
    e.preventDefault()
    id = $( e.target ).closest('tr').data('id')
    new Edit(
      pageData:      {
        object: 'ObjectManagerAttribute'
      },
      genericObject: 'ObjectManagerAttribute'
      callback:       @render
      id:            id
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
  constructor: (params) ->
    super

    @head  = App.i18n.translateContent( 'Edit' )
    @cancel = true
    @button = true

    ###
    controller = new App.ControllerForm(
      model:      App.ObjectManagerAttribute
      params:     @item
      screen:     @screen || 'edit'
      autofocus:  true
    )

    @content = controller.form
    ###

    content = App.view('object_manager/edit')(
      head:  @object
      items: []
    )

    @show(content)



App.Config.set( 'SystemObject', { prio: 1700, parent: '#system', name: 'Objects', target: '#system/object_manager', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )
