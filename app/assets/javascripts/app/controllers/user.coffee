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
      defaultOrder: 'DESC'
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
        searchPlaceholder: __('Search for users')
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

    removeGroupPermissions = (params, attribute, attributes, classname, form, ui) ->
      return if item.active

      form.find('[data-attribute-name="group_ids"]').remove()
      form.find('[name="active"]').closest('.form-group').find('.help-block').html(
        App.i18n.translateInline('You cannot view or change the group permissions of an inactive user. Activate them first to manage their permissions.')
      )

    hideOrganizationHelp = (params, attribute, attributes, classname, form, ui) ->
      return if App.Config.get('ticket_organization_reassignment')

      form.find('[name="organization_id"]').closest('.form-group').find('.help-message').addClass('hide')

    item.secondaryOrganizations(0, 1000, =>
      constructor = @editControllerClass()

      wasInactive = not item.active

      new constructor(
        id: item.id
        pageData:
          title:     __('Users')
          home:      'users'
          object:    __('User')
          objects:   __('Users')
          navupdate: '#users'
        genericObject: 'User'
        container: @el.closest('.content')
        handlers: [removeGroupPermissions, hideOrganizationHelp]
        screen: 'edit'
        veryLarge: true
        contentFormParams: ->
          @item.group_ids = undefined if not @item.active # do not submit empty group_ids if user is inactive
          @item
        onSubmit: (e) ->
          params = @formParam(e.target)
          @item.load(params)

          # validate form using HTML5 validity check
          element = $(e.target).closest('form').get(0)
          if element && element.reportValidity && !element.reportValidity()
            return false

          # validate
          errors = @item.validate(
            controllerForm: @controller
          )

          if @validateOnSubmit
            errors = _.extend({}, errors, @validateOnSubmit(params))

          if !_.isEmpty(errors)
            @log 'error', errors
            @formValidate( form: e.target, errors: errors )
            return false

          # disable form
          @formDisable(e)

          # save object
          ui = @
          @item.save(
            removedFields: @controller.removedFields(@controller.form)
            done: ->
              if ui.callback
                item = App[ ui.genericObject ].fullLocal(@id)
                ui.callback(item)

              if wasInactive and item.active
                wasInactive = false

                # Re-render the modal with success alert on top.
                ui.render()
                ui.el
                  .find('.js-success')
                  .html(App.i18n.translateInline('User updated successfully.'))
                  .removeClass('hide')

                return

              ui.close()

            fail: (settings, details) =>
              App[ ui.genericObject ].fetch(id: @id)
              ui.log 'errors'
              ui.formEnable(e)

              if details && details.invalid_attribute
                @formValidate( form: e.target, errors: details.invalid_attribute )
              else
                ui.controller.showAlert(details.error_human || details.error || __('The object could not be updated.'))
          )
      )
    )

App.Config.set( 'User', { prio: 1000, name: __('Users'), parent: '#manage', target: '#manage/users', controller: User, permission: ['admin.user'] }, 'NavBarAdmin' )
