class Index extends App.Controller
  constructor: ->
    super
    @authenticateCheckRedirect()
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
    new Success(el: @el)

  error: =>
    new Fail(el: @el)

class Success extends App.ControllerContent
  constructor: ->
    super
    @render()

    # rerender view, e. g. on language change
    @bind 'ui:rerender', =>
      @render()

  render: =>
    @renderScreenSuccess(
      detail: 'Woo hoo! Your email address has been verified!'
    )
    delay = =>
      @navigate '#'
    @delay(delay, 20500)

class Fail extends App.ControllerContent
  constructor: ->
    super
    @render()

    # rerender view, e. g. on language change
    @bind 'ui:rerender', =>
      @render()

  render: =>
    @renderScreenError(
      detail: 'Unable to verify email. Please contact your administrator.'
    )

App.Config.set('email_verify/:token', Index, 'Routes')
