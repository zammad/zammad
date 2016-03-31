class App.TaskbarWidget extends App.Controller
  events:
    'click .js-close': 'remove'
    'click .js-locationVerify': 'location'
  fields:
    observe:
      field1: true
      field2: false
      meta: true
      active: true
      notify: true
    observeNot:
      field1: true
      field2: false
  currentItems: {}
    #1:
    # a: 123
    # b: 'some string'
    #2:
    # a: 123
    # b: 'some string'
  renderList: {}
    #1: ..dom..ref..
    #2: ..dom..ref..
  template: 'widget/task_item'

  constructor: ->
    super
    @renderAll()

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
    @bind('taskInit', => @renderAll())
    @bind('taskUpdate', (tasks) =>
      @checkChanges(tasks)
    )
    @bind('taskRemove', (task_ids) =>
      @checkRemoves(task_ids)
    )

    # render on generic ui call
    @bind('ui:rerender', => @renderAll())

    # render on login
    @bind('auth:login', => @renderAll())

    # reset current tasks on logout
    @bind('auth:logout', => @renderAll())

  checkRemoves: (task_ids) ->
    for task_id in task_ids
      delete @currentItems[task_id]
      if @renderList[task_id]
        @renderList[task_id].remove()
        delete @renderList[task_id]

  checkChanges: (items) ->
    #console.log('checkChanges', items, @currentItems)
    changedItems = []
    for item in items
      attributes = {}
      for field of @fields.observe
        attributes[field] = item[field]
      #console.log('item', item)
      #attributes = item.attributes()
      #console.log('item', @fields.observe, item, attributes)
      if !@currentItems[item.id]
        changedItems.push item
        @currentItems[item.id] = attributes
      else
        currentItem = @currentItems[item.id]
        hit = false
        for field of @fields.observe
          diff = _.isEqual(currentItem[field], attributes[field])
          #console.log('diff', field, diff, currentItem[field], attributes[field])
          if !hit && diff
            changedItems.push item
            @currentItems[item.id] = attributes
            hit = true
    console.log('checkChanges, changedItems', changedItems)
    return if _.isEmpty(changedItems)
    @renderParts(changedItems)

  renderAll: ->
    #@html ''
    items = App.TaskManager.allWithMeta()
    localeEls = []
    for item in items
      localeEls.push @renderItem(item, false)
    @html localeEls

  renderParts: (items) ->
    for item in items
      if !@renderList[item.id]
        @renderItem(item)
      else
        @renderItem(item, @renderList[item.id])

  renderItem: (item, el) ->
    html =  $(App.view(@template)(
      item: item
    ))
    console.log('renderItem', item)
    @renderList[item.id] = html
    if el is false
      return html
    else if !el
      @el.append(html)
    else
      el.replaceWith(html)

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
  buttonSubmit: 'Discard changes'
  buttonClass: 'btn--danger'
  head: 'Confirm'

  content: ->
    App.i18n.translateContent('Tab has changed, you really want to close it?')

  onSubmit: =>
    @close()
    @ui.remove(@event, @key, true)
