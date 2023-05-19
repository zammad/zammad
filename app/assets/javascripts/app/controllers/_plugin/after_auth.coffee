class AfterAuth extends App.Controller
  constructor: ->
    super

    return if !@authenticateCheck()

    after_auth = App.Config.get('after_auth')
    return if _.isEmpty(after_auth)

    new App['AfterAuth' + after_auth.type](
      data: after_auth.data
    )

App.Config.set('after_auth', AfterAuth, 'Plugins')
