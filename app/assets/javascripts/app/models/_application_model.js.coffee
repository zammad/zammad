class App.Model extends Spine.Model
  @destroyBind: false
  @apiPath: App.Config.get('api_path')

  constructor: ->
    super

    # delete object from local storage on destroy
    if !@constructor.destroyBind
      @bind( 'destroy', (e) ->
        className = Object.getPrototypeOf(e).constructor.className
        key = "collection::#{className}::#{e.id}"
        App.Store.delete(key)
      )

  uiUrl: ->
    '#'

  translate: ->
    App[ @constructor.className ].configure_translate

  objectDisplayName: ->
    @constructor.className

  displayName: ->
    return @name if @name
    if @realname
      return "#{@realname} <#{@email}>"
    if @firstname
      name = @firstname
      if @lastname
        if name
         name = name + ' '
        name = name + @lastname
      return name
    if @email
      return @email
    if @title
      return @title
    if @subject
      return @subject
    return '???'

  displayNameLong: ->
    return @name if @name
    if @firstname
      name = @firstname
      if @lastname
        if name
         name = name + ' '
        name = name + @lastname
      if @organization
        if typeof @organization is 'object'
          name = "#{name} (#{@organization.name})"
        else
          name = "#{name} (#{@organization})"
      else if @department
        name = "#{name} (#{@department})"
      return name
    return '???'

  @validate: ( data = {} ) ->
    return if !data['model'].configure_attributes

    # check attributes/each attribute of object
    errors = {}
    for attribute in data['model'].configure_attributes

      # only if attribute is not read only
      if !attribute.readonly

        # check required // if null is defined && null is false
        if 'null' of attribute && !attribute[null]

          # check :: fields
          parts = attribute.name.split '::'
          if parts[0] && !parts[1]

            # key exists not in hash || value is '' || value is undefined
            if !( attribute.name of data['params'] ) || data['params'][attribute.name] is '' || data['params'][attribute.name] is undefined
              errors[attribute.name] = 'is required'

          else if parts[0] && parts[1] && !parts[2]

            # key exists not in hash || value is '' || value is undefined
            if !data.params[parts[0]] || !( parts[1] of data.params[parts[0]] ) || data.params[parts[0]][parts[1]] is '' || data.params[parts[0]][parts[1]] is undefined
              errors[attribute.name] = 'is required'

          else
            throw "can't parse '#{attribute.name}'"

        # check confirm password
        if attribute.type is 'password' && data['params'][attribute.name] && "#{attribute.name}_confirm" of data['params']

          # get confirm password
          if data['params'][attribute.name] isnt data['params']["#{attribute.name}_confirm"]
            errors[attribute.name] = 'didn\'t match'
            errors["#{attribute.name}_confirm"] = ''

    # return error object
    if !_.isEmpty(errors)
      console.log 'error', 'validation vailed', errors
      return errors

    # return no errors
    return

  validate: ->
    App.Model.validate(
      model: @constructor,
      params: @,
    )

  isOnline: ->
    return false if !@id
    return true if typeof @id is 'number' # in case of real database id
    return true if @id[0] isnt 'c'
    return false

  @fullLocal: (id) ->
    @_fillUp( App[ @className ].find( id ) )

  @full: (id, callback = false, force = false, bind = false) ->
    url = "#{@url}/#{id}?full=true"

    # subscribe and reload data / fetch new data if triggered
    subscribeId = undefined
    if bind
      subscribeId = App[ @className ].subscribe_item(id, callback)

    # execute if object already exists
    if !force && App[ @className ].exists( id )
      data = App[ @className ].find( id )
      data = @_fillUp( data )
      if callback
        callback( data )
      return subscribeId

    # store callback and requested id
    if !@FULL_CALLBACK
      @FULL_CALLBACK = {}
    if !@FULL_CALLBACK[id]
      @FULL_CALLBACK[id] = {}
    if callback
      key = @className + '-' + Math.floor( Math.random() * 99999 )
      @FULL_CALLBACK[id][key] = callback

    if !@FULL_FETCH
      @FULL_FETCH = {}
    if !@FULL_FETCH[id]
      @FULL_FETCH[id] = true
      App.Ajax.request(
        type:  'GET'
        url:   url
        processData: true,
        success: (data, status, xhr) =>
          @FULL_FETCH[ data.id ] = false

          # full / load assets
          if data.assets
            App.Collection.loadAssets( data.assets )

          # find / load object
          else
            App[ @className ].refresh( data )

          # execute callbacks
          if @FULL_CALLBACK[ data.id ]
            for key, callback of @FULL_CALLBACK[ data.id ]
              callback( @_fillUp( App[ @className ].find( data.id ) ) )
              delete @FULL_CALLBACK[ data.id ][ key ]
            if _.isEmpty @FULL_CALLBACK[ data.id ]
              delete @FULL_CALLBACK[ data.id ]

        error: (xhr, statusText, error) =>
          console.log(statusText, error)
      )
    subscribeId

  @retrieve: ( id, callback, force ) ->
    if !force && App[ @className ].exists( id )
      data = App[ @className ].find( id )
      data = @_fillUp( data )
      if callback
        callback( data )
      return data

    if force
      console.log 'debug', 'find forced to load!', @className, id
    else
      console.log 'debug', 'find not loaded, load now!', @className, id
    if callback

      # store callback and requested id
      if !@RETRIEVE_CALLBACK
        @RETRIEVE_CALLBACK = {}
      if !@RETRIEVE_CALLBACK[id]
        @RETRIEVE_CALLBACK[id] = {}
      key = @className + '-' + Math.floor( Math.random() * 99999 )
      @RETRIEVE_CALLBACK[id][key] = callback

      # bind refresh event
      if !@RETRIEVE_BIND
        @RETRIEVE_BIND = true

        # check if bind for requested id exists
        App[ @className ].bind 'refresh', (records) ->
          for record in records
            if @RETRIEVE_CALLBACK[ record.id ]
              for key, callback of @RETRIEVE_CALLBACK[ record.id ]
                data = callback( @_fillUp( App[ @className ].find( record.id ) ) )
                delete @RETRIEVE_CALLBACK[ record.id ][ key ]
              if _.isEmpty @RETRIEVE_CALLBACK[ record.id ]
                delete @RETRIEVE_CALLBACK[ record.id ]
          @fetchActive = false

      # fetch object
      console.log 'debug', 'loading..' + @className +  '..', id
      if !@fetchActive
        @fetchActive = true
        App[ @className ].fetch( id: id )
      return true
    return false

  ###

  methodWhichIsCalledAtLocalOrServerSiteChange = (changedItems) ->
    console.log("Collection has changed", changedItems, localOrServer)

  params =
    initFetch: true # fetch inital collection

  @subscribeId = App.Model.subscribe( methodWhichIsCalledAtLocalOrServerSiteChange )

  ###

  @subscribe: (callback, param = {}) ->
    if !@SUBSCRIPTION_COLLECTION
      @SUBSCRIPTION_COLLECTION = {}

      # subscribe and render data / fetch new data if triggered
      @bind(
        'refresh change'
        (items) =>
          for key, callback of @SUBSCRIPTION_COLLECTION
            callback(items)
      )

      # fetch() all on network notify
      events = "#{@className}:create #{@className}:update #{@className}:destroy"
      App.Event.bind(
        events
        =>
          @fetch( {}, { clear: true } )

        'Collection::Subscribe::' + @className
      )

    key = @className + '-' + Math.floor( Math.random() * 99999 )
    @SUBSCRIPTION_COLLECTION[key] = callback

    # fetch init collection
    if param.initFetch is true
      @one 'refresh', (collection) =>
        callback(collection)
      @fetch( {}, { clear: true } )

    # return key
    key

  ###

  methodWhichIsCalledAtLocalOrServerSiteChange = (changedItem, localOrServer) ->
    console.log("Item has changed", changedItem, localOrServer)

  model = App.Model.find(1)
  @subscribeId = model.subscribe( methodWhichIsCalledAtLocalOrServerSiteChange )

  ###

  subscribe: (callback, type) ->

    # remember record id and callback
    App[ @constructor.className ].subscribe_item(@id, callback)

  @subscribe_item: (id, callback) ->

    # init bind
    if !@_subscribe_item_bindDone
      @_subscribe_item_bindDone = true

      # subscribe and render data after local change
      @bind(
        'change'
        (items) =>

          # check if result is array or singel item
          if !_.isArray(items)
            items = [items]

          for item in items
            for key, callback of App[ @className ].SUBSCRIPTION_ITEM[ item.id ]
              item = App[ @className ]._fillUp( item )
              callback(item, 'change')
      )

      @changeTable = {}
      @bind(
        'refresh'
        (items) =>

          # check if result is array or singel item
          if !_.isArray(items)
            items = [items]

          for item in items
            for key, callback of App[ @className ].SUBSCRIPTION_ITEM[ item.id ]

              # only trigger callbacks if object has changed
              if !@changeTable[key] || @changeTable[key] isnt item.updated_at
                @changeTable[key] = item.updated_at
                item = App[ @className ]._fillUp( item )
                callback(item, 'refresh')
      )

      # subscribe and render data after server change
      events = "#{@className}:create #{@className}:update #{@className}:destroy"
      App.Event.bind(
        events
        (item) =>
          if @SUBSCRIPTION_ITEM && @SUBSCRIPTION_ITEM[ item.id ]
            genericObject = undefined
            if App[ @className ].exists( item.id )
              genericObject = App[ @className ].find( item.id )

            callback = =>
              if !genericObject || ( new Date(item.updated_at).toString() isnt new Date(genericObject.updated_at).toString() )
                @full( item.id, false, true )

            App.Delay.set(callback, 800, item.id, "full-#{@className}")

        'Item::Subscribe::' + @className
      )

    # remember item callback
    if !@SUBSCRIPTION_ITEM
      @SUBSCRIPTION_ITEM = {}
    if !@SUBSCRIPTION_ITEM[id]
      @SUBSCRIPTION_ITEM[id] = {}
    key = @className + '-' + Math.floor( Math.random() * 99999 )
    @SUBSCRIPTION_ITEM[id][key] = callback
    key

  ###

  unsubscribe from model or collection

  App.Model.unsubscribe( @subscribeId )

  ###

  @unsubscribe: (subscribeId) ->
    if @SUBSCRIPTION_ITEM
      for id, keys of @SUBSCRIPTION_ITEM
        if keys[subscribeId]
          delete keys[subscribeId]

    if @SUBSCRIPTION_COLLECTION
      if @SUBSCRIPTION_COLLECTION[subscribeId]
        delete @SUBSCRIPTION_COLLECTION[subscribeId]

  @_bindsEmpty: ->
    if @SUBSCRIPTION_ITEM
      for id, keys of @SUBSCRIPTION_ITEM
        return false if !_.isEmpty(keys)

    if @SUBSCRIPTION_COLLECTION && !_.isEmpty( @SUBSCRIPTION_COLLECTION )
      return false

    return true

  @_fillUp: (data) ->

    # fill up via relations
    if App[ @className ].configure_attributes
      for attribute in App[ @className ].configure_attributes
        if attribute.relation
          if App[ attribute.relation ]
            withoutId = attribute.name.substr( 0, attribute.name.length - 3 )
            if attribute.name.substr( attribute.name.length - 3, attribute.name.length ) is '_id'
              if data[attribute.name]
                if App[ attribute.relation ].exists( data[attribute.name] )
                  item = App[ attribute.relation ].find( data[attribute.name] )
                  item = App[ attribute.relation ]._fillUp(item)
                  data[ withoutId ] = item
                else
                  console.log("ERROR, cant find #{ attribute.name } App.#{ attribute.relation }.find(#{ data[attribute.name] }) for '#{ data.constructor.className }' #{ data.displayName() }")
    data

  @search: (params) ->
    all = @all()
    all_complied = []
    if !params
      for item in all
        item_new = @find( item.id )
        all_complied.push @_fillUp(item_new)
      return all_complied
    for item in all
      item_new = @find( item.id )
      all_complied.push @_fillUp(item_new)

    # filter search
    if params.filter
      all_complied = @_filter( all_complied, params.filter )

    # use extend filter search
    if params.filterExtended
      all_complied = @_filterExtended( all_complied, params.filterExtended )

    # sort by
    all_complied = @_sortBy( all_complied, params.sortBy )

    # order
    if params.order
      all_complied = @_order( all_complied, params.order )

    all_complied

  @_sortBy: ( collection, attribute ) ->
    _.sortBy( collection, (item) ->

      # set displayName as default sort attribute
      if !attribute
        attribute = 'displayName'

      # check if displayName exists
      if attribute is 'displayName'
        if item.displayName
          return item.displayName().toLowerCase()
        else
          attribute = 'name'

      return '' if item[ attribute ] is undefined
      return '' if item[ attribute ] is null

      # return value
      item[ attribute ].toLowerCase()
    )

  @_order: ( collection, attribute ) ->
    if attribute is 'DESC'
      return collection.reverse()
    collection

  @_filter: ( collection, filter ) ->
    for key, value of filter
      collection = _.filter( collection, (item) ->
        if item[ key ] is value
          return item
      )
    collection

  @_filterExtended: ( collection, filters ) ->
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
    collection
