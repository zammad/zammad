class GettingStartedEmailNotification extends App.ControllerWizardFullScreen
  events:
    'change .js-outbound [name=adapter]': 'toggleOutboundAdapter'
    'submit .js-outbound':                'submit'

  constructor: ->
    super

    # redirect if we are not admin
    if !@permissionCheck('admin.wizard')
      @navigate '#'
      return

    # set title
    @title 'Email Notifications'

    @channelDriver =
      email:
        inbound: {}
        outbound: {}

    @fetch()

  fetch: =>

    # get data
    @ajax(
      id:    'getting_started'
      type:  'GET'
      url:   "#{@apiPath}/getting_started"
      processData: true
      success: (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        @channelDriver = data.channel_driver

        # render page
        @render()
    )

  render: =>
    @replaceWith App.view('getting_started/email_notification')()
    configureAttributesOutbound = [
      { name: 'adapter', display: 'Send Mails via', tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound },
    ]
    new App.ControllerForm(
      el:    @$('.base-outbound-type')
      model:
        configure_attributes: configureAttributesOutbound
        className: ''
      params:
        adapter: 'sendmail'
    )
    @toggleOutboundAdapter()

  toggleOutboundAdapter: =>

    # show used backend
    @el.find('.base-outbound-settings').html('')
    adapter = @$('.js-outbound [name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',     display: 'Host',     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',     display: 'User',     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off' },
        { name: 'options::password', display: 'Password', tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'off', single: true },
        { name: 'options::port',     display: 'Port',     tag: 'input', type: 'text',     limit: 6,   null: true, autocapitalize: false },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
      )

  submit: (e) =>
    e.preventDefault()

    # get params
    params          = @formParam(e.target)
    params['email'] = 'me@localhost'
    @disable(e)

    @showSlide('js-test')

    @ajax(
      id:   'email_notification'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_notification"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'ok'
          for key, value of data.settings
            App.Config.set(key, value)
          if App.Config.get('system_online_service')
            @navigate 'getting_started/channel/email_pre_configured', { emptyEl: true }
          else
            @navigate 'getting_started/channel', { emptyEl: true }
        else
          @showSlide('js-outbound')
          @showAlert('js-outbound', data.message_human || data.message )
          @showInvalidField('js-outbound', data.invalid_field)
          @enable(e)

      fail: =>
        @showSlide('js-outbound')
        @showAlert('js-outbound', data.message_human || data.message )
        @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
    )

App.Config.set('getting_started/email_notification', GettingStartedEmailNotification, 'Routes')
