class Sla extends App.ControllerSubContent
  requiredPermission: 'admin.sla'
  header: __('SLAs')
  events:
    'click .js-new':         'new'
    'click .js-edit':        'edit'
    'click .js-delete':      'delete'
    'click .js-description': 'description'

  constructor: ->
    super
    @subscribeCalendarId = App.Calendar.subscribe(@render)
    @subscribeSlaId = App.Sla.subscribe(@render)

    callback = =>
      @stopLoading()
      @render()
    @startLoading()
    App.Sla.fetchFull(
      callback
      clear: true
    )

  render: =>
    slas = App.Sla.search(
      sortBy: 'name'
    )
    for sla in slas
      sla.rules = App.UiElement.ticket_selector.humanText(sla.condition)
      sla.calendar = App.Calendar.find(sla.calendar_id)

    # show description button, only if content exists
    showDescription = false
    if App.Sla.description
      if !_.isEmpty(slas)
        showDescription = true
      else
        description = marked(App.i18n.translateContent(App.Sla.description))

    @html App.view('sla/index')(
      slas:            slas
      showDescription: showDescription
      description:     description
    )

  release: =>
    if @subscribeCalendarId
      App.Calendar.unsubscribe(@subscribeCalendarId)
    if @subscribeSlaId
      App.Sla.unsubscribe(@subscribeSlaId)

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        title: __('SLAs')
        object: __('SLA')
        objects: __('SLAs')
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
        title: __('SLAs')
        object: __('SLA')
        objects: __('SLAs')
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
      description: App.Sla.description
      container:   @el.closest('.content')
    )

App.Config.set('Sla', { prio: 2900, name: __('SLAs'), parent: '#manage', target: '#manage/slas', controller: Sla, permission: ['admin.sla'] }, 'NavBarAdmin')
