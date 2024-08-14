class App.TwoFactorConfigurationModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Set Up')
  buttonClass: 'btn--success'
  headPrefix: __('Set up two-factor authentication')
  shown: true
  className: 'modal' # no automatic fade transitions

  constructor: (params) ->
    if params.overrideHeadPrefix
      params.headPrefix = params.overrideHeadPrefix

    super(params)

  closeWithFade: =>
    @el.addClass('fade')
    @el.closest('.modal-backdrop').addClass('fade')
    @close()

  nextModalClass: ->
    throw 'You need to implement nextModalClass() method'

  next: (modalOptions = {}) =>
    @close()

    modalOptions.container          ||= @container
    modalOptions.overrideHeadPrefix ||= @overrideHeadPrefix
    modalOptions.successCallback    ||= @successCallback

    constructor = modalOptions.nextModalClass || @nextModalClass()

    new constructor(_.extend(
      {},
      modalOptions,
      backdrop: @backdrop
      buttonClose: @buttonClose
      buttonCancel: @buttonCancel
      onCancel: @onCancel
    ))

  finalizeConfigurationWizard: (data, modalOptions = {}) =>
    if recovery_codes = data?.recovery_codes
      @next(_.extend(
        {},
        modalOptions,
        prefetchedRecoveryCodes: recovery_codes
        nextModalClass:          App.TwoFactorConfigurationModalRecoveryCodes
      ))
      return

    @closeWithFade()
    @successCallback() if @successCallback
    return

  onSubmit: ->
    @notify
      type:      'success'
      msg:       __('Two-factor authentication method was set up successfully.')
      removeAll: true

    @successCallback() if @successCallback
