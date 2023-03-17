class ProfilePassword extends App.ControllerSubContent
  requiredPermission: 'user_preferences.password'
  header: __('Password')
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>

    # item
    html = $( App.view('profile/password')() )

    configure_attributes = [
      { name: 'password_old', display: __('Current password'), tag: 'input', type: 'password', limit: 100, null: false, class: 'input', single: true  },
      { name: 'password_new', display: __('New password'),     tag: 'input', type: 'password', limit: 100, null: false, class: 'input',  },
    ]

    @form = new App.ControllerForm(
      el:        html.find('.password_item')
      model:     { configure_attributes: configure_attributes }
      autofocus: false
    )
    @html html

  update: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    @formDisable(e)

    # validate
    if params['password_new_confirm'] isnt params['password_new']
      @formEnable(e)
      @$('[name=password_new]').val('')
      @$('[name=password_new_confirm]').val('')
      @notify
        type:      'error'
        msg:       __('Can\'t update password, your entered passwords do not match. Please try again!')
        removeAll: true
      return
    if !params['password_new']
      @formEnable(e)
      @notify
        type:      'error'
        msg:       __('Please supply your new password!')
        removeAll: true
      return

    # get data
    @ajax(
      id:          'password_reset'
      type:        'POST'
      url:         @apiPath + '/users/password_change'
      data:        JSON.stringify(params)
      processData: true
      success:     @success
      error:       @error
    )

  success: =>
    @render()

    @notify(
      type: 'success'
      msg:  App.i18n.translateContent( 'Password changed successfully!' )
    )

  error: (xhr, status, error) =>
    return if xhr.status != 422

    data = xhr.responseJSON

    message = if data.notice
                App.i18n.translateContent( data.notice[0], data.notice[1] )
              else
                __('The password could not be set. Please contact your administrator.')

    @notify
      type:      'error'
      msg:       message
      removeAll: true

    @formEnable( @$('form') )

App.Config.set('Password', {
  prio: 2000,
  name: __('Password'),
  parent: '#profile',
  target: '#profile/password',
  controller: ProfilePassword,
  permission: (controller) ->
    return false if !App.Config.get('user_show_password_login') && !controller.permissionCheck('admin.*')
    return controller.permissionCheck('user_preferences.password')
}, 'NavBarProfile')
