class ProfilePassword extends App.ControllerSubContent
  requiredPermission: 'user_preferences.password'
  header: 'Password'
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>

    # item
    html = $( App.view('profile/password')() )

    configure_attributes = [
      { name: 'password_old', display: 'Current password', tag: 'input', type: 'password', limit: 100, null: false, class: 'input', single: true  },
      { name: 'password_new', display: 'New password',     tag: 'input', type: 'password', limit: 100, null: false, class: 'input',  },
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
        msg:       'Can\'t update password, your new passwords do not match. Please try again!'
        removeAll: true
      return
    if !params['password_new']
      @formEnable(e)
      @notify
        type:      'error'
        msg:       'Please supply your new password!'
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
    )

  success: (data) =>
    if data.message is 'ok'
      @render()
      @notify(
        type: 'success'
        msg:  App.i18n.translateContent( 'Password changed successfully!' )
      )
    else
      if data.notice
        @notify
          type:      'error'
          msg:       App.i18n.translateContent( data.notice[0], data.notice[1] )
          removeAll: true
      else
        @notify
          type:      'error'
          msg:       'Unable to set password. Please contact your administrator.'
          removeAll: true
      @formEnable( @$('form') )

App.Config.set('Password', { prio: 2000, name: 'Password', parent: '#profile', target: '#profile/password', controller: ProfilePassword, permission: ['user_preferences.password'] }, 'NavBarProfile')
