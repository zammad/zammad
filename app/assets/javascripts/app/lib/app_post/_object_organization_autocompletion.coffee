class App.ObjectOrganizationAutocompletion extends App.Controller
  className: 'dropdown js-recipientDropdown'
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganizationMembers'
    'click .js-organization':                 'showOrganizationMembers'
    'click .js-back':                         'hideOrganizationMembers'
    'click .js-object':                       'onObjectClick'
    'click .js-objectNew':                    'newObject'
    'focus .js-objectSelect':                 'onFocus'
    'input .js-objectSelect':                 'open'
    'click .js-objectSelect':                 'stopPropagation'
    'blur .js-objectSelect':                  'onBlur'
    'click .form-control':                    'focusInput'
    'click':                                  'stopPropagation'
    'change .js-objectId':                    'executeCallback'
    'click .js-remove':                       'removeThisToken'
    'click .js-showMoreMembers':              'showMoreMembers'

  elements:
    '.recipientList':   'recipientList'
    '.js-objectSelect': 'objectSelect'
    '.js-objectId':     'objectId'
    '.form-control':    'formControl'

  templateObjectItem: 'generic/object_search/item_object'
  templateObjectNew: 'generic/object_search/new_object'
  templateOrganizationItem: 'generic/object_search/item_organization'
  templateOrganizationItemMembers: 'generic/object_search/item_organization_members'

  objectSingle: 'User'
  objectIcon: 'user'
  inactiveObjectIcon: 'inactive-user'
  objectSingels: 'People'
  objectCreate: __('Create new object')
  referenceAttribute: 'member_ids'

  constructor: (params) ->
    super

    @lazySearch = _.debounce(@searchObject, 200)

    @key = Math.floor( Math.random() * 999999 ).toString()

    if !@attribute.sourceType
      @attribute.sourceType = 'GET'
    if !@attribute.source
      @attribute.source = "#{@apiPath}/search/user-organization"
    @build()

    # set current value
    if @attribute.value and @callback
      @callback(@attribute.value)

  element: =>
    @el

  release: ->
    $(window).off 'click.ObjectOrganizationAutocompletion'

  open: =>
    # prevent rebinding of keydown event
    return if @el.hasClass 'open'

    @el.addClass('open')
    $(window).on 'click.ObjectOrganizationAutocompletion', @close
    $(window).on 'keydown.ObjectOrganizationAutocompletion', @navigateByKeyboard

  close: =>
    $(window).off 'keydown.ObjectOrganizationAutocompletion'
    @el.removeClass('open')

    $(window).off 'click.ObjectOrganizationAutocompletion'

  onFocus: =>
    @formControl.addClass 'focus'
    @open()

  focusInput: =>
    @objectSelect.trigger('focus') if not @formControl.hasClass('focus')

  onBlur: =>
    selectObject = @objectSelect.val()
    if _.isEmpty(selectObject) && !@attribute.multiple
      @objectId.val('')
    else if @attribute.guess is true
      currentObjectId = @objectId.val()
      if _.isEmpty(currentObjectId) || currentObjectId.match(/^guess:/)
        if !_.isEmpty(selectObject)
          @objectId.val("guess:#{selectObject}")
    @formControl.removeClass 'focus'

  resetObjectSelection: =>
    @objectId.val('').trigger('change')

  onObjectClick: (e) =>
    objectId = $(e.currentTarget).data('object-id')
    objectName = $(e.currentTarget).find('.recipientList-name').text().trim()
    @selectObject(objectId, objectName)
    @close()

  selectObject: (objectId, objectName) =>
    if @attribute.multiple
      @addValueToObjectInput(objectName, objectId)
    else
      @objectSelect.val('')
      @objectId.val(objectId).trigger('change')

  executeCallback: =>
    if @attribute.multiple
      # create token
      @createToken(@currentObject) if @currentObject
      @currentObject = null

    else
      objectId = @objectId.val()
      if objectId && App[@objectSingle].exists(objectId)
        object = App[@objectSingle].find(objectId)
        name = object.displayName()

        if object.email
          name = App.Utils.buildEmailAddress(object.displayName(), object.email)

        @objectSelect.val(name)

    if @callback
      @callback(objectId)

  createToken: ({name, value}) =>
    @objectSelect.before App.view('generic/token')(
      name: name
      value: value
    )

  removeThisToken: (e) =>
    @removeToken $(e.currentTarget).parents('.token')

  removeToken: (which) =>
    switch which
      when 'last'
        token = @$('.token').last()
        return if not token.length
      else
        token = which

    id = token.data('value')
    @objectId.find("[value=#{id}]").remove()
    @objectId.trigger('change')
    token.remove()

  navigateByKeyboard: (e) =>
    switch e.keyCode
      # clean input on esc
      when 27
        # if org member selection is shown, go back to member list
        if !@recipientList.hasClass('is-shown')
          @hideOrganizationMembers()
          return

        # empty object selection and close
        @objectSelect.val('').trigger('change')
      # remove last token on backspace
      when 8
        if @objectSelect.val() is '' && @objectSelect.is(e.target)
          @removeToken('last')
      # close on tab
      when 9 then @close()
      # ignore left and right
      when 37, 39 then return
      # up / select upper item
      when 38
        e.preventDefault()
        if @recipientList.hasClass('is-shown')
          if @recipientList.find('li.is-active').length is 0
            @recipientList.find('li').last().addClass('is-active')
          else
            if @recipientList.find('li.is-active').prev().length isnt 0
              @recipientList.find('li.is-active').removeClass('is-active').prev().addClass('is-active')
          return
        recipientListOrgMemeber = @$('.recipientList-organizationMembers').not('.hide')
        if recipientListOrgMemeber.not('.hide').find('li.is-active').length is 0
          recipientListOrgMemeber.not('.hide').find('li').last().addClass('is-active')
        else
          if recipientListOrgMemeber.not('.hide').find('li.is-active').prev().length isnt 0
            recipientListOrgMemeber.not('.hide').find('li.is-active').removeClass('is-active').prev().addClass('is-active')
        return
      # down / select lower item
      when 40
        e.preventDefault()
        if @recipientList.hasClass('is-shown')
          if @recipientList.find('li.is-active').length is 0
            @recipientList.find('li').first().addClass('is-active')
          else
            if @recipientList.find('li.is-active').next().length isnt 0
              @recipientList.find('li.is-active').removeClass('is-active').next().addClass('is-active')
          return
        recipientListOrgMemeber = @$('.recipientList-organizationMembers').not('.hide')
        if recipientListOrgMemeber.not('.hide').find('li.is-active').length is 0
          recipientListOrgMemeber.find('li').first().addClass('is-active')
        else
          if recipientListOrgMemeber.not('.hide').find('li.is-active').next().length isnt 0
            recipientListOrgMemeber.not('.hide').find('li.is-active').removeClass('is-active').next().addClass('is-active')
        return
      # enter / take item
      when 13
        e.preventDefault()
        e.stopPropagation()

        # nav by org member selection
        if !@recipientList.hasClass('is-shown')
          recipientListOrganizationMembers = @$('.recipientList-organizationMembers').not('.hide')
          if recipientListOrganizationMembers.find('.js-back.is-active').get(0)
            @hideOrganizationMembers()
            return
          objectId = recipientListOrganizationMembers.find('li.is-active').data('object-id')
          return if !objectId
          objectName = recipientListOrganizationMembers.find('li.is-active .recipientList-name').text().trim()
          @selectObject(objectId, objectName)
          @close() if !@attribute.multiple
          return

        # nav by object list selection
        objectId = @recipientList.find('li.is-active').data('object-id')
        if objectId
          if objectId is 'new'
            @newObject()
          else
            objectName = @recipientList.find('li.is-active .recipientList-name').text().trim()
            @selectObject(objectId, objectName)
            @close() if !@attribute.multiple
          return

        organizationId = @recipientList.find('li.is-active').data('organization-id')
        return if !organizationId
        @showOrganizationMembers(undefined, @recipientList.find('li.is-active'))


  addValueToObjectInput: (objectName, objectId) ->
    @objectSelect.val('')
    @currentObject = {name: objectName, value: objectId}
    if @objectId.val()
      return if @objectId.val().includes("#{objectId}") # cast objectId to string before check
    @objectId.append("<option value=#{App.Utils.htmlEscape(@currentObject.value)} selected>#{App.Utils.htmlEscape(@currentObject.name)}</option>")
    @objectId.trigger('change')

  buildOrganizationItem: (organization) ->
    objectCount = 0
    if organization[@referenceAttribute]
      objectCount = organization[@referenceAttribute].length
    App.view(@templateOrganizationItem)(
      organization: organization
      objectSingels: @objectSingels
      objectCount: objectCount
    )

  showMoreMembers: (e) ->
    @preventDefaultAndStopPropagation(e)

    memberElement  = $(e.target).closest('.js-showMoreMembers')
    oldMemberLimit = memberElement.attr('organization-member-limit')
    newMemberLimit = (parseInt(oldMemberLimit / 25) + 1) * 25
    memberElement.attr('organization-member-limit', newMemberLimit)

    @renderMembers(memberElement, oldMemberLimit, newMemberLimit)

  renderMembers: (element, fromMemberLimit, toMemberLimit) ->
    id           = element.closest('.recipientList-organizationMembers').attr('organization-id')
    organization = App.Organization.find(id)

    # only first 10 members else we would need more ajax requests
    organization.members(fromMemberLimit, toMemberLimit, (users) =>
      for user in users
        element.before(@buildObjectItem(user))

      if element.closest('ul').hasClass('is-shown')
        @showOrganizationMembers(undefined, element.closest('ul'))
    )

    if organization.member_ids.length <= toMemberLimit
      element.addClass('hidden')
    else
      element.removeClass('hidden')

  buildOrganizationMembers: (organization) =>
    organizationMembers = $( App.view(@templateOrganizationItemMembers)(
      organization: organization
    ) )

    @renderMembers(organizationMembers.find('.js-showMoreMembers'), 0, 10)

    organizationMembers

  buildObjectItem: (object) =>
    icon = @objectIcon

    if object.active is false and @inactiveObjectIcon
      icon = @inactiveObjectIcon

    App.view(@templateObjectItem)(
      object: object
      icon: icon
    )

  buildObjectNew: =>
    App.view(@templateObjectNew)(
      objectCreate: @objectCreate
    )

  build: =>
    tokens = ''
    name = ''
    value = ''

    if @attribute.multiple && @attribute.value

      # fallback for if the value is not an array
      if typeof @attribute.value isnt 'object'
        @attribute.value = [@attribute.value]

      # create tokens and attribute values
      values = []
      for objectId in @attribute.value
        if App[@objectSingle].exists objectId
          objectName = App[@objectSingle].find(objectId).displayName()
          objectValue = objectId
          values.push({name: objectName, value: objectValue})
          tokens += App.view('generic/token')(
            name: objectName
            value: objectValue
          )
        else
          @log 'objectId doesn\'t exist', objectId

      @attribute.value = values

    else
      value = @attribute.value
      if value
        if App[@objectSingle].exists(value)
          object = App[@objectSingle].find(value)
          name = object.displayName()
          if object.email
            # Do not use App.Utils.buildEmailAddress here because we don't build an email address and the
            #   quoting would confuse sorting in the GUI.
            name += " <#{object.email}>"
        else if @params && @params["#{@attribute.name}_completion"]
          name = @params["#{@attribute.name}_completion"]
        else
          @log 'objectId doesn\'t exist', value

    @html App.view('generic/object_search/input')(
      attribute: @attribute
      value: value
      tokens: tokens
      name: name
    )

    if !@attribute.disableCreateObject
      @recipientList.append(@buildObjectNew())

    # start search
    @searchTerm = ''

    @objectSelect.on 'keyup', @onKeyUp

  onKeyUp: (e) =>
    query = $(e.target).val().trim()
    return if @searchTerm is query
    @searchTerm = query

    @hideOrganizationMembers()

    # hide dropdown
    if _.isEmpty(query)
      @emptyResultList()

      if !@attribute.disableCreateObject
        @recipientList.append(@buildObjectNew())

      # reset object selection
      @resetObjectSelection() if !@attribute.multiple
      return

    # show dropdown
    if query && ( !@attribute.minLengt || @attribute.minLengt <= query.length )
      @lazySearch(query)

  searchObject: (query) =>
    data =
      query: query
    if @attribute.queryCallback
      data = @attribute.queryCallback(query)

    @ajax(
      id:          "searchObject#{@key}"
      type:        @attribute.sourceType
      url:         @attribute.source
      data:        data
      processData: true
      success:     (data, status, xhr) =>
        @emptyResultList()

        # load assets
        App.Collection.loadAssets(data.assets)

        # user search endpoint
        if data.user_ids
          for id in data.user_ids
            object = App[@objectSingle].fullLocal(id)
            @recipientList.append(@buildObjectItem(object))

        # global search endpoint
        else
          for item in data.result

            # organization
            if item.type is 'Organization'
              organization = App.Organization.fullLocal(item.id)
              @recipientList.append(@buildOrganizationItem(organization))

              # objectss of organization
              if organization[@referenceAttribute]
                @$('.dropdown-menu').append(@buildOrganizationMembers(organization))

            # objectss
            else if item.type is @objectSingle
              object = App[@objectSingle].fullLocal(item.id)
              @recipientList.append(@buildObjectItem(object))

          if !@attribute.disableCreateObject
            @recipientList.append(@buildObjectNew())

        @recipientList.find('.js-object').first().addClass('is-active')
    )

  emptyResultList: =>
    @recipientList.empty()
    @$('.recipientList-organizationMembers').remove()

  showOrganizationMembers: (e,listEntry) =>
    if e
      e.stopPropagation()
      listEntry = $(e.currentTarget)

    organizationId = listEntry.data('organization-id') || listEntry.attr('organization-id')
    @organizationList = @$("[organization-id=#{ organizationId }]")

    return if !@organizationList.get(0)

    @recipientList.removeClass('is-shown')
    @$('.recipientList-organizationMembers').addClass('is-shown')

    # move organization-list to the right and slide it in
    $.Velocity.hook(@organizationList, 'translateX', '100%')
    @organizationList.removeClass('hide')

    @organizationList.velocity
      properties:
        translateX: 0
      options:
        duration: 240

    # fade out list
    @recipientList.velocity
      properties:
        translateX: '-100%'
      options:
        duration: 240
        complete: => @recipientList.height(@organizationList.height())

  hideOrganizationMembers: (e) =>
    e && e.stopPropagation()

    @recipientList.addClass('is-shown')
    @$('.recipientList-organizationMembers').removeClass('is-shown')

    return if !@organizationList

    # fade list back in
    @recipientList.velocity
      properties:
        translateX: 0
      options:
        duration: 240

    # reset list height
    @recipientList.height('')

    # slide out organization-list and hide it
    @organizationList.velocity
      properties:
        translateX: '100%'
      options:
        duration: 240
        complete: => @organizationList.addClass('hide')

  newObject: (e) ->
    if e
      e.preventDefault()
