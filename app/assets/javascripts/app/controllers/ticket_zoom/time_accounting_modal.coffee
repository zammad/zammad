class App.TicketZoomTimeAccountingModal extends App.ControllerModal
  @include App.TimeAccountingUnitMixin

  buttonClose: true
  buttonCancel: false
  buttonSubmit: __('Account Time')
  buttonClass: 'btn--success'
  leftButtons: [{
    className: 'js-skip',
    text: __('Skip')
  }]
  head: __('Time Accounting')
  small: true

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-cancel':                   'cancel'
    'click .js-close':                    'cancel'
    'click .js-skip':                     'skip'

  constructor: ->
    super

    @controllerBind('config_update', (data) =>
      return if not /^time_accounting_unit/.test(data.name) or not /^time_accounting_type/.test(data.name)
      @render()
    )

    @subscribeId = App.TicketTimeAccountingType.subscribe(@render, initFetch: true)

  release: =>
    App.TicketTimeAccountingType.unsubscribe(@subscribeId)

  content: ->
    configure_attributes = [
      { name: 'time_unit', display: __('Accounted Time'), tag: 'input', type: 'text', null: false, placeholder: __('Enter the time you want to record'), appendText: @timeAccountingDisplayUnit() }
    ]

    if @Config.get('time_accounting_types')

      # Pre-select the default activity type, but only if it's active.
      if @Config.get('time_accounting_type_default')
        defaultType   = App.TicketTimeAccountingType.find(@Config.get('time_accounting_type_default'))
        defaultTypeId = defaultType.active and defaultType.id

      configure_attributes.push
        name: 'accounted_time_type_id'
        display: __('Activity Type')
        tag: 'select'
        relation: 'TicketTimeAccountingType'
        null: true
        nulloption: true
        value: defaultTypeId

    @form = new App.ControllerForm(
      model:     { configure_attributes: configure_attributes }
      autofocus: true
    )

    @form.el

  skip: (e) =>
    return if !@submitCallback
    @submitCallback({})
    @close(e)

  onCancel: =>
    return if !@cancelCallback
    @cancelCallback()

  onClose: ->
    return if !@cancelCallback
    @cancelCallback()

  onSubmit: (e) =>
    e.preventDefault()
    @formDisable(e)

    params = @formParams()

    errors = @form.validate(params)

    if !_.isEmpty(errors)
      @formEnable(e)
      @formValidate(form: @form.el, errors: errors)
      return false

    params.time_unit = params.time_unit.replace(',', '.')

    if isNaN(parseFloat(params.time_unit)) or /[A-z]|\s/.test(params.time_unit)
      errors =
        time_unit: __('is not a number')
      @formEnable(e)
      @formValidate(form: @form.el, errors: errors)
      return false

    @close()
    @submitCallback(params) if @submitCallback
