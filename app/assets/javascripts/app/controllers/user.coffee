class User extends App.ControllerSubContent
  @requiredPermission: 'admin.user'
  header: __('Users')
  elements:
    '.js-search': 'searchInput'
  events:
    'click [data-type=new]': 'new'
    'click [data-type=import]': 'import'

  constructor: ->
    super

    @render()

  show: =>
    super
    return if !@table
    @table.show()

  hide: =>
    super
    return if !@table
    @table.hide()

  render: ->
    roles = App.Role.findAllByAttribute('active', true)
    roles = _.sortBy(roles, (role) -> role.name.toLowerCase())

    @html App.view('user')(
      head: __('Users')
      buttons: [
        { name: __('Import'), 'data-type': 'import', class: 'btn' }
        { name: __('New User'), 'data-type': 'new', class: 'btn--success' }
      ]
      roles: roles
    )

    @$('.tab').on(
      'click'
      (e) =>
        e.preventDefault()
        $(e.target).toggleClass('active')
        query = @searchInput.val().trim()
        @query = query
        @delay(@search, 220, 'search')
    )

    # start search
    @searchInput.on( 'keyup', (e) =>
      query = @searchInput.val().trim()
      return if query is @query
      @query = query
      @delay(@search, 220, 'search')
    )

    # App.User.subscribe will clear model data so we use controllerBind (#4040)
    @controllerBind('User:create User:update User:touch User:destroy', => @delay(@search, 220, 'search'))

    # show last 20 users
    @search()

  renderResult: (user_ids = []) ->
    @stopLoading()

    switchTo = (id,e) =>
      e.preventDefault()
      e.stopPropagation()
      @disconnectClient()
      $('#app').hide().attr('style', 'display: none!important')
      @delay(
        =>
          App.Auth._logout(false)
          @ajax(
            id:          'user_switch'
            type:        'GET'
            url:         "#{@apiPath}/sessions/switch/#{id}"
            success:     (data, status, xhr) =>
              location = "#{window.location.protocol}//#{window.location.host}#{data.location}"
              @windowReload(undefined, location)
          )
        800
      )

    edit = (id, e) =>
      e.preventDefault()
      item = App.User.find(id)

      rerender = =>
        App.Group.fetch()
        @renderResult(user_ids)

      hideOrganizationHelp = (params, attribute, attributes, classname, form, ui) ->
        return if App.Config.get('ticket_organization_reassignment')

        form.find('[name="organization_id"]').closest('.form-group').find('.help-message').addClass('hide')

      item.secondaryOrganizations(0, 1000, =>
        new App.ControllerGenericEdit(
          id: item.id
          pageData:
            title:     __('Users')
            home:      'users'
            object:    __('User')
            objects:   __('Users')
            navupdate: '#users'
          genericObject: 'User'
          callback: rerender
          container: @el.closest('.content')
          handlers: [hideOrganizationHelp]
          screen: 'edit'
          veryLarge: true
        )
      )

    callbackLoginAttribute = (value, object, attribute, attributes) ->
      attribute.prefixIcon = null
      attribute.title = null

      if object.maxLoginFailedReached()
        attribute.title = App.i18n.translateContent('This user is currently blocked because of too many failed login attempts.')
        attribute.prefixIcon = 'lock'

      value

    users = []
    for user_id in user_ids
      user = App.User.find(user_id)
      users.push user

    @$('.table-overview').html('')
    @table = new App.ControllerTable(
      tableId: 'users_admin_overview'
      el:      @$('.table-overview')
      model:   App.User
      objects: users
      class:   'user-list'
      customActions: [
        {
          name: 'switchTo'
          display: __('View from user\'s perspective')
          icon: 'switchView '
          class: 'create js-switchTo'
          callback: (id) =>
            @disconnectClient()
            $('#app').hide().attr('style', 'display: none!important')
            @delay(
              =>
                App.Auth._logout(false)
                @ajax(
                  id:          'user_switch'
                  type:        'GET'
                  url:         "#{@apiPath}/sessions/switch/#{id}"
                  success:     (data, status, xhr) =>
                    location = "#{window.location.protocol}//#{window.location.host}#{data.location}"
                    @windowReload(undefined, location)
                )
              800
            )
        },
        {
          name: 'manageTwoFactor'
          display: __('Manage Two-Factor Authentication')
          icon: 'two-factor'
          class: 'create js-manageTwoFactor'
          available: (user) ->
            !!user.preferences?.two_factor_authentication?.default
          callback: (id) ->
            user = App.User.find(id)
            return if !user

            new App.ControllerManageTwoFactor(
              user: user
            )
        },
        {
          name: 'delete'
          display: __('Delete')
          icon: 'trash'
          class: 'delete'
          callback: (id) =>
            @navigate "#system/data_privacy/#{id}"
        },
        {
          name: 'unlock'
          display: __('Unlock')
          icon: 'lock-open'
          class: 'unlock'
          available: (user) ->
            user.maxLoginFailedReached()
          callback: (id) =>
            @ajax(
              id: "user_unlock_#{id}"
              type:  'PUT'
              url:   "#{@apiPath}/users/unlock/#{id}"
              success: =>
                App.User.full(id,
                => @notify(
                  type: 'success'
                  msg:  App.i18n.translateContent('User successfully unlocked!')

                  @renderResult(user_ids)
                ),
                true)
            )
        }
      ]
      callbackAttributes: {
        login: [ callbackLoginAttribute ]
      }
      bindRow:
        events:
          'click': edit
    )

  search: =>
    role_ids = []
    @$('.tab.active').each( (i,d) ->
      role_ids.push $(d).data('id')
    )
    @startLoading(@$('.table-overview'))
    App.Ajax.request(
      id: 'search'
      type: 'GET'
      url: "#{@apiPath}/users/search?sort_by=created_at"
      data:
        query: @query || '*'
        limit: 50
        role_ids: role_ids
        full:  true
      processData: true,
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @renderResult(data.user_ids)
        @stopLoading()
      done: =>
        @stopLoading()
    )

  new: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        title:     __('Users')
        home:      'users'
        object:    __('User')
        objects:   __('Users')
        navupdate: '#users'
      genericObject: 'User'
      screen: 'create',
      container: @el.closest('.content')
      callback: @newUserAddedCallback
      veryLarge: true
    )

  # GitHub Issue #3050
  # resets search input value to empty after new user added
  # resets any active role tab
  newUserAddedCallback: =>
    @searchInput.val('')
    @query = ''
    @resetActiveTabs()
    @search()

  resetActiveTabs: ->
    @$('.tab.active').removeClass('active')

  import: (e) ->
    e.preventDefault()
    new App.Import(
      baseUrl: '/api/v1/users'
      container: @el.closest('.content')
    )

App.Config.set( 'User', { prio: 1000, name: __('Users'), parent: '#manage', target: '#manage/users', controller: User, permission: ['admin.user'] }, 'NavBarAdmin' )
