# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The states of an internal-only email server, shared by the notification sender dialog and the
#   notification step of the setup wizard: the usual check, the question after the server refused
#   its test email ('question'), and the check with the address the admin enters ('internal-only').
App.EmailNotificationInternalOnly =
  # A form that is rendered again lost what the admin entered, so it starts with the usual check.
  internalOnlyRender: ->
    @$('.js-internalOnly').html App.view('channel/email_notification_internal_only')()

    @internalOnlySet('usual')

  internalOnlySet: (state) ->
    @internalOnlyState = state

    @$('.js-internalOnlyQuestion').toggleClass('hide', state isnt 'question')
    @$('.js-internalOnlyNote').toggleClass('hide', state isnt 'internal-only')

  internalOnlyAttributes: (attributes) ->
    return attributes if @internalOnlyState isnt 'internal-only'

    result = []
    for attribute in attributes
      result.push(attribute)

      continue if attribute.name isnt 'options::host'

      # Not below "options": the options are saved, the test address is not. Type "text", because the
      #   pattern of an "email" input refuses an address on a host without a domain, which the server takes.
      result.push({ name: 'test_address', display: __('Custom verification email'), tag: 'input', type: 'text', limit: 120, null: false, autocapitalize: false, autocomplete: 'off' })

    result

  internalOnlyResult: (data) ->
    if @internalOnlyState isnt 'internal-only'
      @internalOnlySet(if data.refused then 'question' else 'usual')

    @$('[name="test_address"]').closest('.form-group').toggleClass('has-error', !!data.invalid_field?.test_address)

  internalOnlyConfirm: (e) ->
    e.preventDefault()

    params              = @formParam(@$('.js-outbound'))
    params.test_address = App.Session.get('email')

    @hideAlert('js-outbound')
    @internalOnlySet('internal-only')

    @toggleOutboundAdapter(undefined, params)

    @$('[name="options::port"]').trigger('change')
    @$('[name="test_address"]').trigger('focus')

  internalOnlyReset: ->
    @internalOnlySet('usual')

    @$('[name="test_address"]').closest('.form-group').remove()
