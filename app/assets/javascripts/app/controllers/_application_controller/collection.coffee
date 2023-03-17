class App.CollectionController extends App.Controller
  events:
    'click .js-remove': 'remove'
    'click .js-item': 'click'
    'click .js-locationVerify': 'location'
  observe:
    field1: true
    field2: false
  #currentItems: {}
    #1:
    # a: 123
    # b: 'some string'
    #2:
    # a: 123
    # b: 'some string'
  #renderList: {}
    #1: ..dom..ref..
    #2: ..dom..ref..
  template: '_need_to_be_defined_'
  uniqKey: 'id'
  model: '_need_to_be_defined_'
  sortBy: 'name'
  order: 'ASC',
  insertPosition: 'after'
  globalRerender: true

  constructor: ->
    @events = @constructor.events unless @events
    @observe = @constructor.observe unless @observe
    @currentItems = {}
    @renderList = {}
    @queue = []
    @queueRunning = false
    @lastOrder = []

    super

    @queue.push ['renderAll']
    @uIRunner()

    # bind to changes
    if @model
      @subscribeId = App[@model].subscribe(@collectionSync)

    # render on generic ui call
    if @globalRerender
      @controllerBind('ui:rerender', =>
        @queue.push ['renderAll']
        @uIRunner()
      )

    # render on login
    @controllerBind('auth:login', =>
      @queue.push ['renderAll']
      @uIRunner()
    )

    # reset current tasks on logout
    @controllerBind('auth:logout', =>
      @queue.push ['renderAll']
      @uIRunner()
    )

    @log 'debug', 'Init @uniqKey', @uniqKey
    @log 'debug', 'Init @observe', @observe
    @log 'debug', 'Init @model', @model

  release: =>
    if @subscribeId
      App[@model].unsubscribe(@subscribeId)

  uIRunner: =>
    return if !@queue[0]
    return if @queueRunning
    @queueRunning = true
    loop
      param = @queue.shift()
      if param[0] is 'domChange'
        @domChange(param[1])
      else if param[0] is 'domRemove'
        @domRemove(param[1])
      else if param[0] is 'change'
        @collectionSync(param[1])
      else if param[0] is 'destroy'
        @collectionSync(param[1], 'destroy')
      else if param[0] is 'renderAll'
        @renderAll()
      else
        @log 'error', "Unknown type #{param[0]}", param[1]
      if !@queue[0]
        @onRenderEnd()
        @queueRunning = false
        break

  collectionOrderGet: =>
    newOrder = []
    all = @itemsAll()
    for item in all
      newOrder.push item[@uniqKey]
    newOrder

  collectionOrderSet: (newOrder = false) =>
    if !newOrder
      newOrder = @collectionOrderGet()
    @lastOrder = newOrder

  collectionSync: (items, type) =>

    # remove items
    if type is 'destroy'
      ids = []
      for item in items
        ids.push item[@uniqKey]
      @queue.push ['domRemove', ids]
      @uIRunner()
      return

    # inital render
    if _.isEmpty(@renderList)
      @queue.push ['renderAll']
      @uIRunner()
      return

    # check if item order is the same
    newOrder = @collectionOrderGet()
    removedIds = _.difference(@lastOrder, newOrder)
    addedIds = _.difference(newOrder, @lastOrder)

    @log 'debug', 'collectionSync removedIds', removedIds
    @log 'debug', 'collectionSync addedIds', addedIds
    @log 'debug', 'collectionSync @lastOrder', @lastOrder
    @log 'debug', 'collectionSync newOrder', newOrder

    # add items
    alreadyRemoved = false
    if !_.isEmpty(addedIds)
      lastOrderNew = []
      for id in @lastOrder
        if !_.contains(removedIds, id)
          lastOrderNew.push id

      # try to find positions of new items
      @log 'debug', 'collectionSync lastOrderNew', lastOrderNew
      applyOrder = App.Utils.diffPositionAdd(lastOrderNew, newOrder)
      @log 'debug', 'collectionSync applyOrder', applyOrder
      if !applyOrder
        @queue.push ['renderAll']
        @uIRunner()
        return

      if !_.isEmpty(removedIds)
        alreadyRemoved = true
        @queue.push ['domRemove', removedIds]
        @uIRunner()

      newItems = []
      for apply in applyOrder
        item = @itemGet(apply.id)
        item.meta_position = apply.position
        newItems.push item
      @queue.push ['domChange', newItems]
      @uIRunner()

    # remove items
    if !alreadyRemoved && !_.isEmpty(removedIds)
      @queue.push ['domRemove', removedIds]
      @uIRunner()

    # update items
    newItems = []
    for item in items
      if !_.contains(removedIds, item.id) && !_.contains(addedIds, item.id)
        newItems.push item
    return if _.isEmpty(newItems)
    @queue.push ['domChange', newItems]
    @uIRunner()
    #return

    # rerender all items
    #@queue.push ['renderAll']
    #@uIRunner()

  domRemove: (ids) =>
    @log 'debug', 'domRemove', ids
    for id in ids
      @itemAttributesDelete(id)
      if @renderList[id]
        @renderList[id].remove()
        delete @renderList[id]
      @onRemoved(id)
    @collectionOrderSet()

  domChange: (items) =>
    @log 'debug', 'domChange items', items
    @log 'debug', 'domChange @currentItems', @currentItems
    changedItems = []
    for item in items
      @log 'debug', 'domChange|item', item
      attributes = @itemAttributes(item)
      currentItem = @itemAttributesGet(item[@uniqKey])
      if !currentItem
        @log 'debug', 'domChange|add', item
        changedItems.push item
        @itemAttributesSet(item[@uniqKey], attributes)
      else
        @log 'debug', 'domChange|change', item
        @log 'debug', 'domChange|change|observe attributes', @observe
        @log 'debug', 'domChange|change|current', currentItem
        @log 'debug', 'domChange|change|new', attributes
        for field of @observe
          @log 'debug', 'domChange|change|compare', field, currentItem[field], attributes[field]
          diff = !_.isEqual(currentItem[field], attributes[field])
          @log 'debug', 'domChange|diff', diff
          if diff
            changedItems.push item
            @itemAttributesSet(item[@uniqKey], attributes)
            break
    return if _.isEmpty(changedItems)
    @renderParts(changedItems)

  renderAll: =>
    items = @itemsAll()
    @log 'debug', 'renderAll', items
    localeEls = []
    for item in items
      attributes = @itemAttributes(item)
      @itemAttributesSet(item[@uniqKey], attributes)
      localeEls.push @renderItem(item, false)
    @html localeEls
    @collectionOrderSet()
    @onRenderEnd()

  itemDestroy: (id) =>
    App[@model].destroy(id)

  itemsAll: =>
    App[@model].search(sortBy: @sortBy, order: @order)

  itemAttributesDiff: (item) =>
    attributes = @itemAttributes(item)
    currentItem = @itemAttributesGet(item[@uniqKey])
    for field of @observe
      @log 'debug', 'itemAttributesDiff|compare', field, currentItem[field], attributes[field]
      diff = !_.isEqual(currentItem[field], attributes[field])
      if diff
        @log 'debug', 'itemAttributesDiff|diff', diff
        return true
    false

  itemAttributesDelete: (id) =>
    delete @currentItems[id]

  itemAttributesGet: (id) =>
    @currentItems[id]

  itemAttributesSet: (id, attributes) =>
    @currentItems[id] = attributes

  itemAttributes: (item) =>
    attributes = {}
    for field of @observe
      attributes[field] = item[field]
    attributes

  itemGet: (id) =>
    App[@model].find(id)

  renderParts: (items) =>
    @log 'debug', 'renderParts', items
    for item in items
      if !@renderList[item[@uniqKey]]
        @renderItem(item)
      else
        @renderItem(item, @renderList[item[@uniqKey]])
    @collectionOrderSet()

  renderItem: (item, el) =>
    if @prepareForObjectListItemSupport
      item = @prepareForObjectListItem(item)
    @log 'debug', 'renderItem', item, @template, el, @renderList[item[@uniqKey]]
    html =  $(App.view(@template)(
      item: item
    ))
    if @onRenderItemEnd
      @onRenderItemEnd(item, html)
    itemCount = Object.keys(@renderList).length
    @renderList[item[@uniqKey]] = html
    if el is false
      return html
    else if !el
      position = item.meta_position
      if itemCount > position
        position += 1
      element = @el.find(".js-item:nth-child(#{position})")
      if !element.get(0)
        @el.append(html)
        return
      if @insertPosition is 'before'
        element.before(html)
      else
        element.after(html)
    else
      el.replaceWith(html)

  onRenderEnd: ->
    # nothing

  location: (e) =>
    @locationVerify(e)

  click: (e) =>
    row = $(e.target).closest('.js-item')
    id = row.data('id')
    @onClick(id, e)

  onClick: (id, e) ->
    # nothing

  remove: (e) =>
    e.preventDefault()
    e.stopPropagation()
    row = $(e.target).closest('.js-item')
    id = row.data('id')
    @onRemove(id,e)
    @itemDestroy(id)

  onRemove: (id, e) ->
    # nothing

  onRemoved: (id) ->
    # nothing
