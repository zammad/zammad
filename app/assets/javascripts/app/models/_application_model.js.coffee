class App.Model extends Spine.Model
  @destroyBind: false

  constructor: ->
    super

    # delete object from local storage on destroy
    if !@constructor.destroyBind
      @bind( 'destroy', (e) ->
        className = Object.getPrototypeOf(e).constructor.className
        key = "collection::#{className}::#{e.id}"
        App.Store.delete(key)
      )

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

          # key exists not in hash || value is '' || value is undefined 
          if !( attribute.name of data['params'] ) || data['params'][attribute.name] is '' || data['params'][attribute.name] is undefined
            errors[attribute.name] = 'is required'

        # check confirm password
        if attribute.type is 'password' && data['params'][attribute.name] && "#{attribute.name}_confirm" of data['params']

          # get confirm password
          if data['params'][attribute.name] isnt data['params']["#{attribute.name}_confirm"]
            errors[attribute.name] = 'didn\'t match'
            errors["#{attribute.name}_confirm"] = ''

    # return error object
    return errors if !_.isEmpty(errors)

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

  @retrieve: ( id, callback, force ) ->
    if !force && App[ @className ].exists( id )
      data = App[ @className ].find( id )
      data = @_fillUp( data )
      if callback
        callback( data )
      return data
    else
      if force
        console.log 'debug', 'find forced to load!', @className, id
      else
        console.log 'debug', 'find not loaded!', @className, id
      if callback

        # execute callback if record got loaded
        col = @
        App[ @className ].one 'refresh', (record) ->
          delay = =>
            data = App[ @className ].find( id )
            if callback
              callback( data )
          window.setTimeout(delay, 200)

        # fetch object
        console.log 'debug', 'loading..' + @className +  '..', id
        App[ @className ].fetch( id: id )
        return true
      return false

  @subscribe: (callback, param = {}) ->
    if !@SUBSCRIPTION_COLLECTION
      @SUBSCRIPTION_COLLECTION = {}

      # subscribe and render data / fetch new data if triggered
      @bind(
        'refresh change'
        =>
          for key, callbackSingle of @SUBSCRIPTION_COLLECTION
            callbackSingle()
      )

      # trigger deleteAll() and fetch() on network notify
      events = "#{@className}:created #{@className}:updated #{@className}:destroy"
      App.Event.bind(
        events
        =>
          @deleteAll()
#          callbacks = =>
#            for key, callbackSingle of @SUBSCRIPTION_COLLECTION
#              callbackSingle()
#          @one 'refresh', (collection) =>
#            callbacks(collection)
          @fetch()

        'Collection::Subscribe::' + @className
      )


    key = @className + '-' + Math.floor( Math.random() * 99999 )
    @SUBSCRIPTION_COLLECTION[key] = callback

    # fetch init collection
    if param['initFetch'] is true
      @one 'refresh', (collection) =>
        callback(collection)
      @fetch()

    return key

  subscribe: (callback) ->
    if !App[ @constructor.className ]['SUBSCRIPTION_ITEM']
      App[ @constructor.className ]['SUBSCRIPTION_ITEM'] = {}
    if !App[ @constructor.className ]['SUBSCRIPTION_ITEM'][@id]
      App[ @constructor.className ]['SUBSCRIPTION_ITEM'][@id] = {}

      events = "#{@constructor.className}:created #{@constructor.className}:updated #{@constructor.className}:destroy"
      App.Event.bind(
        events
        (record) =>
          if @id.toString() is record.id.toString()
            App[ @constructor.className ].one 'refresh', (record) =>
              user = App[ @constructor.className ].find(@id)
              for key, callback of App[ @constructor.className ]['SUBSCRIPTION_ITEM'][@id]
                callback(user)
            App[ @constructor.className ].fetch( id: @id )
        'Item::Subscribe::' + @constructor.className
      )

    key = @constructor.className + '-' + Math.floor( Math.random() * 99999 )
    App[ @constructor.className ]['SUBSCRIPTION_ITEM'][@id][key] = callback
    return key

  @unsubscribe: (data) ->
    if @SUBSCRIPTION_ITEM
      for id, keys of @SUBSCRIPTION_ITEM
        if keys[data]
          delete keys[data]

    if @SUBSCRIPTION_COLLECTION
      if @SUBSCRIPTION_COLLECTION[data]
        delete @SUBSCRIPTION_COLLECTION[data]

  @_bindsEmpty: ->
    if @SUBSCRIPTION_ITEM
      for id, keys of @SUBSCRIPTION_ITEM
        return false if !_.isEmpty(keys)

    if @SUBSCRIPTION_COLLECTION && !_.isEmpty( @SUBSCRIPTION_COLLECTION )
      return false

    return true

  @_fillUp: (data) ->
    # nothing
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

    if params.filter
      all_complied = @_filter( all_complied, params.filter )

    if params.filterExtended
      all_complied = @_filterExtended( all_complied, params.filterExtended )

    if params.sortBy
      all_complied = @_sortBy( all_complied, params.sortBy )

    if params.order
      all_complied = @_order( all_complied, params.order )

    return all_complied

  @_sortBy: ( collection, attribute ) ->
    _.sortBy( collection, (item) ->
      return '' if item[ attribute ] is undefined || item[ attribute ] is null
      return item[ attribute ].toLowerCase()
    )

  @_order: ( collection, attribute ) ->
    if attribute is 'DESC'
      return collection.reverse()
    return collection

  @_filter: ( collection, filter ) ->
    for key, value of filter
      collection = _.filter( collection, (item) ->
        if item[ key ] is value
          return item
      )
    return collection

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
    return collection

  
