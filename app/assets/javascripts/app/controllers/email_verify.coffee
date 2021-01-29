class EmailVerify extends App.Controller
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
      success:     @success
      error:       @error
    )

  success: =>
    new Success(el: @el, appEl: @appEl)

  error: =>
    new Fail(el: @el, appEl: @appEl)

class Success extends App.ControllerAppContent
  constructor: ->
    super
    @render()

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', =>
      @render()
    )

  render: =>
    @renderScreenSuccess(
      detail: 'Woo hoo! Your email address has been verified!'
    )
    delay = =>
      @navigate '#'
    @delay(delay, 2000)

class Fail extends App.ControllerAppContent
  constructor: ->
    super
    @render()

    # rerender view, e. g. on language change
    @controllerBind('ui:rerender', =>
      @render()
    )

  render: =>
    @renderScreenError(
      detail: 'Unable to verify email. Please contact your administrator.'
    )

App.Config.set('email_verify/:token', EmailVerify, 'Routes')
