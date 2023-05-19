class App.ControllerAfterAuthModal extends App.ControllerModal
  includeForm: false
  data: {}
  logoutOnCancel: true
  backdrop: 'static'
  keyboard: false
  buttonClose: false
  buttonSubmit: false
  buttonCancel: __('Cancel')

  onCancel: (e) ->
    if @logoutOnCancel
      App.Auth.logout()

  fetchAfterAuth: ->
    @ajax(
      id:      'after_auth'
      type:    'GET'
      url:     "#{@apiPath}/users/after_auth"
      success: (after_auth) ->
        App.Config.set('after_auth', after_auth)

        return if _.isEmpty(after_auth)

        new App['AfterAuth' + after_auth.type](
          data: after_auth.data
        )
    )
