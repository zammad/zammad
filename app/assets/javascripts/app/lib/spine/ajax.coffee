Spine  = @Spine or require('spine')
$      = Spine.$
Model  = Spine.Model
Queue  = $({})

Ajax =
  getURL: (object) ->
    if object.className?
      @generateURL(object)
    else
      @generateURL(object, encodeURIComponent(object.id))

  getCollectionURL: (object) ->
    @generateURL(object)

  getScope: (object) ->
    object.scope?() or object.scope

  getCollection: (object) ->
    if object.url isnt object.generateURL
      if typeof object.url is 'function'
        object.url()
      else
        object.url
    else if object.className?
      object.className.toLowerCase() + 's'

  generateURL: (object, args...) ->
    collection = Ajax.getCollection(object) or Ajax.getCollection(object.constructor)
    scope = Ajax.getScope(object) or Ajax.getScope(object.constructor)
    args.unshift(collection)
    args.unshift(scope)
    # construct and clean url
    path = args.join('/')
    path = path.replace /(\/\/)/g, "/"
    path = path.replace /^\/|\/$/g, ""
    # handle relative urls vs those that use a host
    if path.indexOf("../") isnt 0
      Model.host + "/" + path
    else
      path

  enabled: true

  disable: (callback) ->
    if @enabled
      @enabled = false
      try
        do callback
      catch e
        throw e
      finally
        @enabled = true
    else
      do callback

  queue: (request) ->
    if request then Queue.queue(request) else Queue.queue()

  clearQueue: ->
    @queue []

  config:
    loadMethod: 'GET'
    updateMethod: 'PUT'
    createMethod: 'POST'
    destroyMethod: 'DELETE'

class Base
  defaults:
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}

  queue: Ajax.queue

  ajax: (params, defaults) ->
    $.ajax @ajaxSettings(params, defaults)

  ajaxQueue: (params, defaults, record) ->
    jqXHR    = null
    deferred = $.Deferred()
    promise  = deferred.promise()
    return promise unless Ajax.enabled
    settings = @ajaxSettings(params, defaults)
    # prefer setting if exists else default is to parallelize 'GET' requests
    parallel = if settings.parallel isnt undefined then settings.parallel else (settings.type is 'GET')
    request = (next) ->
      if record?.id?
        # for existing singleton, model id may have been updated
        # after request has been queued
        settings.url ?= Ajax.getURL(record)
        settings.data?.id = record.id
      # 2 reasons not to stringify: if already a string, or if intend to have ajax processData
      if typeof settings.data isnt 'string' and settings.processData isnt true
        settings.data = JSON.stringify(settings.data)
      jqXHR = $.ajax(settings)
                .done(deferred.resolve)
                .fail(deferred.reject)
                .then(next, next)
      if parallel
        Queue.dequeue()

    promise.abort = (statusText) ->
      return jqXHR.abort(statusText) if jqXHR
      index = $.inArray(request, @queue())
      @queue().splice(index, 1) if index > -1
      deferred.rejectWith(
        settings.context or settings,
        [promise, statusText, '']
      )
      promise

    @queue request
    promise

  ajaxSettings: (params, defaults) ->
    $.extend({}, @defaults, defaults, params)

class Collection extends Base
  constructor: (@model) ->

  find: (id, params, options = {}) ->
    record = new @model(id: id)
    @ajaxQueue(
      params, {
        type: options.method or Ajax.config.loadMethod
        url: options.url or Ajax.getURL(record)
        parallel: options.parallel
      }
    ).done(@recordsResponse)
     .fail(@failResponse)

  all: (params, options = {}) ->
    @ajaxQueue(
      params, {
        type: options.method or Ajax.config.loadMethod
        url: options.url or Ajax.getURL(@model)
        parallel: options.parallel
      }
    ).done(@recordsResponse)
     .fail(@failResponse)

  fetch: (params = {}, options = {}) ->
    if id = params.id
      delete params.id
      @find(id, params, options).done (record) =>
        @model.refresh(record, options)
    else
      @all(params, options).done (records) =>
        @model.refresh(records, options)

  # Private

  recordsResponse: (data, status, xhr) =>
    @model.trigger('ajaxSuccess', null, status, xhr)

  failResponse: (xhr, statusText, error) =>
    @model.trigger('ajaxError', null, xhr, statusText, error)

class Singleton extends Base
  constructor: (@record) ->
    @model = @record.constructor

  reload: (params, options = {}) ->
    @ajaxQueue(
      params, {
        type: options.method or Ajax.config.loadMethod
        url: options.url
        parallel: options.parallel
      }, @record
    ).done(@recordResponse(options))
     .fail(@failResponse(options))

  create: (params, options = {}) ->
    @ajaxQueue(
      params, {
        type: options.method or Ajax.config.createMethod
        contentType: 'application/json'
        data: @record.toJSON()
        url: options.url or Ajax.getCollectionURL(@record)
        parallel: options.parallel
      }
    ).done(@recordResponse(options))
     .fail(@failResponse(options))

  update: (params, options = {}) ->
    @ajaxQueue(
      params, {
        type: options.method or Ajax.config.updateMethod
        contentType: 'application/json'
        data: @record.toJSON()
        url: options.url
        parallel: options.parallel
      }, @record
    ).done(@recordResponse(options))
     .fail(@failResponse(options))

  destroy: (params, options = {}) ->
    @ajaxQueue(
      params, {
        type: options.method or Ajax.config.destroyMethod
        url: options.url
        parallel: options.parallel
      }, @record
    ).done(@recordResponse(options))
     .fail(@failResponse(options))

  # Private

  recordResponse: (options = {}) =>
    (data, status, xhr) =>

      Ajax.disable =>
        unless Spine.isBlank(data) or @record.destroyed
          # ID change, need to do some shifting
          if data.id and @record.id isnt data.id
            @record.changeID(data.id)
          # Update with latest data
          @record.refresh(data)

      @record.trigger('ajaxSuccess', data, status, xhr)
      options.done?.apply(@record)

  failResponse: (options = {}) =>
    (xhr, statusText, error) =>
      @record.trigger('ajaxError', xhr, statusText, error)
      options.fail?.apply(@record)

# Ajax endpoint
Model.host = ''

GenerateURL =
  include: (args...) ->
    args.unshift(encodeURIComponent(@id))
    Ajax.generateURL(@, args...)
  extend: (args...) ->
    Ajax.generateURL(@, args...)

Include =
  ajax: -> new Singleton(this)

  generateURL: GenerateURL.include

  url: GenerateURL.include

Extend =
  ajax: -> new Collection(this)

  generateURL: GenerateURL.extend

  url: GenerateURL.extend

Model.Ajax =
  extended: ->
    @fetch @ajaxFetch
    @change @ajaxChange
    @extend Extend
    @include Include

  # Private

  ajaxFetch: ->
    @ajax().fetch(arguments...)

  ajaxChange: (record, type, options = {}) ->
    return if options.ajax is false
    record.ajax()[type](options.ajax, options)

Model.Ajax.Methods =
  extended: ->
    @extend Extend
    @include Include

# Globals
Ajax.defaults   = Base::defaults
Ajax.Base       = Base
Ajax.Singleton  = Singleton
Ajax.Collection = Collection
Spine.Ajax      = Ajax
module?.exports = Ajax
