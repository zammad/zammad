class App.InviteUser extends App.ControllerWizardModal
  events:
    'click  .js-close':     'hide'
    'submit .js-user':      'submit'
    'click  .js-goToSlide': 'goToSlide'

  constructor: ->
    super

    if @container
      @el.addClass('modal--local')

    @render()

    @el.modal
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    .on
      'hidden.bs.modal': =>
        if @callback
          @callback()
        @el.remove()

  render: =>
    modal = $(App.view('widget/invite_user')(
      head: @head
    ))
    new App.ControllerForm(
      el:        modal.find('.js-form')
      model:     App.User
      screen:    @screen
      autofocus: true
    )
    if !@initRenderingDone
      @initRenderingDone = true
      @html modal
    else
      @$('.modal-dialog').replaceWith(modal)

  submit: (e) =>
    e.preventDefault()
    @showSlide('js-waiting')
    @formDisable(e)
    @params = @formParam(e.target)

    # set invite flag
    @params.invite = true

    # find signup roles
    if @signup
      @params.role_ids = App.Role.search(
        filter:
          active: true
          default_at_signup: true
      ).map((role) -> role.id)

    user = new App.User
    user.load(@params)

    errors = user.validate(
      screen: @screen
    )
    if errors
      @log 'error new', errors
      @formValidate(form: e.target, errors: errors)
      @formEnable(e)
      @showSlide('js-user')
      return false

    # save user
    user.save(
      done: (r) =>
        @showSlide('js-success')
        @el.modal('hide')

      fail: (settings, details) =>
        @formEnable(e)
        @showSlide('js-user')
        @showAlert('js-user',  details.error_human || details.error)
    )
