class App.UserOrganizationAutocompletion extends App.Controller
  className: 'dropdown js-recipientDropdown'
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganizationMembers'
    'click .js-organization':                 'showOrganizationMembers'
    'click .js-back':                         'hideOrganizationMembers'
    'click .js-user':                         'onUserClick'
    'click .js-userNew':                      'newUser'
    'focus .js-userSelect':                   'onFocus'
    'click .js-userSelect':                   'stopPropagation'
    'blur .js-userSelect':                    'onBlur'
    'click .form-control':                    'focusInput'
    'click':                                  'stopPropagation'
    'change .js-userId':                      'executeCallback'
    'click .js-remove':                       'removeThisToken'

  elements:
    '.recipientList': 'recipientList'
    '.js-userSelect': 'userSelect'
    '.js-userId': 'userId'
    '.form-control': 'formControl'

  constructor: (params) ->
    super

    @lazySearch = _.debounce(@searchUser, 200)

    @key = Math.floor( Math.random() * 999999 ).toString()

    if !@attribute.source
      @attribute.source = "#{@apiPath}/search/user-organization"
    @build()

    # set current value
    if @attribute.value and @callback
      @callback(@attribute.value)

  element: =>
    @el

  release: ->
    $(window).off 'click.UserOrganizationAutocompletion'

  open: =>
    # prevent rebinding of keydown event
    return if @el.hasClass 'open'

    @el.addClass('open')
    $(window).on 'click.UserOrganizationAutocompletion', @close
    $(window).on 'keydown.UserOrganizationAutocompletion', @navigateByKeyboard

  close: =>
    $(window).off 'keydown.UserOrganizationAutocompletion'
    @el.removeClass('open')

    $(window).off 'click.UserOrganizationAutocompletion'

  onFocus: =>
    @formControl.addClass 'focus'
    @open()

  focusInput: =>
    @userSelect.focus() if not @formControl.hasClass 'focus'

  onBlur: =>
    @formControl.removeClass 'focus'

  onUserClick: (e) =>
    userId = $(e.currentTarget).data('user-id')
    @selectUser(userId)
    @close()

  selectUser: (userId) =>
    if @attribute.multiple and @userId.val()
      # add userId to end of comma separated list
      userId = _.chain( @userId.val().split(',') ).push(userId).join(',').value()

    @userSelect.val('')
    @userId.val(userId).trigger('change')

  executeCallback: =>
    # with @attribute.multiple this can be several user ids.
    # Only work with the last one since its the newest one
    userId = @userId.val().split(',').pop()

    return if !userId
    return if !App.User.exists(userId)
    user = App.User.find(userId)
    name = user.displayName()

    if @attribute.multiple
      # create token
      @createToken name, userId
    else
      if user.email
        name += " <#{user.email}>"

      @userSelect.val(name)

    if @callback
      @callback(userId)

  createToken: (name, userId) =>
    @userSelect.before App.view('generic/token')(
      name: name
      value: userId
    )

  removeThisToken: (e) =>
    @removeToken $(e.currentTarget).parents('.token')

  removeToken: (which) =>
    switch which
      when 'last'
        token = @$('.token').last()
        return if not token.size()
      else
        token = which

    # remove userId from input
    index = @$('.token').index(token)
    ids = @userId.val().split(',')
    ids.splice(index, 1)
    @userId.val ids.join(',')

    token.remove()

  navigateByKeyboard: (e) =>
    switch e.keyCode
      # clean input on esc
      when 27
        # if org member selection is shown, go back to member list
        if !@recipientList.hasClass('is-shown')
          @hideOrganizationMembers()
          return

        # empty user selection and close
        @userSelect.val('').trigger('change')
      # remove last token on backspace
      when 8
        if @userSelect.val() is ''
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
          userId = recipientListOrganizationMembers.find('li.is-active').data('user-id')
          return if !userId
          @selectUser(userId)
          @close() if !@attribute.multiple
          return

        # nav by user list selection
        userId = @recipientList.find('li.is-active').data('user-id')
        if userId
          if userId is 'new'
            @newUser()
          else
            @selectUser(userId)
            @close() if !@attribute.multiple
          return

        organizationId = @recipientList.find('li.is-active').data('organization-id')
        return if !organizationId
        @showOrganizationMembers(undefined, @recipientList.find('li.is-active'))


  buildOrganizationItem: (organization) ->
    App.view('generic/user_search/item_organization')(
      organization: organization
    )

  buildOrganizationMembers: (organization) =>
    organizationMemebers = $( App.view('generic/user_search/item_organization_members')(
      organization: organization
    ) )
    for userId in organization.member_ids
      user = App.User.fullLocal(userId)
      organizationMemebers.append(@buildUserItem(user))

  buildUserItem: (user) ->
    App.view('generic/user_search/item_user')(
      user: user
    )

  buildUserNew: ->
    App.view('generic/user_search/new_user')()

  build: =>
    tokens = ''
    name = ''
    value = ''

    if @attribute.multiple && @attribute.value

      # fallback for if the value is not an array
      if typeof @attribute.value isnt 'object'
        @attribute.value = [@attribute.value]
      value = @attribute.value.join ','

      # create tokens
      for userId in @attribute.value
        if App.User.exists userId
          tokens += App.view('generic/token')(
            name: App.User.find(userId).displayName()
            value: userId
          )
        else
          @log 'userId doesn\'t exist', userId
    else
      value = @attribute.value
      if value
        if App.User.exists value
          user = App.User.find(value)
          name = user.displayName()
          if user.email
            name += " <#{user.email}>"
        else if @params && @params["#{@attribute.name}_completion"]
          name = @params["#{@attribute.name}_completion"]
        else
          @log 'userId doesn\'t exist', value

    @html App.view('generic/user_search/input')(
      attribute: @attribute
      value: value
      tokens: tokens
      name: name
    )

    if !@attribute.disableCreateUser
      @recipientList.append(@buildUserNew())

    # start search
    @searchTerm = ''

    @userSelect.on 'keyup', @onKeyUp

  onKeyUp: (e) =>
    term = $(e.target).val().trim()
    return if @searchTerm is term
    @searchTerm = term

    @hideOrganizationMembers()

    # hide dropdown
    if !term
      @emptyResultList()

      if !@attribute.disableCreateUser
        @recipientList.append(@buildUserNew())

    # show dropdown
    if term && ( !@attribute.minLengt || @attribute.minLengt <= term.length )
      @lazySearch(term)

  searchUser: (term) =>
    @ajax(
      id:    "searchUser#{@key}"
      type:  'GET'
      url:   @attribute.source
      data:
        query: term
      processData: true
      success: (data, status, xhr) =>
        @emptyResultList()

        # load assets
        App.Collection.loadAssets(data.assets)

        # build markup
        for item in data.result

          # organization
          if item.type is 'Organization'
            organization = App.Organization.fullLocal(item.id)
            @recipientList.append(@buildOrganizationItem(organization))

            # users of organization
            if organization.member_ids
              @$('.dropdown-menu').append(@buildOrganizationMembers(organization))

          # users
          if item.type is 'User'
            user = App.User.fullLocal(item.id)
            @recipientList.append(@buildUserItem(user))

        if !@attribute.disableCreateUser
          @recipientList.append(@buildUserNew())

        @recipientList.find('.js-user').first().addClass('is-active')
    )

  emptyResultList: =>
    @recipientList.empty()
    @$('.recipientList-organizationMembers').remove()

  showOrganizationMembers: (e,listEntry) =>
    if e
      e.stopPropagation()
      listEntry = $(e.currentTarget)

    organizationId = listEntry.data('organization-id')

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
        speed: 300

    # fade out list
    @recipientList.velocity
      properties:
        translateX: '-100%'
      options:
        speed: 300
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
        speed: 300

    # reset list height
    @recipientList.height('')

    # slide out organization-list and hide it
    @organizationList.velocity
      properties:
        translateX: '100%'
      options:
        speed: 300
        complete: => @organizationList.addClass('hide')

  newUser: (e) =>
    if e
      e.preventDefault()
    new UserNew(
      parent:    @
      container: @el.closest('.content')
    )

class UserNew extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'User'
  headPrefix: 'New'

  content: ->
    @controller = new App.ControllerForm(
      model:     App.User
      screen:    'edit'
      autofocus: true
    )
    @controller.form

  onSubmit: (e) =>
    params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !params.login && params.email
      params.login = params.email

    # find role_id
    if !params.role_ids || _.isEmpty(params.role_ids)
      role = App.Role.findByAttribute('name', 'Customer')
      params.role_ids = role.id
    @log 'notice', 'updateAttributes', params

    user = new App.User
    user.load(params)

    errors = user.validate()
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return

    # save user
    ui = @
    user.save(
      done: ->

        # force to reload object
        callbackReload = (user) ->
          ui.parent.el.find('[name=customer_id]').val(user.id).trigger('change')
          ui.parent.close()

          # start customer info controller
          ui.close()
        App.User.full(@id, callbackReload , true)

      fail: (settings, details) ->
        ui.log 'errors', details
        ui.formEnable(e)
        ui.controller.showAlert(details.error_human || details.error || 'Unable to create object!')
    )
