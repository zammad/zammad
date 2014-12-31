class App.UserOrganizationAutocompletion extends App.Controller
  className: 'dropdown js-recipientDropdown zIndex-2'
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganisationMembers'
    'click .js-organisation':                 'showOrganisationMembers'
    'click .js-back':                         'hideOrganisationMembers'
    'click .js-user':                         'selectUser'
    'click .js-user-new':                     'newUser'
    'focus input':                            'open'

  constructor: (params) ->
    super

    @key = Math.floor( Math.random() * 999999 ).toString()

    if !@attribute.source
      @attribute.source = @apiPath + '/search_user_org'
    @build()

  element: =>
    @el

  open: =>
    @clearDelay('close')
    @el.addClass('open')
    @catcher = new App.clickCatcher
      holder:       @el.offsetParent()
      callback:     @close
      zIndexScale:  1

  close: =>
    execute = =>
      @el.removeClass('open')
    @delay( execute, 400, 'close' )

    if @catcher
      @catcher.remove()

  selectUser: (e) ->
    userId = $(e.target).parents('.recipientList-entry').data('user-id')
    if !userId
      userId = $(e.target).data('user-id')
    @setUser(userId)
    @close()

  setUser: (userId) =>
    @el.find('[name="' + @attribute.name + '"]').val( userId ).trigger('change')

  executeCallback: ->
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

  buildOrganizationItem: (organization) =>
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

  buildUserItem: (user) =>
    App.view('generic/user_search/item_user')(
      user: user
    )

  buildUserNew: =>
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
            organisationId = @$('.recipientList').find('li.is-active').data('organisation-id')
            if organisationId
              @showOrganisationMembers(undefined, @$('.recipientList').find('li.is-active'))
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
        item = $(e.target).val().trim()
        return if @searchTerm is item
        @searchTerm = item

        # hide dropdown
        if !item && !@attribute.disableCreateUser
          @emptyResultList()
          @$('.recipientList').append( @buildUserNew() )

        # show dropdown
        if item && ( !@attribute.minLengt || @attribute.minLengt <= item.length )
          execute = => @searchUser(item)
          @delay( execute, 400, 'userSearch' )
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
        App.Collection.loadAssets( data.assets )

        # build markup
        for item in data.result

          # organization
          if item.type is 'Organization'
            organization = App.Organization.fullLocal( item.id )
            @el.find('.recipientList').append( @buildOrganizationItem(organization) )

            # users of organization
            if organization.member_ids
              @el.find('.dropdown-menu').append( @buildOrganizationMembers(organization) )

          # users
          if item.type is 'User'
            user = App.User.fullLocal( item.id )
            @el.find('.recipientList').append( @buildUserItem(user) )

        if !@attribute.disableCreateUser
          @el.find('.recipientList').append( @buildUserNew() )
    )

  emptyResultList: =>
    @$('.recipientList').empty()
    @$('.recipientList-organisationMembers').remove()

  showOrganisationMembers: (e,listEntry) =>
    if e
      e.stopPropagation()
      listEntry = $(e.currentTarget)

    organisationId = listEntry.data('organisation-id')

    @recipientList = @$('.recipientList')
    @organisationList = @$("##{ organisationId }")

    # move organisation-list to the right and slide it in

    $.Velocity.hook(@organisationList, 'translateX', '100%')
    @organisationList.removeClass('hide')

    @organisationList.velocity
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
        complete: => @recipientList.height(@organisationList.height())

  hideOrganisationMembers: (e) =>
    e && e.stopPropagation()

    return if !@organisationList

    # fade list back in
    @recipientList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # reset list height

    @recipientList.height('')

    # slide out organisation-list and hide it
    @organisationList.velocity
      properties:
        translateX: '100%'
      options:
        speed: 300
        complete: => @organisationList.addClass('hide')

  newUser: (e) =>
    if e
      e.preventDefault()
    new UserNew(
      parent: @
    )

class UserNew extends App.ControllerModal
  constructor: ->
    super
    @head   = 'New User'
    @cancel = true
    @button = true

    controller = new App.ControllerForm(
      model:      App.User
      screen:     'edit'
      autofocus:  true
    )

    @content = controller.form

    @show()

  onSubmit: (e) ->

    e.preventDefault()
    params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !params.login && params.email
      params.login = params.email

    # find role_id
    if !params.role_ids || _.isEmpty( params.role_ids )
      role = App.Role.findByAttribute( 'name', 'Customer' )
      params.role_ids = role.id
    @log 'notice', 'updateAttributes', params

    user = new App.User
    user.load(params)

    errors = user.validate()
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return

    # save user
    ui = @
    user.save(
      done: ->

        # force to reload object
        callbackReload = (user) ->
          ui.parent.el.find('[name=customer_id]').val( user.id ).trigger('change')
          ui.parent.close()

          # start customer info controller
          ui.hide()
        App.User.full( @id, callbackReload , true )

      fail: ->
        ui.hide()
    )