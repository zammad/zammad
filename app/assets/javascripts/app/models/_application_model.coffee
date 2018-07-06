class App.Model extends Spine.Model
  @apiPath: App.Config.get('api_path')

  constructor: ->
    super

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
    if !_.isEmpty(@firstname)
      name = @firstname
    if !_.isEmpty(@lastname)
      if _.isEmpty(name)
        name = ''
      else
        name = name + ' '
      name = name + @lastname
    return name if !_.isEmpty(name)
    if @email
      return @email
    if @title
      return @title
    if @subject
      return @subject
    if @phone
      return @phone
    if @login
      return @login
    return '???'

  displayNameLong: ->
    return @name if @name
    if !_.isEmpty(@firstname)
      name = @firstname
    if !_.isEmpty(@lastname)
      if _.isEmpty(name)
        name = ''
      else
        name = name + ' '
      name = name + @lastname
    if !_.isEmpty(name)
      if !_.isEmpty(@organization)
        if typeof @organization is 'object'
          name = "#{name} (#{@organization.name})"
        else
          name = "#{name} (#{@organization})"
      else if !_.isEmpty(@department)
        name = "#{name} (#{@department})"
    return name if !_.isEmpty(name)
    if @email
      return @email
    if @title
      return @title
    if @subject
      return @subject
    if @phone
      return @phone
    if @login
      return @login
    return '???'

  icon: (user) ->
    ''

  iconTitle: (user) ->
    ''

  iconActivity: (user) ->
    ''

  @validate: (data = {}) ->

    # based on model attrbutes
    if App[ data['model'] ] && App[ data['model'] ].attributesGet
      attributes = App[ data['model'] ].attributesGet(data['screen'])

    # based on custom attributes
    else if data['model'].configure_attributes
      attributes = App.Model.attributesGet(data['screen'], data['model'].configure_attributes)

    # check required_if attributes
    for attributeName, attribute of attributes
      if attribute['required_if']

        for key, values of attribute['required_if']

          localValues = data['params'][key]
          if !_.isArray( localValues )
            localValues = [ localValues ]

          match = false
          for value in values
            if localValues
              for localValue in localValues
                if value && localValue && value.toString() is localValue.toString()
                  match = true
          if match is true
            attribute['null'] = false
          else
            attribute['null'] = true

    # check attributes/each attribute of object
    errors = {}
    for attributeName, attribute of attributes

      # only if attribute is not read only
      if !attribute.readonly

        # check required // if null is defined && null is false
        if 'null' of attribute && !attribute['null']

          # check :: fields
          parts = attribute.name.split '::'
          if parts[0] && !parts[1]

            # key exists not in hash || value is '' || value is undefined
            if !( attributeName of data['params'] ) || data['params'][attributeName] is '' || data['params'][attributeName] is undefined || data['params'][attributeName] is null
              errors[attributeName] = 'is required'

          else if parts[0] && parts[1] && !parts[2]

            # key exists not in hash || value is '' || value is undefined
            if !data.params[parts[0]] || !( parts[1] of data.params[parts[0]] ) || data.params[parts[0]][parts[1]] is '' || data.params[parts[0]][parts[1]] is undefined || data.params[parts[0]][parts[1]] is null
              errors[attributeName] = 'is required'

          else
            throw "can't parse '#{attribute.name}'"

        # check confirm password
        if attribute.type is 'password' && data['params'][attributeName] && "#{attributeName}_confirm" of data['params']

          # get confirm password
          if data['params'][attributeName] isnt data['params']["#{attributeName}_confirm"]
            errors[attributeName] = 'didn\'t match'
            errors["#{attributeName}_confirm"] = ''

        # check email
        if attribute.type is 'email' && data['params'][attributeName]
          if !data['params'][attributeName].match(/\S+@\S+\.\S+/)
            errors[attributeName] = 'invalid'
          if data['params'][attributeName].match(/ /)
            errors[attributeName] = 'invalid'

        # check datetime
        if attribute.tag is 'datetime'
          if data['params'][attributeName] is 'invalid'
            errors[attributeName] = 'invalid'

          # validate value

        # check date
        if attribute.tag is 'date'
          if data['params'][attributeName] is 'invalid'
            errors[attributeName] = 'invalid'

          # validate value

    # return error object
    if !_.isEmpty(errors)
      App.Log.error('Model', 'validation failed', errors)
      return errors

    # return no errors
    return

  ###

set new attributes of model (remove already available attributes)

  App.Model.attributesSet(attributes)

  ###

  @attributesSet: (attributes) ->

    configure_attributes = App[ @.className ].configure_attributes
    attributesNew = []
    for localAttribute in configure_attributes
      found = false
      for attribute in attributes
        if attribute.name is localAttribute.name
          found = true
          break
      if !found
        attributesNew.push localAttribute
    for attribute in attributes
      App[@.className].attributes.push attribute.name
      attributesNew.push attribute
    App[@.className].configure_attributes = attributesNew

  ###

  attributes = App.Model.attributesGet(optionalScreen, optionalAttributesList)

  returns
    {
      'name': {
        name:    'name'
        display: 'Name'
        tag:     'input'
        type:    'text'
        limit:   100
        null:    false
      },
      'assignment_timeout': {
        name:    'assignment_timeout'
        display: 'Assignment Timeout'
        tag:     'input'
        type:    'text'
        limit:   100
        null:    false
      },
    }

  ###

  @attributesGet: (screen = undefined, attributes = false, noDefaultAttributes = false) ->
    if !attributes
      attributes = clone(App[@.className].configure_attributes, true)
    else
      attributes = clone(attributes, true)

    # in case if no configure_attributes exist
    return {} if !attributes

    # check params of screen if screen is requested
    attributesNew = {}
    if screen
      for attribute in attributes
        if attribute && attribute.screen && attribute.screen[screen] && (!_.isEmpty(attribute.screen[screen]) && (attribute.screen[screen].shown is true || attribute.screen[screen].shown is undefined))
          for item, value of attribute.screen[screen]
            attribute[item] = value
          attributesNew[ attribute.name ] = attribute

    # if no screen is given or no attribute has this screen - use default attributes
    if (!screen || _.isEmpty(attributesNew)) && !noDefaultAttributes
      for attribute in attributes
        attributesNew[ attribute.name ] = attribute

    attributesNew

  validate: (params = {}) ->
    App.Model.validate(
      model:  @constructor.className
      params: @
      screen: params.screen
    )

  isOnline: ->
    return false if !@id
    return true if typeof @id is 'number' # in case of real database id
    return true if @id[0] isnt 'c'
    return false

  # App.Model.fullLocal(id)
  @fullLocal: (id) ->
    @_fillUp( App[@className].find(id) )

  # App.Model.full(id, callback, force, bind)
  @full: (id, callback = false, force = false, bind = false) ->
    url = "#{@url}/#{id}?full=true"

    # subscribe and reload data / fetch new data if triggered
    subscribeId = undefined
    if bind
      subscribeId = App[@className].subscribeItem(id, callback)

    # execute if object already exists
    if !force && App[@className].exists(id)
      data = App[@className].find(id)
      data = @_fillUp(data)
      if callback
        callback(data, 'full')
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
      App.Log.debug('Model', "fetch #{@className}.find(#{id}) from server", url)
      App.Ajax.request(
        type:  'GET'
        url:   url
        processData: true,
        success: (data, status, xhr) =>
          @FULL_FETCH[id] = false

          App.Log.debug('Model', "got #{@className}.find(#{id}) from server", data)

          # full / load assets
          if data.assets
            App.Collection.loadAssets(data.assets, targetModel: @className)

          # find / load object
          else
            App[@className].refresh(data)

          # execute callbacks
          if @FULL_CALLBACK[data.id]
            for key, callback of @FULL_CALLBACK[data.id]
              callback( @_fillUp( App[@className].find(data.id) ) )
              delete @FULL_CALLBACK[data.id][key]
            if _.isEmpty @FULL_CALLBACK[data.id]
              delete @FULL_CALLBACK[data.id]

        error: (xhr, statusText, error) =>
          @FULL_FETCH[id] = false
          App.Log.error('Model', statusText, error, url)
      )
    subscribeId

  ###

  methodWhichIsCalledAtLocalOrServerSiteChange = (changedItems) ->
    console.log("Collection has changed", changedItems, localOrServer)

  # localOrServer can be:
  #  change -> has changed local
  #  destroy -> has beed removed local or remote
  #  refresh -> has been changed remote

  params =
    initFetch: true # fetch initial collection

  @subscribeId = App.Model.subscribe(methodWhichIsCalledAtLocalOrServerSiteChange)

  ###

  @subscribe: (callback, param = {}) ->

    # global bind to changes
    if !@SUBSCRIPTION_COLLECTION
      @SUBSCRIPTION_COLLECTION = {}

      # subscribe and render data / fetch new data if triggered
      @bind(
        'refresh'
        (items, options) =>
          if !_.isArray(items)
            items = [items]
          App.Log.debug('Model', "local collection refresh #{@className}", items)
          for key, callback of @SUBSCRIPTION_COLLECTION
            callback(items, 'refresh')
      )
      @bind(
        'change'
        (items, subEvent) =>
          return if subEvent is 'destroy'
          if !_.isArray(items)
            items = [items]
          App.Log.debug('Model', "local collection change #{@className}", items)
          for key, callback of @SUBSCRIPTION_COLLECTION
            callback(items, 'change')
      )
      @bind(
        'destroy'
        (items) =>
          if !_.isArray(items)
            items = [items]
          App.Log.debug('Model', "local collection destroy #{@className}", items)
          for key, callback of @SUBSCRIPTION_COLLECTION
            callback(items, 'destroy')
      )

      # fetch() all on network notify
      events = "#{@className}:create #{@className}:update #{@className}:touch #{@className}:destroy"
      App.Event.bind(
        events
        =>
          return if _.isEmpty(@SUBSCRIPTION_COLLECTION)
          App.Log.debug('Model', "server notify collection change #{@className}")
          callback = =>
            @fetchFull(
              ->
              clear: true
            )
          App.Delay.set(callback, 200, "fullcollection-#{@className}", "model-#{@className}")

        "Collection::Subscribe::#{@className}"
      )

    key = "#{@className}-#{Math.floor(Math.random() * 99999)}"
    @SUBSCRIPTION_COLLECTION[key] = callback

    # fetch init collection
    if param.initFetch is true
      clear = true
      if param.clear is true || param.clear is false
        clear = param.clear
      if !@initFetchActives && @count() is 0
        @initFetchActive = true
        @one('refresh', (collection) =>
          @initFetchActive = false
          callback(collection)
        )
        @fetchFull(
          ->
          clear: clear
        )
      else
        callback(@all())

    # return key
    key

  ###

  methodWhichIsCalledAtLocalOrServerSiteChange = (changedItem, localOrServer) ->
    console.log("Item has changed", changedItem, localOrServer)

  # localOrServer can be:
  #  change -> has changed local
  #  destroy -> has been removed local or remote
  #  refresh -> has been changed remote

  model = App.Model.find(1)
  @subscribeId = model.subscribe(methodWhichIsCalledAtLocalOrServerSiteChange)

  ###

  subscribe: (callback, type) ->

    # remember record id and callback
    App[ @constructor.className ].subscribeItem(@id, callback)

  @subscribeItem: (id, callback) ->

    # init bind
    if !@_subscribeItemBindDone
      @_subscribeItemBindDone = true

      # subscribe and render data after local change
      @bind(
        'change'
        (items) =>

          # check if result is array or singel item
          if !_.isArray(items)
            items = [items]
          App.Log.debug('Model', "local change #{@className}", items)
          for item in items
            for key, callback of App[@className].SUBSCRIPTION_ITEM[ item.id ]
              callback(App[@className]._fillUp(item), 'change')
      )
      @bind(
        'destroy'
        (items) =>

          # check if result is array or singel item
          if !_.isArray(items)
            items = [items]
          App.Log.debug('Model', "local destroy #{@className}", items)
          for item in items
            for key, callback of App[@className].SUBSCRIPTION_ITEM[ item.id ]
              callback(App[@className]._fillUp(item), 'destroy')
      )

      @changeTable = {}
      @bind(
        'refresh'
        (items) =>

          # check if result is array or singel item
          if !_.isArray(items)
            items = [items]
          App.Log.debug('Model', "local refresh #{@className}", items)
          for item in items
            for key, callback of App[@className].SUBSCRIPTION_ITEM[ item.id ]

              # only trigger callbacks if object has changed
              if !@changeTable[key] || @changeTable[key] < item.updated_at
                @changeTable[key] = item.updated_at
                callback(App[@className]._fillUp(item), 'refresh')
      )

      # subscribe and render data after server change
      events = "#{@className}:create #{@className}:update #{@className}:touch"
      App.Event.bind(
        events
        (item) =>
          return if !@SUBSCRIPTION_ITEM || !@SUBSCRIPTION_ITEM[ item.id ]
          App.Log.debug('Model', "server change on #{@className}.find(#{item.id}) #{item.updated_at}")
          callback = =>
            genericObject = undefined
            if App[@className].exists(item.id)
              genericObject = App[@className].find(item.id)
            if !genericObject || new Date(item.updated_at) > new Date(genericObject.updated_at)
              App.Log.debug('Model', "request #{@className}.find(#{item.id}) from server")
              @full(item.id, false, true)
          App.Delay.set(callback, 600, "full-#{item.id}", "model-#{@className}")
        "Item::Subscribe::#{@className}"
      )

      events = "#{@className}:destroy"
      App.Event.bind(
        events
        (item) =>
          return if !@SUBSCRIPTION_ITEM || !@SUBSCRIPTION_ITEM[ item.id ]
          return if !App[@className].exists(item.id)
          genericObject = App[@className].find(item.id)
          App.Log.debug('Model', "server delete on #{@className}.find(#{item.id}) #{item.updated_at}")
          callback = ->
            genericObject.trigger('destroy', genericObject)
          App.Delay.set(callback, 500, "delete-#{item.id}", "model-#{@className}")
        "Item::SubscribeDelete::#{@className}"
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

  App.Model.unsubscribe(@subscribeId)

  ###

  @unsubscribe: (subscribeId) ->
    if @SUBSCRIPTION_ITEM
      for id, keys of @SUBSCRIPTION_ITEM
        if keys[subscribeId]
          delete keys[subscribeId]

    if @SUBSCRIPTION_COLLECTION
      if @SUBSCRIPTION_COLLECTION[subscribeId]
        delete @SUBSCRIPTION_COLLECTION[subscribeId]

  ###

  fetch full collection (with assets)

  App.Model.fetchFull(@callback)

  App.Model.fetchFull(
    @callback
    clear: true
    force: false # only do server call if no record exsits
  )


  ###
  @fetchFull: (callback, params = {}) ->
    url = "#{@url}/?full=true"
    App.Log.debug('Model', "fetchFull collection #{@className}", url)

    # request already active, queue callback
    queueManagerName = "#{@className}::fetchFull"
    if params.force is false && App[@className].count() isnt 0
      if callback
        localCallback = =>
          callback(App[@className].all(), 'full')
        App.QueueManager.add(queueManagerName, localCallback)
        App.QueueManager.run(queueManagerName)
      return

    if callback
      localCallback = =>
        callback(App[@className].all())
      App.QueueManager.add(queueManagerName, localCallback)

    return if @fetchFullActive && @fetchFullActive > new Date().getTime() - 500
    @fetchFullActive = new Date().getTime()
    App.Ajax.request(
      type:  'GET'
      url:   url
      processData: true,
      success: (data, status, xhr) =>
        @fetchFullActive = false

        App.Log.debug('Model', "got fetchFull collection #{@className}", data)

        # clear collection
        if params.clear
          App[@className].deleteAll()

        # full / load assets
        if data.assets
          App.Collection.loadAssets(data.assets, targetModel: @className)

          # in case of no record_ids are there, no inital render is fired
          if data.record_ids && _.isEmpty(data.record_ids)
            App[@className].trigger('refresh', [])

        # find / load object
        else
          App[@className].refresh(data)

        App.QueueManager.run(queueManagerName)

      error: (xhr, statusText, error) =>
        @fetchFullActive = false
        App.Log.error('Model', statusText, error, url)
    )

  @_bindsEmpty: ->
    if @SUBSCRIPTION_ITEM
      for id, keys of @SUBSCRIPTION_ITEM
        return false if !_.isEmpty(keys)

    if @SUBSCRIPTION_COLLECTION && !_.isEmpty(@SUBSCRIPTION_COLLECTION)
      return false

    return true

  @_fillUp: (data, classNames = []) ->

    # fill up via relations
    return data if !App[@className].configure_attributes
    for attribute in App[@className].configure_attributes

      # lookup relations
      if attribute.relation

        # relations - not calling object it self, to prevent loops
        if !_.contains(classNames, @className)

          # only if relation model exists
          if App[attribute.relation]
            withoutId = attribute.name.substr(0, attribute.name.length - 3)
            if attribute.name.substr(attribute.name.length - 3, attribute.name.length) is '_id'
              if data[attribute.name]

                # only if relation record exists in collection
                if App[ attribute.relation ].exists(data[attribute.name])
                  item = App[attribute.relation].findNative(data[attribute.name])
                  item = App[attribute.relation]._fillUp(item, classNames.concat(@className))
                  data[withoutId] = item
                else
                  if !attribute.do_not_log
                    console.log("ERROR, cant find #{attribute.name} App.#{attribute.relation}.find(#{data[attribute.name]}) for '#{data.constructor.className}' #{data.displayName()}")
    data

  ###

    result = App.Model.search(
      sortBy: 'name'
      order:  'DESC' # default is ASC

      # just show this values in result, all filters need to match to get shown
      filter:
        some_attribute1: ['only_this_value1', 'only_that_value1']
        some_attribute2: ['only_this_value2', 'only_that_value2']

      # just show this values in result, all filters need to match to get shown
      filterExtended:
        [
          some_attribute1: 'regex_to_match1'
          some_attribute2: 'regex_to_match2'
        ]
    )

    returns:

      [ array of objects ]

    examples:

      list = App.Model.search({sortBy:'updated_at', order:'DESC'})

  ###

  @search: (params) ->
    all = @all()
    all_complied = []
    if !params
      for item in all
        item_new = @findNative(item.id)
        all_complied.push @_fillUp(item_new)
      return all_complied
    for item in all
      item_new = @findNative(item.id)
      all_complied.push @_fillUp(item_new)

    # filter search
    if params.filter
      all_complied = @_filter(all_complied, params.filter)

    # use extend filter search
    if params.filterExtended
      all_complied = @_filterExtended(all_complied, params.filterExtended)

    # sort by
    if params.sortBy != null
      all_complied = @_sortBy(all_complied, params.sortBy)

    # order
    if params.order
      all_complied = @_order(all_complied, params.order)

    all_complied

  @_sortBy: (collection, attribute) ->
    _.sortBy(collection, (item) ->

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

      # return value if string
      if item[ attribute ].toLowerCase
        return item[ attribute ].toLowerCase()

      item[ attribute ]
    )

  @_order: (collection, attribute) ->
    if attribute is 'DESC'
      return collection.reverse()
    collection

  @_filter: (collection, filter) ->
    for key, value of filter
      collection = _.filter(collection, (item) ->
        if item[key] is value
          return item
      )
    collection

  @_filterExtended: (collection, filters) ->
    collection = _.filter(collection, (item) ->

      # check all filters
      for filter in filters

        # all conditions need match
        matchInner = undefined
        for key, value of filter

          if matchInner isnt false
            reg = new RegExp( value, 'i' )
            if item[ key ] isnt undefined && item[ key ] isnt null && item[ key ].match(reg)
              matchInner = true
            else
              matchInner = false

        # if all matched, add item to new collection
        if matchInner is true
          return item

      return
    )
    collection

  activityMessage: (item) ->
    return "Need own activityMessage() in model to generate text (#{@objectDisplayName()}/#{item.type})."

  @lastUpdatedAt: ->
    updated_at
    for item in @all()
      if item.updated_at
        if !updated_at
          updated_at = item.updated_at
        else if item.updated_at > updated_at
          updated_at = item.updated_at
    updated_at

  @updatedAt: (id) ->
    return if !@irecords[id]
    @irecords[id].updated_at

  @findNative: (id) ->
    @irecords[id] or notFound?(id)

  @tagGet: (id, key, callback) ->
    App.Ajax.request(
      id:    key
      type:  'GET'
      url:   "#{@apiPath}/tags"
      data:
        object: @.className
        o_id:   id
      processData: true
      success: (data, status, xhr) ->
        callback(data)
    )

  @tagAdd: (id, item) ->
    App.Ajax.request(
      type:  'GET'
      url:   "#{@apiPath}/tags/add"
      data:
        object: @.className
        o_id:   id
        item:   item
      processData: true
    )

  @tagRemove: (id, item) ->
    App.Ajax.request(
      type:  'GET'
      url:   "#{@apiPath}/tags/remove"
      data:
        object: @.className
        o_id:   id
        item:   item
      processData: true
    )

  @clearInMemory: ->
    App.Delay.clearLevel("model-#{@className}")

    # reset callbacks to session based functions
    @resetCallbacks()

    # reset attributes to prevent cached forms on relogin
    @resetAttributes()

    # reset cached values of model
    @deleteAll()

  @updateAttributes: (attributes) ->
    if _.isEmpty(@org_configure_attributes)

      # use jquery instead of ._clone() because we need a deep copy of the obj
      @org_configure_attributes = $.extend(true, [], @configure_attributes)
    for attribute in attributes
      @attributes.push attribute.name

      found = false
      for attribute_model, index in @configure_attributes
        continue if attribute_model.name != attribute.name

        @configure_attributes[index] = _.extend(attribute_model, attribute)

        found = true
        break

      if !found
        @configure_attributes.push attribute

  @resetAttributes: ->
    return if _.isEmpty(@org_configure_attributes)

    # use jquery instead of ._clone() because we need a deep copy of the obj
    @configure_attributes = $.extend(true, [], @org_configure_attributes)

  @resetCallbacks: ->
    if @SUBSCRIPTION_ITEM
      @SUBSCRIPTION_ITEM = {}
    if @SUBSCRIPTION_COLLECTION
      @SUBSCRIPTION_COLLECTION = {}
