class App.TaskbarWidget extends App.Controller
  events:
    'click .js-close': 'remove'
    'click .js-locationVerify': 'location'

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
    taskItems = []
    for task in tasks

      # collect meta data of task for task bar item
      meta =
        url:       '#'
        id:        false
        iconClass: 'loading'
        title:     App.i18n.translateInline('Loading...')
        head:      App.i18n.translateInline('Loading...')
        active:    false
      worker = App.TaskManager.worker(task.key)
      if worker
        data = worker.meta()

        # apply meta data of controller
        if data
          for key, value of data
            meta[key] = value

      # collect new task bar items
      item = {}
      item.task = task
      item.meta = meta
      taskItems.push item

      # set title
      if task.active
        @title meta.title

    @html App.view('task_widget_tasks')(
      taskItems: taskItems
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
            throw 'No such key attributes found for task item'
          order.push key
        App.TaskManager.reorder(order)

    @el.sortable(dndOptions)

  location: (e) =>
    return if !$(e.currentTarget).hasClass('is-modified')
    @locationVerify(e)

  remove: (e, key = false, force = false) =>
    e.preventDefault()
    if !key
      key = $(e.target).parents('a').data('key')
    if !key
      throw 'No such key attributes found for task item'

    # check if input has changed
    worker = App.TaskManager.worker(key)
    if !force && worker && worker.changed
      if worker.changed()
        new Remove(
          key: key
          ui:  @
        )
        return

    # check if active task is closed
    currentTask      = App.TaskManager.get(key)
    tasks            = App.TaskManager.all()
    active_is_closed = false
    for task in tasks
      if currentTask.active && task.key is key
        active_is_closed = true

    # remove task
    App.TaskManager.remove(key, false)

    $(e.target).closest('.task').remove()

    # if we do not need to move to an other task
    return if !active_is_closed

    # get new task url
    nextTaskUrl = App.TaskManager.nextTaskUrl()
    if nextTaskUrl
      @navigate nextTaskUrl
      return

    @navigate '#'

class Remove extends App.ControllerModalNice
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Discared changes'
  buttonClass: 'btn--danger'
  head: 'Confirm'

  content: ->
    App.i18n.translateContent('Tab has changed, you really want to close it?')

  onSubmit: (e) =>
    @close()
    @ui.remove(e, @key, true)
