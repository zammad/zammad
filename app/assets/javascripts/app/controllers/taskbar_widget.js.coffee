class App.TaskbarWidget extends App.Controller
  events:
    'click .js-close': 'remove'

  constructor: ->
    super
    @render()

    # render on generic ui call
    @bind 'ui:rerender', => @render()

    # render view
    @bind 'task:render', => @render()

    # render on login
    @bind 'auth:login', => @render()

    # reset current tasks on logout
    @bind 'auth:logout', => @render()

  render: ->
    return if !@Session.get()

    tasks = App.TaskManager.all()
    item_list = []
    for task in tasks

      # collect meta data of task for task bar item
      data =
        url:   '#'
        id:    false
        iconClass: 'loading'
        title: App.i18n.translateInline('Loading...')
        head:  App.i18n.translateInline('Loading...')
      worker = App.TaskManager.worker( task.key  )
      if worker
        meta = worker.meta()

        # apply meta data of controller
        if meta
          for key, value of meta
            data[key] = value

      # collect new task bar items
      item = {}
      item.task = task
      item.data = data
      item_list.push item

      # set title
      if task.active
        @title data.title

    @html App.view('task_widget_tasks')(
      item_list: item_list
    )

    dndOptions =
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true
      items:                '> a'
      update:               =>
        items = @el.find('> a')
        order = []
        for item in items
          key = $(item).data('key')
          if !key
            throw "No such key attributes found for task item"
          order.push key
        App.TaskManager.reorder( order  )

    @el.sortable( dndOptions )

  remove: (e, key = false, force = false) =>
    e.preventDefault()
    if !key
      key = $(e.target).parents('a').data('key')
    if !key
      throw "No such key attributes found for task item"

    # check if input has changed
    worker = App.TaskManager.worker( key )
    if !force && worker && worker.changed
      if worker.changed()
        new Remove(
          key: key
          ui:  @
        )
        return

    # check if active task is closed
    currentTask = App.TaskManager.get( key )
    tasks = App.TaskManager.all()
    active_is_closed = false
    for task in tasks
      if currentTask.active && task.key is key
        active_is_closed = true

    # remove task
    App.TaskManager.remove( key )

    # navigate to next task if needed
    tasks = App.TaskManager.all()
    if active_is_closed && !_.isEmpty( tasks )
      task_last = undefined
      for task in tasks
        task_last = task
      if task_last
        worker = App.TaskManager.worker( task_last.key )
        if worker
          @navigate worker.url()
        return
    if _.isEmpty( tasks )
      @navigate '#'

class Remove extends App.ControllerModal
  constructor: ->
    super
    @head        = 'Confirm'
    @message     = 'Tab has changed, you really want to close it?'
    @cancel      = true
    @close       = true
    @button      = 'Discared changes'
    @buttonClass = 'btn--danger'
    @show()

  onSubmit: (e) =>
    e.preventDefault()
    @hide()
    @ui.remove(e, @key, true)
