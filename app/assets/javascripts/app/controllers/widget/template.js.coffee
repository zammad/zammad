class App.WidgetTemplate extends App.ControllerDrox
  events:
    'click [data-type=template_save]':   'create',
    'click [data-type=template_select]': 'select',
    'click [data-type=template_delete]': 'delete',

  constructor: ->
    super
    @subscribeId = App.Template.subscribe(@render, initFetch: true )

  release: =>
    App.Template.unsubscribe(@subscribeId)

  render: =>
    @configure_attributes = [
      { name: 'template_id', display: '', tag: 'select', multiple: false, null: true, nulloption: true, relation: 'Template', class: 'span2', default: @template_id  },
    ]

    template = {}
    if @template_id
      template = App.Template.find( @template_id )

    # insert data
    @html @template(
      file:   'widget/template'
      header: 'Templates'
      params:
        template: template
    )
    new App.ControllerForm(
      el:        @el.find('#form-template')
      model:     { configure_attributes: @configure_attributes, className: '' }
      autofocus: false
    )

  delete: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    template = App.Template.find( params['template_id'] )
    if confirm('Sure?')
      template.destroy()
      @template_id = undefined
      @render()

  select: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    template = App.Template.find( params['template_id'] )
    App.Event.trigger 'ticket_create_rerender', template.attributes()

  create: (e) =>
    e.preventDefault()

    # get params
    form   = @formParam( $('.ticket-create') )
    params = @formParam(e.target)
    name = params['template_name']
#    delete params['template_name']

    template = App.Template.findByAttribute( 'name', name )
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
        success: ->
          ui.template_id = @.id
          ui.render()

        error: =>
          @log 'error', 'save failed!'
      )
