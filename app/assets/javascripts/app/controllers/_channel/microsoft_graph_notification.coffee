# Handles the OAuth redirect response for the microsoft_graph_outbound adapter
# and injects the correct form fields when that adapter is selected in the
# Email Notification wizard.

class App.MicrosoftGraphNotification extends App.Controller
  constructor: ->
    super
    @bindAdapterChangeHandler()
    @bindAjaxRedirectHandler()

  bindAdapterChangeHandler: ->
    # Inject mailbox type fields into the Email Notification wizard
    # (either the original one on the Email page or our proxy on the MS Graph page)
    # when microsoft_graph_outbound is selected in the dropdown.
    $(document).on 'change', '.js-outbound [name=adapter]', (e) ->
      adapter = $(e.target).val()
      modal   = $(e.target).closest('.modal-content')

      # Only act on the Email Notification wizard
      return if !modal.find('.modal-title').text().match(/Email Notification/i)

      settingsContainer = modal.find('.base-outbound-settings')
      sslAlert          = modal.find('.js-sslVerifyAlert')
      submitBtn         = modal.find('.btn--primary')

      if adapter is 'microsoft_graph_outbound'
        sslAlert.addClass('hide')
        settingsContainer.empty()

        form = new App.ControllerForm(
          el: settingsContainer
          model:
            configure_attributes: [
              { name: 'mailbox_type',   display: __('Mailbox type'),   tag: 'select', options: { user: __('User mailbox'), shared: __('Shared mailbox') }, translate: true, null: false, value: 'user' },
              { name: 'shared_mailbox', display: __('Shared mailbox'), tag: 'input', type: 'email', limit: 120, null: true, placeholder: __('user@your-organization.tld'), hide: true },
            ]
            className: ''
          handlers: [
            App.FormHandlerChannelAccountMailboxType.run
          ]
        )

        submitBtn.text(App.i18n.translateContent('Authenticate'))
      else
        submitBtn.text(App.i18n.translateContent('Continue'))

  bindAjaxRedirectHandler: ->
    # The server returns { result: 'redirect', url: '...' } for microsoft_graph_outbound.
    # Intercept globally so both the original email wizard and our proxy wizard handle it.
    $(document).ajaxComplete (event, xhr, settings) ->
      return if !settings.url || settings.url.indexOf('channels_email_notification') is -1
      try
        data = JSON.parse(xhr.responseText)
      catch
        return
      if data.result is 'redirect' && data.url
        window.location.href = data.url

App.Config.set('microsoft_graph_notification', App.MicrosoftGraphNotification, 'Plugins')
