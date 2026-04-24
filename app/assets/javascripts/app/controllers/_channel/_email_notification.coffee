# Shared Email Notification tab controller.
# Can be included as a tab in any channel page (Email, Microsoft Graph, etc.)
# Loads the notification channel data from the email index endpoint and renders
# the notification section with an Edit button that opens the notification wizard.

class App.ChannelEmailNotification extends App.Controller
  events:
    'click .js-editNotificationOutbound': 'editNotificationOutbound'

  constructor: ->
    super
    @load()

  load: =>
    @startLoading()
    @ajax(
      id:   'email_notification_tab'
      type: 'GET'
      url:  "#{@apiPath}/channels_email"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @channelDriver = data.channel_driver
        @config = data.config
        @render(data)
    )

  render: (data = {}) =>
    notification_channels = []
    if data.notification_channel_ids
      for channel_id in data.notification_channel_ids
        notification_channels.push App.Channel.find(channel_id)

    @html App.view('channel/email_notification_overview')(
      notification_channels: notification_channels
      config: @config
    )

  editNotificationOutbound: (e) =>
    e.preventDefault()
    id      = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    # ChannelEmailNotificationWizard is file-local in email.coffee, so we
    # trigger the edit via a synthetic click on the email channel page.
    # Instead, we re-implement the wizard opening inline.
    @openNotificationWizard(channel)

  openNotificationWizard: (channel) =>
    # Load the notification wizard dynamically. Since ChannelEmailNotificationWizard
    # is not globally accessible, we navigate to the email channel page to trigger
    # the edit there. This is a pragmatic workaround.
    # However, we can also replicate the wizard-opening behavior:
    new App.ChannelEmailNotificationWizardProxy(
      container:     @el.closest('.content')
      channel:       channel
      callback:      @load
      channelDriver: @channelDriver
    )


# Proxy class that opens the notification wizard by temporarily navigating to
# the email channel, or by creating the wizard modal inline.
# Since the actual ChannelEmailNotificationWizard is file-local, we build the
# wizard modal here using the same template and behavior.
class App.ChannelEmailNotificationWizardProxy extends App.ControllerWizardModal
  elements:
    '.modal-body': 'body'
  events:
    'change [name="options::ssl_verify"]': 'toggleSslVerifyAlert'
    'change [name="options::port"]':       'toggleSslVerifyVisibility'
    'change .js-outbound [name=adapter]':  'toggleOutboundAdapter'
    'submit .js-outbound':                 'probleOutbound'
    'click  .js-close':                    'hide'

  constructor: ->
    super

    @account =
      inbound:
        adapter: undefined
        options: undefined
      outbound:
        adapter: undefined
        options: undefined
      meta: {}

    if @channel
      @account =
        inbound: clone(@channel.options.inbound)
        outbound: clone(@channel.options.outbound)

    @render()
    @toggleSslVerifyAlert(target: @el.find('[name="options::ssl_verify"]'))

    @el.modal(
      keyboard:  true
      show:      true
      backdrop:  true
      container: @container
    ).on(
      'show.bs.modal':   @onShow
      'shown.bs.modal': =>
        @el.addClass('modal--ready')
        @onShown() if @onShown
      'hidden.bs.modal': =>
        if @callback
          @callback()
        @el.remove()
    )
    if @slide
      @showSlide(@slide)

  render: =>
    super

    @html App.view('channel/email_notification_wizard')()
    @showSlide('js-outbound')

    configureAttributesOutbound = [
      { name: 'adapter', display: __('Send Mails via'), tag: 'select', multiple: false, null: false, options: @channelDriver.email.outbound, translate: true },
    ]
    new App.ControllerForm(
      el:    @$('.base-outbound-type')
      model:
        configure_attributes: configureAttributesOutbound
        className: ''
      params:
        adapter: @account.outbound.adapter || 'sendmail'
    )
    @toggleOutboundAdapter()

  toggleOutboundAdapter: =>
    @el.find('.base-outbound-settings').html('')
    adapter = @$('.js-outbound [name=adapter]').val()
    if adapter is 'smtp'
      configureAttributesOutbound = [
        { name: 'options::host',       display: __('Host'),     tag: 'input', type: 'text',     limit: 120, null: false, autocapitalize: false, autofocus: true },
        { name: 'options::user',       display: __('User'),     tag: 'input', type: 'text',     limit: 120, null: true, autocapitalize: false, autocomplete: 'off' },
        { name: 'options::password',   display: __('Password'), tag: 'input', type: 'password', limit: 120, null: true, autocapitalize: false, autocomplete: 'new-password', single: true },
        { name: 'options::port',       display: __('Port'),     tag: 'input', type: 'text',     limit: 6,   null: true, autocapitalize: false, item_class: 'formGroup--halfSize' },
        { name: 'options::ssl_verify', display: __('SSL verification'), tag: 'boolean', default: true, null: true, translate: true, item_class: 'formGroup--halfSize' },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
        params: @account.outbound
      )
      @$('.js-outbound .btn--primary').text(App.i18n.translateContent('Continue'))
    else if adapter is 'microsoft_graph_outbound'
      @el.find('.js-sslVerifyAlert').addClass('hide')

      currentMailboxType = 'user'
      currentSharedMailbox = ''
      if @account?.outbound?.adapter is 'microsoft_graph_outbound'
        if @account.outbound.options?.shared_mailbox
          currentMailboxType = 'shared'
          currentSharedMailbox = @account.outbound.options.shared_mailbox

      configureAttributesOutbound = [
        { name: 'mailbox_type',   display: __('Mailbox type'),   tag: 'select', options: { user: __('User mailbox'), shared: __('Shared mailbox') }, translate: true, null: false, value: currentMailboxType },
        { name: 'shared_mailbox', display: __('Shared mailbox'), tag: 'input', type: 'email', limit: 120, null: true, placeholder: __('user@your-organization.tld'), value: currentSharedMailbox, hide: currentMailboxType isnt 'shared' },
      ]
      @form = new App.ControllerForm(
        el:    @$('.base-outbound-settings')
        model:
          configure_attributes: configureAttributesOutbound
          className: ''
        handlers: [
          App.FormHandlerChannelAccountMailboxType.run
        ]
      )
      @$('.js-outbound .btn--primary').text(App.i18n.translateContent('Authenticate'))
    else
      # sendmail — no extra fields
      @$('.js-outbound .btn--primary').text(App.i18n.translateContent('Continue'))

  toggleSslVerifyVisibility: (e) ->
    elem      = $(e.target)
    isEnabled = elem.val() is '' or elem.val() is '465' or elem.val() is '587'
    sslVerifyField = elem.closest('form').find('[name="options::ssl_verify"]')
    if isEnabled
      sslVerifyField.removeAttr('disabled')
    else
      sslVerifyField.attr('disabled', 'disabled')
    @toggleSslVerifyAlert(target: sslVerifyField, !isEnabled)

  toggleSslVerifyAlert: (e, forceInvisible) ->
    elem           = $(e.target)
    isAlertVisible = if forceInvisible then false else elem.val() != 'true'
    elem.closest('.modal-content')
      .find('.js-sslVerifyAlert')
      .toggleClass('hide', !isAlertVisible)

  probleOutbound: (e) =>
    e.preventDefault()

    params = @formParam(e.target)
    params.channel_id = @channel.id

    adapter = @$('.js-outbound [name=adapter]').val()

    if adapter is 'microsoft_graph_outbound'
      if params.mailbox_type is 'shared' && !params.shared_mailbox
        @showAlert('js-outbound', __('Please enter a shared mailbox address.'))
        return
      # Move mailbox fields into options for the server
      params.options ||= {}
      params.options.shared_mailbox = params.shared_mailbox if params.mailbox_type is 'shared'
      delete params.mailbox_type
      delete params.shared_mailbox

    sslVerifyField = $(e.target).closest('form').find('[name="options::ssl_verify"]')
    if sslVerifyField[0]?.disabled
      params.options ||= {}
      params.options.ssl_verify = false

    @disable(e)
    @showSlide('js-test')

    @ajax(
      id:   'email_outbound'
      type: 'POST'
      url:  "#{@apiPath}/channels_email_notification"
      data: JSON.stringify(params)
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'redirect' && data.url
          window.location.href = data.url
          return
        if data.result is 'ok'
          @el.modal('hide')
        else
          @showSlide('js-outbound')
          @showAlert('js-outbound', data.message_human || data.message)
          @showInvalidField('js-outbound', data.invalid_field)
        @enable(e)
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @showSlide('js-outbound')
        @showAlert('js-outbound', data.message_human || data.message || data.error)
        @showInvalidField('js-outbound', data.invalid_field)
    )
