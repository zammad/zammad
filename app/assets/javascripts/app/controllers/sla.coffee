class Index extends App.ControllerContent
  events:
    'click .js-new':         'new'
    'click .js-edit':        'edit'
    'click .js-delete':      'delete'
    'click .js-description': 'description'

  constructor: ->
    super

    # check authentication
    return if !@authenticate(false, 'Admin')

    @interval(@load, 60000)
    #@load()

  load: =>
    @startLoading()
    @ajax(
      id:   'sla_index'
      type: 'GET'
      url:  @apiPath + '/slas'
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @stopLoading()
        @render(data)
    )

  render: =>
    slas = App.Sla.search(
      sortBy: 'name'
    )
    for sla in slas
      if sla.first_response_time
        sla.first_response_time_in_text = @toText(sla.first_response_time)
      if sla.update_time
        sla.update_time_in_text = @toText(sla.update_time)
      if sla.solution_time
        sla.solution_time_in_text = @toText(sla.solution_time)
      sla.rules = App.UiElement.ticket_selector.humanText(sla.condition)
      sla.calendar = App.Calendar.find(sla.calendar_id)

    # show description button, only if content exists
    showDescription = false
    if App.Sla.description
      if !_.isEmpty(slas)
        showDescription = true
      else
        description = marked(App.Sla.description)

    @html App.view('sla/index')(
      slas:            slas
      showDescription: showDescription
      description:     description
    )

  release: =>
    if @subscribeId
      App.Calendar.unsubscribe(@subscribeId)

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        title: 'SLAs'
        object: 'Sla'
        objects: 'SLAs'
      genericObject: 'Sla'
      container:     @el.closest('.content')
      callback:      @load
      large:         true
    )

  edit: (e) ->
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    new App.ControllerGenericEdit(
      id: id
      pageData:
        title: 'SLAs'
        object: 'Sla'
        objects: 'SLAs'
      genericObject: 'Sla'
      callback:      @load
      container:     @el.closest('.content')
      large:         true
    )

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Sla.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @load
    )

  description: (e) =>
    new App.ControllerGenericDescription(
      description: App.Calendar.description
      container:   @el.closest('.content')
    )

  toText: (m) ->
    m = parseInt(m)
    return if !m
    minutes = m % 60
    hours = Math.floor(m / 60)

    if minutes < 10
      minutes = "0#{minutes}"
    if hours < 10
      hours = "0#{hours}"

    "#{hours}:#{minutes}"

App.Config.set( 'Sla', { prio: 2900, name: 'SLAs', parent: '#manage', target: '#manage/slas', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )