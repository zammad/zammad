class App.TwoFactorConfigurationModalRecoveryCodes extends App.TwoFactorConfigurationModal
  buttonSubmit: __("OK, I've saved my recovery codes")
  buttonClass: 'btn--success'
  leftButtons: [
    {
      className: 'js-print',
      text: __('Print')
    },
    {
      className: 'js-copy',
      text: __('Copy')
    }
  ]
  head: __('Save Codes')
  events:
    'click .js-print': 'print'
    'click .js-copy':  'copy'

  constructor: (params) ->
    # params set at the top of the class may be overrided by the Two Factor setup wizard
    # hiding cancel button here to ensure it's not called shown in this modal
    params.buttonCancel = false

    @method = App.Config.get('TwoFactorMethods').RecoveryCodes

    super(params)

    @$('.js-print, .js-copy').removeClass('btn--text').removeClass('btn--subtle').addClass('btn--primary')


    addEventListener('beforeprint', @beforePrint)
    addEventListener('afterprint', @afterPrint)

  content: ->
    false

  onSubmit: =>
    @closeWithFade()

  onClose: =>
    @successCallback() if @successCallback

  render: ->
    super

    $('.modal .js-loading').removeClass('hide')
    $('.modal .btn-success').addClass('hide')

    if @prefetchedRecoveryCodes
      @didFetch(@prefetchedRecoveryCodes)
      return

    @fetchRecoveryCodes()

  fetchRecoveryCodes: =>
    @ajax(
      id: 'two_factor_recovery_codes_generate'
      type: 'POST'
      url: "#{@apiPath}/users/two_factor/recovery_codes_generate"
      data: JSON.stringify(token: @token)
      processData: true
      success: @didFetch
    )

  didFetch: (recovery_codes) =>
    if recovery_codes?.invalid_password_token
      @invalidPasswordToken()
      return

    content = $(App.view('widget/two_factor_configuration/recovery_codes')(
      recovery_codes: recovery_codes
    ))

    $('.modal .js-loading').addClass('hide')
    $('.modal .btn-success').removeClass('hide')
    $('.modal-body').html(content)

  print: (e) ->
    e.preventDefault()

    window.print()

  release: ->
    super

    removeEventListener('beforeprint', @beforePrint)
    removeEventListener('afterprint', @afterPrint)

  copy: (e) ->
    e.preventDefault()

    text = @$('code').text()

    @copyToClipboardWithTooltip(text, e.target,'.modal-body', true)

  beforePrint: =>
    @originalHead = @$('.modal-title').text()
    @$('.modal-title').text @head

  afterPrint: =>
    @$('.modal-title').text @originalHead
    @originalHead = undefined
