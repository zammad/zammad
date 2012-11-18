$ = jQuery.sub()

class App.TemplateUI extends App.Controller
  events:
    'click [data-type=template_save]':   'create',
    'click [data-type=template_select]': 'select',
    'click [data-type=template_delete]': 'delete',

  constructor: ->
    super

    # fetch item on demand
    fetch_needed = 1
    if App.Collection.count( 'Template' ) > 0
      fetch_needed = 0
      @render()

    if fetch_needed
      @reload()

  reload: =>
      App.Template.bind 'refresh', =>
        @log 'loading....'
        @render()
        App.Template.unbind 'refresh'
      App.Collection.fetch( 'Template' )

  render: =>
    @configure_attributes = [
      { name: 'template_id', display: '', tag: 'select', multiple: false, null: true, nulloption: true, relation: 'Template', class: 'span2', default: @template_id  },
    ]

    template = {}
    if @template_id
      template = App.Collection.find( 'Template', @template_id )

    # insert data
    @html App.view('template_widget')(
      template: template,
    )
    new App.ControllerForm(
      el: @el.find('#form-template'),
      model: { configure_attributes: @configure_attributes, className: '' },
      autofocus: false,
    )

  delete: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    template = App.Collection.find( 'Template', params['template_id'] )
    if confirm('Sure?')
      template.destroy() 
      @template_id = undefined
      @render()

  select: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    template = App.Collection.find( 'Template', params['template_id'] )
    App.Event.trigger 'ticket_create_rerender', template.attributes()

  create: (e) =>
    e.preventDefault()
    
    # get params
    params = @formParam(e.target)
    name = params['template_name']
#    delete params['template_name']

    template = App.Collection.findByAttribute( 'Template', 'name', name )
    if !template
      template = new App.Template

    options = params
    template.load(
      name:    params['template_name']
      options: options
    )

    # validate form
    errors = template.validate()

    # show errors in form
    if errors
      @log 'error new', errors
    else
      ui = @
      template.save(
        success: ->
          ui.template_id = @.id
          ui.render()

        error: =>
          @log 'save failed!'
      )
