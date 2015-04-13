###
Spine.js MVC library
Released under the MIT License
###

Events =
  bind: (ev, callback) ->
    evs   = ev.split(' ')
    @_callbacks or= {} unless @hasOwnProperty('_callbacks')
    for name in evs
      @_callbacks[name] or= []
      @_callbacks[name].push(callback)
    this

  one: (ev, callback) ->
    @bind ev, handler = ->
      @unbind(ev, handler)
      callback.apply(this, arguments)

  trigger: (args...) ->
    ev   = args.shift()
    list = @_callbacks?[ev]
    return unless list
    for callback in list
      break if callback.apply(this, args) is false
    true

  listenTo: (obj, ev, callback) ->
    obj.bind(ev, callback)
    @listeningTo or= []
    @listeningTo.push {obj, ev, callback}
    this

  listenToOnce: (obj, ev, callback) ->
    listeningToOnce = @listeningToOnce or= []
    obj.bind ev, handler = ->
      idx = -1
      for lt, i in listeningToOnce when lt.obj is obj
        idx = i if lt.ev is ev and lt.callback is handler
      obj.unbind(ev, handler)
      listeningToOnce.splice(idx, 1) unless idx is -1
      callback.apply(this, arguments)
    listeningToOnce.push {obj, ev, callback: handler}
    this

  stopListening: (obj, events, callback) ->
    if arguments.length is 0
      for listeningTo in [@listeningTo, @listeningToOnce]
        continue unless listeningTo
        for lt in listeningTo
          lt.obj.unbind(lt.ev, lt.callback)
      @listeningTo = undefined
      @listeningToOnce = undefined

    else if obj
      for listeningTo in [@listeningTo, @listeningToOnce]
        continue unless listeningTo
        events = if events then events.split(' ') else [undefined]
        for ev in events
          for idx in [listeningTo.length-1..0]
            lt = listeningTo[idx]
            continue unless lt.obj is obj
            continue if callback and lt.callback isnt callback
            if (not ev) or (ev is lt.ev)
              lt.obj.unbind(lt.ev, lt.callback)
              listeningTo.splice(idx, 1) unless idx is -1
            else if ev
              evts = lt.ev.split(' ')
              if ev in evts
                evts = (e for e in evts when e isnt ev)
                lt.ev = $.trim(evts.join(' '))
                lt.obj.unbind(ev, lt.callback)
    this

  unbind: (ev, callback) ->
    if arguments.length is 0
      @_callbacks = {}
      return this
    return this unless ev
    evs = ev.split(' ')
    for name in evs
      list = @_callbacks?[name]
      continue unless list
      unless callback
        delete @_callbacks[name]
        continue
      for cb, i in list when (cb is callback)
        list = list.slice()
        list.splice(i, 1)
        @_callbacks[name] = list
        break
    this

Events.on  = Events.bind
Events.off = Events.unbind

Log =
  trace: true

  logPrefix: '(App)'

  log: (args...) ->
    return unless @trace
    if @logPrefix then args.unshift(@logPrefix)
    console?.log?(args...)
    this

moduleKeywords = ['included', 'extended']

class Module
  @include: (obj) ->
    throw new Error('include(obj) requires obj') unless obj
    for key, value of obj when key not in moduleKeywords
      @::[key] = value
    obj.included?.apply(this)
    this

  @extend: (obj) ->
    throw new Error('extend(obj) requires obj') unless obj
    for key, value of obj when key not in moduleKeywords
      @[key] = value
    obj.extended?.apply(this)
    this

  @proxy: (func) ->
    => func.apply(this, arguments)

  proxy: (func) ->
    => func.apply(this, arguments)

  constructor: ->
    @init?(arguments...)

class Model extends Module
  @extend Events
  @include Events

  @records    : []
  @irecords   : {}
  @attributes : []

  @configure: (name, attributes...) ->
    @className = name
    @deleteAll()
    @attributes = attributes if attributes.length
    @attributes and= makeArray(@attributes)
    @attributes or=  []
    @unbind()
    this

  @toString: -> "#{@className}(#{@attributes.join(", ")})"

  @find: (id, notFound = @notFound) ->
    @irecords[id]?.clone() or notFound?(id)

  @findAll: (ids, notFound) ->
    (@find(id) for id in ids when @find(id, notFound))

  @notFound: (id) -> null

  @exists: (id) -> Boolean @irecords[id]

  @addRecord: (record) ->
    if root = @irecords[record.id or record.cid]
      root.refresh(record)
    else
      record.id or= record.cid
      @irecords[record.id] = @irecords[record.cid] = record
      @records.push(record)
    record

  @refresh: (values, options = {}) ->
    @deleteAll() if options.clear
    records = @fromJSON(values)
    records = [records] unless isArray(records)
    @addRecord(record) for record in records
    @sort()

    result = @cloneArray(records)
    @trigger('refresh', result, options)
    result

  @select: (callback) ->
    (record.clone() for record in @records when callback(record))

  @findByAttribute: (name, value) ->
    for record in @records
      if record[name] is value
        return record.clone()
    null

  @findAllByAttribute: (name, value) ->
    @select (item) ->
      item[name] is value

  @each: (callback) ->
    callback(record.clone()) for record in @records

  @all: ->
    @cloneArray(@records)

  @slice: (begin = 0, end)->
    @cloneArray(@records.slice(begin, end))

  @first: (end = 1)->
    if end > 1
      @cloneArray(@records.slice(0, end))
    else
      @records[0]?.clone()

  @last: (begin)->
    if typeof begin is 'number'
      @cloneArray(@records.slice(-begin))
    else
      @records[@records.length - 1]?.clone()

  @count: ->
    @records.length

  @deleteAll: ->
    @records  = []
    @irecords = {}

  @destroyAll: (options) ->
    record.destroy(options) for record in @records

  @update: (id, atts, options) ->
    @find(id).updateAttributes(atts, options)

  @create: (atts, options) ->
    record = new @(atts)
    record.save(options)

  @destroy: (id, options) ->
    @find(id).destroy(options)

  @change: (callbackOrParams) ->
    if typeof callbackOrParams is 'function'
      @bind('change', callbackOrParams)
    else
      @trigger('change', arguments...)

  @fetch: (callbackOrParams) ->
    if typeof callbackOrParams is 'function'
      @bind('fetch', callbackOrParams)
    else
      @trigger('fetch', arguments...)

  @toJSON: ->
    @records

  @beforeFromJSON: (objects) -> objects

  @fromJSON: (objects) ->
    return unless objects
    if typeof objects is 'string'
      objects = JSON.parse(objects)
    objects = @beforeFromJSON(objects)
    if isArray(objects)
      for value in objects
        if value instanceof this
          value
        else
          new @(value)
    else
      return objects if objects instanceof this
      new @(objects)

  @fromForm: ->
    (new this).fromForm(arguments...)

  @sort: ->
    if @comparator
      @records.sort @comparator
    this

  # Private

  @cloneArray: (array) ->
    (value.clone() for value in array)

  @idCounter: 0

  @uid: (prefix = '') ->
    uid = prefix + @idCounter++
    uid = @uid(prefix) if @exists(uid)
    uid

  # Instance

  constructor: (atts) ->
    super
    if @constructor.uuid? and typeof @constructor.uuid is 'function'
      @cid = @constructor.uuid()
      @id  = @cid unless @id
    else
      @cid = atts?.cid or @constructor.uid('c-')
    @load atts if atts

  isNew: ->
    not @exists()

  isValid: ->
    not @validate()

  validate: ->

  load: (atts) ->
    if atts.id then @id = atts.id
    for key, value of atts
      if typeof @[key] is 'function'
        continue if typeof value is 'function'
        @[key](value)
      else
        @[key] = value
    this

  attributes: ->
    result = {}
    for key in @constructor.attributes when key of this
      if typeof @[key] is 'function'
        result[key] = @[key]()
      else
        result[key] = @[key]
    result.id = @id if @id
    result

  eql: (rec) ->
    rec and rec.constructor is @constructor and
      ((rec.cid is @cid) or (rec.id and rec.id is @id))

  save: (options = {}) ->
    unless options.validate is false
      error = @validate()
      if error
        @trigger('error', this, error)
        return false

    @trigger('beforeSave', this, options)
    record = if @isNew() then @create(options) else @update(options)
    @stripCloneAttrs()
    @trigger('save', record, options)
    record

  stripCloneAttrs: ->
    return if @hasOwnProperty 'cid' # Make sure it's not the raw object
    for own key, value of this
      delete @[key] if key in @constructor.attributes
    this

  updateAttribute: (name, value, options) ->
    atts = {}
    atts[name] = value
    @updateAttributes(atts, options)

  updateAttributes: (atts, options) ->
    @load(atts)
    @save(options)

  changeID: (id) ->
    return if id is @id
    records = @constructor.irecords
    records[id] = records[@id]
    delete records[@id] unless @cid is @id
    @id = id
    @save()

  remove: (options = {}) ->
    # Remove record from model
    records = @constructor.records.slice(0)
    for record, i in records when @eql(record)
      records.splice(i, 1)
      break
    @constructor.records = records
    if options.clear
      # Remove the ID and CID indexes
      delete @constructor.irecords[@id]
      delete @constructor.irecords[@cid]

  destroy: (options = {}) ->
    options.clear ?= true
    @trigger('beforeDestroy', this, options)
    @remove(options)
    @destroyed = true
    # handle events
    @trigger('destroy', this, options)
    @trigger('change', this, 'destroy', options)
    @stopListening() if @listeningTo
    @unbind()
    this

  dup: (newRecord = true) ->
    atts = @attributes()
    if newRecord
      delete atts.id
    else
      atts.cid = @cid
    record = new @constructor(atts)
    @_callbacks and record._callbacks = @_callbacks unless newRecord
    record

  clone: ->
    createObject(this)

  reload: ->
    return this if @isNew()
    original = @constructor.find(@id)
    @load(original.attributes())
    original

  refresh: (atts) ->
    atts = @constructor.fromJSON(atts)
    # ID change, need to do some shifting
    if atts.id and @id isnt atts.id
      @changeID(atts.id)
    # go to the source and load attributes
    @constructor.irecords[@id].load(atts)
    @trigger('refresh', this)
    @trigger('change', this, 'refresh')
    this

  toJSON: ->
    @attributes()

  toString: ->
    "<#{@constructor.className} (#{JSON.stringify(this)})>"

  fromForm: (form) ->
    result = {}

    for checkbox in $(form).find('[type=checkbox]:not([value])')
      result[checkbox.name] = $(checkbox).prop('checked')

    for checkbox in $(form).find('[type=checkbox][name$="[]"]')
      name = checkbox.name.replace(/\[\]$/, '')
      result[name] or= []
      result[name].push checkbox.value if $(checkbox).prop('checked')

    for key in $(form).serializeArray()
      result[key.name] or= key.value

    @load(result)

  exists: ->
    @constructor.exists(@id)

  # Private

  update: (options) ->
    @trigger('beforeUpdate', this, options)

    records = @constructor.irecords
    records[@id].load @attributes()

    @constructor.sort()

    clone = records[@id].clone()
    clone.trigger('update', clone, options)
    clone.trigger('change', clone, 'update', options)
    clone

  create: (options) ->
    @trigger('beforeCreate', this, options)
    @id or= @cid

    record = @dup(false)
    @constructor.addRecord(record)
    @constructor.sort()

    clone = record.clone()
    clone.trigger('create', clone, options)
    clone.trigger('change', clone, 'create', options)
    clone

  bind: ->
    record = @constructor.irecords[@id] or this
    Events.bind.apply record, arguments

  one: ->
    record = @constructor.irecords[@id] or this
    Events.one.apply record, arguments

  unbind: ->
    record = @constructor.irecords[@id] or this
    Events.unbind.apply record, arguments

  trigger: ->
    Events.trigger.apply this, arguments # fire off the instance event
    return true if arguments[0] is 'refresh' # Don't trigger refresh events, because ... ?
    @constructor.trigger arguments... # fire off the class event

Model::on  = Model::bind
Model::off = Model::unbind


class Controller extends Module
  @include Events
  @include Log

  eventSplitter: /^(\S+)\s*(.*)$/
  tag: 'div'

  constructor: (options) ->
    @options = options

    for key, value of @options
      @[key] = value

    @el = document.createElement(@tag) unless @el
    @el = $(@el)

    @el.addClass(@className) if @className
    @el.attr(@attributes) if @attributes

    @events = @constructor.events unless @events
    @elements = @constructor.elements unless @elements

    context = @
    while parent_prototype = context.constructor.__super__
      @events = $.extend({}, parent_prototype.events, @events) if parent_prototype.events
      @elements = $.extend({}, parent_prototype.elements, @elements) if parent_prototype.elements
      context = parent_prototype

    @delegateEvents(@events) if @events
    @refreshElements() if @elements

    super

  release: =>
    @trigger 'release', this
    # no need to unDelegateEvents since remove will end up handling that
    @el.remove()
    @unbind()
    @stopListening()

  $: (selector) -> @el.find(selector)

  delegateEvents: (events) ->
    for key, method of events

      if typeof(method) is 'function'
        # Always return true from event handlers
        method = do (method) => =>
          method.apply(this, arguments)
          true
      else
        unless @[method]
          throw new Error("#{method} doesn't exist")

        method = do (method) => =>
          @[method].apply(this, arguments)
          true

      match      = key.match(@eventSplitter)
      eventName  = match[1]
      selector   = match[2]

      if selector is ''
        @el.bind(eventName, method)
      else
        @el.on(eventName, selector, method)

  refreshElements: ->
    for key, value of @elements
      @[value] = @$(key)

  delay: (func, timeout) ->
    setTimeout(@proxy(func), timeout || 0)

  # keep controllers elements obj in sync with it contents

  html: (element) ->
    @el.html(element.el or element)
    @refreshElements()
    @el

  append: (elements...) ->
    elements = (e.el or e for e in elements)
    @el.append(elements...)
    @refreshElements()
    @el

  appendTo: (element) ->
    @el.appendTo(element.el or element)
    @refreshElements()
    @el

  prepend: (elements...) ->
    elements = (e.el or e for e in elements)
    @el.prepend(elements...)
    @refreshElements()
    @el

  replace: (element) ->
    element = element.el or element
    element = $.trim(element) if typeof element is "string"
    # parseHTML is incompatible with Zepto
    [previous, @el] = [@el, $($.parseHTML(element)?[0] or element)]
    previous.replaceWith(@el)
    @delegateEvents(@events)
    @refreshElements()
    @el

# Utilities & Shims

$ = window?.jQuery or window?.Zepto or (element) -> element

createObject = Object.create or (o) ->
  Func = ->
  Func.prototype = o
  new Func()

isArray = (value) ->
  Object::toString.call(value) is '[object Array]'

isBlank = (value) ->
  return true unless value
  return false for key of value
  true

makeArray = (args) ->
  Array::slice.call(args, 0)

# Globals

Spine = @Spine   = {}
module?.exports  = Spine

Spine.version    = '1.4.1'
Spine.isArray    = isArray
Spine.isBlank    = isBlank
Spine.$          = $
Spine.Events     = Events
Spine.Log        = Log
Spine.Module     = Module
Spine.Controller = Controller
Spine.Model      = Model

# Global events

Module.extend.call(Spine, Events)

# JavaScript compatability

Module.create = Module.sub =
  Controller.create = Controller.sub =
    Model.sub = (instances, statics) ->
      class Result extends this
      Result.include(instances) if instances
      Result.extend(statics) if statics
      Result.unbind?()
      Result

Model.setup = (name, attributes = []) ->
  class Instance extends this
  Instance.configure(name, attributes...)
  Instance

Spine.Class = Module
