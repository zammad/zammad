class App.WidgetTemplate extends App.Controller
  events:
    'submit form': 'select'

  constructor: ->
    super
    @subscribeId = App.Template.subscribe(@render)
    @render()

  release: =>
    App.Template.unsubscribe(@subscribeId)

  render: =>
    return if !@rerenderNeeded()

    @configure_attributes = [
      { name: 'id', display: '', tag: 'select', multiple: false, null: true, nulloption: true, relation: 'Template', default: @id },
    ]

    template = {}
    if @id && App.Template.exists(@id)
      template = App.Template.find(@id)

    # insert data
    @html App.view('widget/template')(
      template: template
    )
    @controller = new App.ControllerForm(
      el:        @el.find('#form-template')
      model:
        configure_attributes: @configure_attributes
      autofocus: false
    )

    if App.Template.all().length is 0
      @showWelcome()
    else
      @showSelect()

  rerenderNeeded: =>
    localLastUpdatedAt = App.Template.lastUpdatedAt()
    result = true
    if localLastUpdatedAt and localLastUpdatedAt is @lastUpdatedAt
      result = false

    @lastUpdatedAt = localLastUpdatedAt

    result

  showSelect: (e) ->
    if e
      e.preventDefault()
    @el.find('.templates-select').show()
    @el.find('.templates-welcome').hide()

  showWelcome: (e) ->
    if e
      e.preventDefault()
    @el.find('.templates-select').hide()
    @el.find('.templates-welcome').show()

    if App.User.current()?.permission('admin.template')
      @el.find('.js-createLink').show()
      @el.find('.js-createTextOnly').hide()
    else
      @el.find('.js-createTextOnly').show()
      @el.find('.js-createLink').hide()

  select: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # check if template is selected
    return if !params['id']

    # remember template (to select it after rerender)
    @id = params['id']

    template = App.Template.find(params['id'])
    App.Event.trigger('ticket_create_rerender', template)
