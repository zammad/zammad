class UserSignupCheck extends App.Controller
  constructor: ->
    super

    # for browser test
    @controllerBind('user_signup_verify', (user) ->
      new Modal(user: user)
    )

    user = App.User.current()
    @verifyLater(user.id) if user?

  verifyLater: (userId) =>
    delay = =>
      @verify(userId)
    @delay(delay, 5000, 'user_signup_verify_dialog')

  verify: (userId) ->
    return if !userId
    return if !App.User.exists(userId)
    user = App.User.find(userId)
    return if user.source isnt 'signup'
    return if user.verified is true
    currentTime = new Date().getTime()
    createdAt = Date.parse(user.created_at)
    diff = currentTime - createdAt
    max = 1000 * 60 * 30 # show message if account is older then 30 minutes
    return if diff < max
    new Modal(user: user)

class Modal extends App.ControllerModal
  backdrop: false
  keyboard: false
  head: __('Account not verified')
  small: true
  buttonClose: false
  buttonCancel: false
  buttonSubmit: __('Resend verification email')

  constructor: ->
    super

  content: =>
    if !@sent
      return App.i18n.translateContent('Your account has not been verified. Please click on the link in the verification email.')
    content = App.i18n.translateContent('An email was sent to _%s_. Click the link in the email to verify your account.', @user.email)
    content += '<br><br>'
    content += App.i18n.translateContent('If you don\'t see the email, check other places it might be, like your junk, spam, social, or other folders.')
    content

  onSubmit: =>
    @ajax(
      id:          'email_verify_send'
      type:        'POST'
      url:         @apiPath + '/users/email_verify_send'
      data:        JSON.stringify(email: @user.email)
      processData: true
      success:     @success
      error:       @error
    )

  success: (data) =>
    @sent = true
    @update()

  error: (data, status, xhr) =>
    details = data.responseJSON || {}
    @contentInline =  details.error_human || details.error || __('Verification email could not be sent.')
    @update()

App.Config.set('user_signup', UserSignupCheck, 'Plugins')
