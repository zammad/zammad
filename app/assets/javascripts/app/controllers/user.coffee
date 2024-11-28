class User extends App.ControllerSubContent
  @requiredPermission: 'admin.user'
  header: __('Users')
  constructor: ->
    super

    roles = App.Role.findAllByAttribute('active', true)
    roles = _.sortBy(roles, (role) -> role.name.toLowerCase())

    callbackLoginAttribute = (value, object, attribute, attributes) ->
      attribute.prefixIcon = null
      attribute.title = null

      if object.maxLoginFailedReached()
        attribute.title = App.i18n.translateContent('This user is currently blocked because of too many failed login attempts.')
        attribute.prefixIcon = 'lock'

      value

    @genericController = new App.ControllerGenericIndexUser(
      el: @el
      id: @id
      genericObject: 'User'
      importCallback: ->
        new App.Import(
          baseUrl: '/api/v1/users'
          container: @el.closest('.content')
        )
      defaultSortBy: 'created_at'
      searchBar: true
      searchQuery: @search_query
      filterMenu: [
        {
          name: 'Roles',
          data: _.map(roles, (role) -> return { id: role.id, name: role.name })
        }
      ]
      filterCallback: (active_filters, params) ->
        if active_filters && active_filters.length > 0
          params.role_ids = active_filters
        return params
      pageData:
        home: 'users'
        object: __('User')
        objects: __('Users')
        pagerAjax: true
        pagerBaseUrl: '#manage/users/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#users'
        buttons: [
          { name: __('Import'), 'data-type': 'import', class: 'btn' }
          { name: __('New User'), 'data-type': 'new', class: 'btn--success' }
        ]
        tableExtend: {
          callbackAttributes: {
            login: [ callbackLoginAttribute ]
          }
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
                    App.User.full(id, =>
                      @notify(
                        type: 'success'
                        msg:  __('User successfully unlocked!')
                      )
                    , true)
                )
            }
          ]
        }
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

class App.ControllerGenericIndexUser extends App.ControllerGenericIndex
  edit: (id, e) =>
    e.preventDefault()
    item = App.User.find(id)

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
        container: @el.closest('.content')
        handlers: [hideOrganizationHelp]
        screen: 'edit'
        veryLarge: true
      )
    )

App.Config.set( 'User', { prio: 1000, name: __('Users'), parent: '#manage', target: '#manage/users', controller: User, permission: ['admin.user'] }, 'NavBarAdmin' )
