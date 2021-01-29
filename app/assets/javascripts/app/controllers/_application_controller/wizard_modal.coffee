class App.ControllerWizardModal extends App.ControllerFullPage
  className: 'modal fade'

  constructor: ->
    super

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender', =>
      @render()
      'wizard'
    )

  goToSlide: (e) =>
    e.preventDefault()
    slide = $(e.target).data('slide')
    return if !slide
    @showSlide(slide)

  showSlide: (name) =>
    @hideAlert(name)
    @$('.setup.wizard').addClass('hide')
    @$(".setup.wizard.#{name}").removeClass('hide')
    @$(".setup.wizard.#{name} input, .setup.wizard.#{name} select").first().focus()

  showAlert: (screen, message) =>
    @$(".#{screen}").find('.alert').first().removeClass('hide').text(App.i18n.translatePlain(message))

  hideAlert: (screen) =>
    @$(".#{screen}").find('.alert').first().addClass('hide')

  disable: (e) =>
    @formDisable(e)
    @$('.wizard-controls .btn').attr('disabled', true)

  enable: (e) =>
    @formEnable(e)
    @$('.wizard-controls .btn').attr('disabled', false)

  hide: (e) =>
    e.preventDefault()
    @el.modal('hide')

  showInvalidField: (screen, fields) =>
    @$(".#{screen}").find('.form-group').removeClass('has-error')
    return if !fields
    for field, type of fields
      if type
        @$(".#{screen}").find("[name=\"options::#{field}\"]").closest('.form-group').addClass('has-error')

  render: ->
    # do nothing

