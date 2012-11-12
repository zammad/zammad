class App.Collection
  _instance = undefined

  @init: ->
    _instance = new _Singleton

  @load: ( args ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.load( args )

  @reset: ( args ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.reset( args )

  @find: ( type, id, callback, force ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.find( type, id, callback, force )

  @get: ( args ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.get( args )

  @all: ( type ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.all( type )

  @deleteAll: ( type ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.deleteAll( type )

  @findByAttribute: ( type, key, value ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.findByAttribute( type, key, value )

  @count: ( type ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.count( type )

  @fetch: ( type ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.fetch( type )

  @observe: (args) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.observe(args)

  @observeUnbindLevel: (level) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.observeUnbindLevel(level)

  @_observeStats: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance._observeStats()

class _Singleton extends Spine.Module
  @include App.Log

  constructor: (@args) ->

    # add trigger - bind new events
    App.Event.bind 'loadCollection', (data) =>

      # load collections
      if data.collections
        for type of data.collections

          @log 'Collection', 'debug', 'loadCollection:trigger', type, data.collections[type]
          @load( localStorage: data.localStorage, type: type, data: data.collections[type] )

    # add trigger - bind new events
    App.Event.bind 'resetCollection', (data) =>

      # load collections
      if data.collections
        for type of data.collections

          @log 'Collection', 'debug', 'resetCollection:trigger', type, data.collections[type]
          @reset( localStorage: data.localStorage, type: type, data: data.collections[type] )

    # find collections to load
    @_loadCollectionAll()

  _loadCollectionAll: ->
    list = App.Store.list()
    for key in list
      parts = key.split('::')
      if parts[0] is 'collection'
        data = App.Store.get( key )
        if data && data.localStorage
          @log 'Collection', 'debug', 'load INIT', data
          @load( data )

  reset: (params) ->
    @log 'Collection', 'debug', 'reset', params

    # empty in-memory
    App[ params.type ].refresh( [], { clear: true } )

    # remove permanent storage
    list = App.Store.list()
    for key in list
      parts = key.split('::')
      if parts[0] is 'collection' && parts[1] is params.type
        App.Store.delete(key)

    # load with new data
    @load(params)

  load: (params) ->
    @log 'Collection', 'debug', 'load', params

    return if _.isEmpty( params.data )

    localStorage = params.localStorage

    # load full array once
    if _.isArray( params.data )
#      console.log( 'load ARRAY', params.data)
      App[ params.type ].refresh( params.data )

      # remember in store if not already requested from local storage
      if !localStorage
        for object in params.data
          App.Store.write( 'collection::' + params.type + '::' + object.id, { type: params.type, localStorage: true, data: [ object ] } )
      return

    # load data from object
#    if _.isObject( params.data )
    for key, object of params.data
#      console.log( 'load OB', object)
      App[ params.type ].refresh( object )

      # remember in store if not already requested from local storage
      if !localStorage
        App.Store.write( 'collection::' + params.type + '::' + object.id, { type: params.type, localStorage: true, data: [ object ] } )

  find: ( type, id, callback, force ) ->

#    console.log( 'find', type, id, force )
#    if App[type].exists( id ) && !callback
    if !force && App[type].exists( id )
#      console.log( 'find exists', type, id )
      data = App[type].find( id )
      if callback
        callback( data )
    else
      if force
        @log 'Collection', 'debug', 'find forced to load!', type, id
      else
        @log 'Collection', 'debug', 'find not loaded!', type, id
      if callback

        # execute callback if record got loaded
        App[type].one 'refresh', ->
          console.log 'loaded..' + type +  '..', id

          data = App.Collection.find( type, id )
          callback( data )

        # fetch object
        console.log 'loading..' + type +  '..', id
        App[type].fetch( id: id )
        return true
      return false

   # users
    if type == 'User'

      # set socal media links
      if data['accounts']
        for account of data['accounts']
          if account == 'twitter'
            data['accounts'][account]['link'] = 'http://twitter.com/' + data['accounts'][account]['username']
          if account == 'facebook'
            data['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + data['accounts'][account]['uid']

      # set image url
      if data && !data['image']
        data['image'] = 'http://placehold.it/48x48'

      return data

    # tickets
    else if type == 'Ticket'

      # priority
      data.ticket_priority = @find( 'TicketPriority', data.ticket_priority_id )

      # state
      data.ticket_state = @find( 'TicketState', data.ticket_state_id )

      # group
      data.group = @find( 'Group', data.group_id )

      # customer
      if data.customer_id
        data.customer = @find( 'User', data.customer_id )

      # owner
      if data.owner_id
        data.owner = @find( 'User', data.owner_id )

      # add created & updated
      if data.created_by_id
        data.created_by = @find( 'User', data.created_by_id )
      if data.updated_by_id
        data.updated_by = @find( 'User', data.updated_by_id )

      return data

    # articles
    else if type == 'TicketArticle'

      # add created & updated
      data.created_by = @find( 'User', data.created_by_id )

      # add possible actions
      data.article_type = @find( 'TicketArticleType', data.ticket_article_type_id )
      data.article_sender = @find( 'TicketArticleSender', data.ticket_article_sender_id )

      return data

    # history
    else if type == 'History'

      # add user
      data.created_by = @find( 'User', data.created_by_id )

      # add possible actions
      if data.history_attribute_id
        data.attribute = @find( 'HistoryAttribute', data.history_attribute_id )
      if data.history_type_id
        data.type      = @find( 'HistoryType', data.history_type_id )
      if data.history_object_id
        data.object    = @find( 'HistoryObject', data.history_object_id )

      return data

    else
      return data

  get: (params) ->
    @log 'Collection', 'debug', 'get', params
    App[ params.type ].refresh( object, options: { clear: true } )

  all: (params) ->
    all = App[ params.type ].all()
    all_complied = []
    for item in all
      item_new = @find( params.type, item.id )
      all_complied.push item_new

    if params.filter
      all_complied = @_filter( all_complied, params.filter )

    if params.filterExtended
      all_complied = @_filterExtended( all_complied, params.filterExtended )

    if params.sortBy
      all_complied = @_sortBy( all_complied, params.sortBy )

    if params.order
      all_complied = @_order( all_complied, params.order )

    return all_complied

  deleteAll: (type) ->
    App[type].deleteAll()

  findByAttribute: ( type, key, value ) ->
    App[type].findByAttribute( key, value )

  count: ( type ) ->
    App[type].count()

  fetch: ( type ) ->
    App[type].fetch()

  _sortBy: ( collection, attribute ) ->
    _.sortBy( collection, (item) ->
      return '' if item[ attribute ] is undefined || item[ attribute ] is null
      return item[ attribute ].toLowerCase()
    )

  _order: ( collection, attribute ) ->
    if attribute is 'DESC'
      return collection.reverse()
    return collection

  _filter: ( collection, filter ) ->
    for key, value of filter
      collection = _.filter( collection, (item) ->
        if item[ key ] is value
          return item
      )
    return collection

  _filterExtended: ( collection, filters ) ->
    collection = _.filter( collection, (item) ->

      # check all filters
      for filter in filters

        # all conditions need match
        matchInner = undefined
        for key, value of filter

          if matchInner isnt false
            reg = new RegExp( value, 'i' )
            if item[ key ] isnt undefined && item[ key ] isnt null && item[ key ].match( reg )
              matchInner = true
            else
              matchInner = false

        # if all matched, add item to new collection
        if matchInner is true
          return item

      return
    )
    return collection

  observeUnbindLevel: (level) ->
    return if !@observeCurrent
    return if !@observeCurrent[level]
    for observers in @observeCurrent[level]
      @_observeUnbind( observers )
    @observeCurrent[level] = []

  observe: (data) ->
    if !@observeCurrent
      @observeCurrent = {}

    if !@observeCurrent[ data.level ]
      @observeCurrent[ data.level ] = []

    @observeCurrent[ data.level ].push data.collections
    for observe in data.collections
      events = observe.event.split(' ')
      for event in events
        if App[ observe.collection ]
          App[ observe.collection ].bind( event, observe.callback )

  _observeUnbind: (observers) ->
    for observe in observers
      events = observe.event.split(' ')
      for event in events
        if App[ observe.collection ]
          App[ observe.collection ].unbind( event, observe.callback )

  _observeStats: ->
    @observeCurrent