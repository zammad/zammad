class App.ChannelEmailFilter extends App.Controller
  events:
    'click [data-type=new]': 'new'

  constructor: ->
    super
    App.PostmasterFilter.subscribe(@render, initFetch: true)

  render: =>
    data = App.PostmasterFilter.search(sortBy: 'name')

    template = $( '<div><div class="overview"></div><a data-type="new" class="btn btn--success">' + App.i18n.translateContent('New') + '</a></div>' )

    description = 'With filters you can e. g. dispatch new tickets into certain groups or set a certain priority for tickets of a VIP customer.'

    new App.ControllerTable(
      el:       template.find('.overview')
      model:    App.PostmasterFilter
      objects:  data
      bindRow:
        events:
          'click': @edit
      explanation: description
    )
    @html template

  new: (e) =>
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        object: 'Postmaster Filter'
      genericObject: 'PostmasterFilter'
      container: @el.closest('.content')
      callback: @load
      large: true
    )

  edit: (id, e) =>
    e.preventDefault()
    new App.ControllerGenericEdit(
      id: id,
      pageData:
        object: 'Postmaster Filter'
      genericObject: 'PostmasterFilter'
      container: @el.closest('.content')
      callback: @load
      large: true
    )
