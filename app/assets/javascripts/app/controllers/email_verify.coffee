class Index extends App.Controller
  constructor: ->
    super
    @verifyCall()

  verifyCall: =>
    @ajax(
      id:          'email_verify'
      type:        'POST'
      url:         "#{@apiPath}/users/email_verify"
      data:        JSON.stringify(token: @token)
      processData: true
      success: (data, status, xhr) =>
        App.Auth.loginCheck()
        @navigate '#'

        @notify
          type:      'success'
          msg:       App.i18n.translateContent('Woo hoo! Your email address has been verified!')
          removeAll: true
          timeout: 2000

      error: (data, status, xhr) =>
        @navigate '#'

        @notify
          type:      'error'
          msg:       App.i18n.translateContent('Unable to verify email. Please contact your administrator.')
          removeAll: true
    )

App.Config.set('email_verify/:token', Index, 'Routes')
