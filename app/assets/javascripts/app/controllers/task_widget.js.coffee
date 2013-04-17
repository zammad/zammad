class App.TaskWidget extends App.Controller
  events:
    'click    [data-type="close"]': 'remove'

  constructor: ->
    super
    @render()

    # rerender view
    App.Event.bind 'ui:rerender', (data) =>
      @render()

    # rebuild chat widget
    App.Event.bind 'auth', (user) =>
      App.TaskManager.reset()
      @el.html('')

  render: ->

    return if _.isEmpty( @Session.all() )

    tasks = App.TaskManager.all()
    item_list = []
    for key, task of tasks
      item = {}
      item.key  = key
      item.data = App[task.type].find( task.type_id )
      item_list.push item

    @html App.view('task_widget')(
      item_list: item_list
    )

  remove: (e) =>
    e.preventDefault()
    key = $(e.target).parent().data('id')
    App.TaskManager.remove( key )
    @render()
    if _.isEmpty( App.TaskManager.all() ) 
      @navigate '#'

App.Config.set( 'task', App.TaskWidget, 'Widgets' )
