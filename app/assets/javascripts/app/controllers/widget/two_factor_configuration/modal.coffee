class App.TwoFactorConfigurationModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Set Up')
  buttonClass: 'btn--success'
  headPrefix: __('Set up two-factor authentication')
  shown: true
  className: 'modal' # no automatic fade transitions

  render: ->
    super

  closeWithFade: =>
    @el.addClass('fade')
    $('.modal-backdrop').addClass('fade')
    @close()

  nextModalClass: ->
    throw 'You need to implement nextModalClass() method'

  next: (modalOptions = {}) =>
    @close()

    constructor = @nextModalClass()

    new constructor(_.extend(
      {},
      modalOptions,
      backdrop: @backdrop
      buttonClose: @buttonClose
      buttonCancel: @buttonCancel
      onCancel: @onCancel
    ))

  onSubmit: ->
    @notify
      type:      'success'
      msg:       App.i18n.translateContent('Two-factor authentication method was set up successfully.')
      removeAll: true

    @successCallback() if @successCallback
