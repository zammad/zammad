class App.WidgetTemplate extends App.Controller
  events:
    'click [data-type=template_save]':   'create'
    'click [data-type=template_select]': 'select'
    'click [data-type=template_delete]': 'delete'
    'click .templates-welcome .create':  'showManage'

  constructor: ->
    super
    @subscribeId = App.Template.subscribe(@render, initFetch: true)
    @render()

  release: =>
    App.Template.unsubscribe(@subscribeId)

  render: =>
    @configure_attributes = [
      { name: 'template_id', display: '', tag: 'select', multiple: false, null: true, nulloption: true, relation: 'Template', default: @template_id },
    ]

    template = {}
    if @template_id && App.Template.exists(@template_id)
      template = App.Template.find(@template_id)

    # insert data
    @html App.view('widget/template')(
      template: template
    )
    new App.ControllerForm(
      el:        @el.find('#form-template')
      model:
        configure_attributes: @configure_attributes
      autofocus: false
    )

    if App.Template.all().length is 0
      @showWelcome()
    else
      @showManage()

  showManage: (e) ->
    if e
      e.preventDefault()
    @el.find('.templates-manage').show()
    @el.find('.templates-welcome').hide()

  showWelcome: (e) ->
    if e
      e.preventDefault()
    @el.find('.templates-manage').hide()
    @el.find('.templates-welcome').show()

  delete: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # check if template is selected
    return if !params['template_id']

    template = App.Template.find(params['template_id'])
    if confirm('Sure?')
      @template_id = false
      template.destroy()

  select: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # check if template is selected
    return if !params['template_id']

    # remember template (to select it after rerender)
    @template_id = params['template_id']

    template = App.Template.find(params['template_id'])
    App.Event.trigger 'ticket_create_rerender', template.attributes()

  create: (e) =>
    e.preventDefault()

    # get params
    form   = @formParam($(e.target).closest('.content').find('.ticket-create'))
    params = @formParam(e.target)
    name = params['template_name']
    return if !name

    template = App.Template.findByAttribute('name', name)
    if !template
      template = new App.Template

    template.load(
      name:    params['template_name']
      options: form
    )

    # validate form
    errors = template.validate()

    # show errors in form
    if errors
      @log 'error', errors
    else
      ui = @
      template.save(
        done: ->
          ui.template_id = @id

        fail: =>
          @log 'error', 'save failed!'
      )
