class App.TaskbarWidget extends App.CollectionController
  events:
    'click .js-close': 'remove'
    'click .js-locationVerify': 'location'

  model: false
  template: 'widget/task_item'
  uniqKey: 'key'
  observe:
    meta: true
    active: true
    notify: true

  constructor: ->
    super

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

    # bind to changes
    @bind('taskInit', =>
      @queue.push ['renderAll']
      @uIRunner()
    )
    @bind('taskUpdate', (tasks) =>
      @queue.push ['change', tasks]
      @uIRunner()
    )
    @bind('taskRemove', (tasks) =>
      @queue.push ['destroy', tasks]
      @uIRunner()
    )
    @bind('taskCollectionOrderSet', (taskKeys) =>
      @collectionOrderSet(taskKeys)
    )

  itemGet: (key) ->
    App.TaskManager.get(key)

  itemDestroy: (key) ->
    App.TaskManager.remove(key)

  itemsAll: ->
    App.TaskManager.allWithMeta()

  location: (e) =>
    return if !$(e.currentTarget).hasClass('is-modified')
    @locationVerify(e)

  remove: (e, key = false, force = false) =>
    e.preventDefault()
    e.stopPropagation()
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
          ui: @
          event: e
        )
        return

    # check if active task is closed
    currentTask    = App.TaskManager.get(key)
    tasks          = App.TaskManager.all()
    activeIsClosed = false
    for task in tasks
      if currentTask.active && task.key is key
        activeIsClosed = true

    # remove task
    App.TaskManager.remove(key)

    # if we do not need to move to an other task
    return if !activeIsClosed

    # get new task url
    nextTaskUrl = App.TaskManager.nextTaskUrl()
    if nextTaskUrl
      @navigate nextTaskUrl
      return

    @navigate '#'

class Remove extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Discard Changes'
  buttonClass: 'btn--danger'
  head: 'Confirm'

  content: ->
    App.i18n.translateContent('Tab has changed, do you really want to close it?')

  onSubmit: =>
    @close()
    @ui.remove(@event, @key, true)
