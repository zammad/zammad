class App.UserOrganizationAutocompletion extends App.Controller
  className: 'dropdown js-recipientDropdown zIndex-2'
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganizationMembers'
    'click .js-organization':                 'showOrganizationMembers'
    'click .js-back':                         'hideOrganizationMembers'
    'click .js-user':                         'selectUser'
    'click .js-userNew':                      'newUser'
    'focus input':                            'open'
    'click':                                  'stopPropagation'

  constructor: (params) ->
    super

    @key = Math.floor( Math.random() * 999999 ).toString()

    if !@attribute.source
      @attribute.source = @apiPath + '/search/user-organization'
    @build()

    # set current value
    if @attribute.value
      @setUser(@attribute.value)

  element: =>
    @el

  release: ->
    $(window).off 'click.UserOrganizationAutocompletion'

  open: =>
    @clearDelay('close')
    @el.addClass('open')

    $(window).on 'click.UserOrganizationAutocompletion', @close

  close: =>
    execute = =>
      @el.removeClass('open')
    @delay(execute, 200, 'close')

    $(window).off 'click.UserOrganizationAutocompletion'

  selectUser: (e) =>
    userId = $(e.target).parents('.recipientList-entry').data('user-id')
    if !userId
      userId = $(e.target).data('user-id')
    @setUser(userId)
    @close()

  setUser: (userId) =>
    @el.find('[name="' + @attribute.name + '"]').val( userId ).trigger('change')

  executeCallback: =>
    userId = @el.find('[name="' + @attribute.name + '"]').val()
    return if !userId
    return if !App.User.exists(userId)
    user = App.User.find(userId)
    name = user.displayName()
    if user.email
      name += " <#{user.email}>"
    @el.find('[name="' + @attribute.name + '_completion"]').val( name ).trigger('change')

    if @callback
      @callback(userId)

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
      organizationMemebers.append( @buildUserItem(user) )

  buildUserItem: (user) ->
    App.view('generic/user_search/item_user')(
      user: user
    )

  buildUserNew: ->
    App.view('generic/user_search/new_user')()

  build: =>
    @el.html App.view('generic/user_search/input')(
      attribute: @attribute
    )
    if !@attribute.disableCreateUser
      @el.find('.recipientList').append( @buildUserNew() )

    @el.find('[name="' + @attribute.name + '"]').on(
      'change',
      (e) =>
        @executeCallback()
    )

    # navigate in result list
    @el.find('[name="' + @attribute.name + '_completion"]').on(
      'keydown',
      (e) =>
        item = $(e.target).val().trim()

        #@log('CC', e.keyCode, item)

        # clean input field on ESC
        if e.keyCode is 27

          # if org member selection is shown, go back to member list
          if @$('.recipientList-backClickArea').is(':visible')
            @$('.recipientList-backClickArea').click()
            return

          # empty user selection and close
          $(e.target).val('')
          item = ''
          @close()

        # if tab / close recipientList
        if e.keyCode is 9
          @close()

        # ignore arrow keys
        if e.keyCode is 37
          return

        if e.keyCode is 39
          return

        # up / select upper item
        if e.keyCode is 38
          e.preventDefault()
          recipientList = @$('.recipientList')
          if recipientList.find('li.is-active').length is 0
            recipientList.find('li').last().addClass('is-active')
          else
            if recipientList.find('li.is-active').prev().length isnt 0
              recipientList.find('li.is-active').removeClass('is-active').prev().addClass('is-active')
          return

        # down / select lower item
        if e.keyCode is 40
          e.preventDefault()
          recipientList = @$('.recipientList')
          if recipientList.find('li.is-active').length is 0
            recipientList.find('li').first().addClass('is-active')
          else
            if recipientList.find('li.is-active').next().length isnt 0
              recipientList.find('li.is-active').removeClass('is-active').next().addClass('is-active')
          return

        # enter / take item
        if e.keyCode is 13
          e.preventDefault()
          userId = @$('.recipientList').find('li.is-active').data('user-id')
          if !userId
            organizationId = @$('.recipientList').find('li.is-active').data('organization-id')
            if !organizationId
              return
            @showOrganizationMembers(undefined, @$('.recipientList').find('li.is-active'))
            return
          if userId is 'new'
            @newUser()
          else
            @setUser(userId)
            @close()
          return
    )

    # start search
    @searchTerm = ''
    @el.find('[name="' + @attribute.name + '_completion"]').on(
      'keyup',
      (e) =>
        term = $(e.target).val().trim()
        return if @searchTerm is term
        @searchTerm = term

        # hide dropdown
        if !term && !@attribute.disableCreateUser
          @emptyResultList()
          @$('.recipientList').append(@buildUserNew())

        # show dropdown
        if term && ( !@attribute.minLengt || @attribute.minLengt <= term.length )
          execute = => @searchUser(term)
          @delay(execute, 400, 'userSearch')
    )

  searchUser: (term) =>
    @ajax(
      id:    'searchUser' + @key
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
            @$('.recipientList').append(@buildOrganizationItem(organization))

            # users of organization
            if organization.member_ids
              @$('.dropdown-menu').append(@buildOrganizationMembers(organization))

          # users
          if item.type is 'User'
            user = App.User.fullLocal(item.id)
            @$('.recipientList').append(@buildUserItem(user))

        if !@attribute.disableCreateUser
          @$('.recipientList').append(@buildUserNew())
    )

  emptyResultList: =>
    @$('.recipientList').empty()
    @$('.recipientList-organizationMembers').remove()

  showOrganizationMembers: (e,listEntry) =>
    if e
      e.stopPropagation()
      listEntry = $(e.currentTarget)

    organizationId = listEntry.data('organization-id')

    @recipientList = @$('.recipientList')
    @organizationList = @$("##{ organizationId }")

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
