# Injects the Email Notification section into the Microsoft 365 Graph Email
# Accounts tab (below the channel list) and handles the OAuth redirect response
# for the microsoft_graph_outbound adapter.

class App.MicrosoftGraphNotification extends App.Controller
  constructor: ->
    super
    @bindGraphPageNotificationInjector()
    @bindAdapterChangeHandler()
    @bindAjaxRedirectHandler()

  bindGraphPageNotificationInjector: ->
    # After the MS Graph channel index loads and renders, append the notification
    # section below the channel list — same position as the Email channel page.
    $(document).ajaxComplete (event, xhr, settings) =>
      return if !settings.url || settings.url.indexOf('channels/admin/microsoft_graph') is -1
      # Only act on GET (index), not POST (notification/group/etc.)
      return if settings.type isnt 'GET'

      # Small delay to let render() finish painting the DOM
      @delay(
        ->
          # Find the Accounts tab content on the MS Graph page
          pageContent = $('#c-account .page-content')
          return if !pageContent.length

          # Don't inject if app is not connected (intro page shown)
          return if !pageContent.length or pageContent.closest('.content').find('.js-new').length is 0

          # Remove previous injection to avoid duplicates (re-render)
          pageContent.closest('#c-account').find('.js-notification-section').remove()

          # Create container and append after page-content
          container = $('<div class="js-notification-section"></div>')
          pageContent.after(container)

          # Instantiate the shared notification controller
          new App.ChannelEmailNotification(el: container)
        200
        'ms-graph-notification-inject'
      )

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
