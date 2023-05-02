class App.SettingTicketNotifications extends App.ControllerSubContent
  @include App.TicketNotificationMatrix

  @requiredPermission: 'admin.ticket'
  events:
    'click .js-ticketDefaultNotifications': 'saveDefaultNotifications'
    'click .js-ticketDefaultNotificationsReset': 'resetDefaultNotifications'
    'click .js-ticketDefaultNotificationsApplyToAll': 'applyDefaultNotificationsToAll'

  constructor: ->
    super
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    ticketAgentDefaultNotifications = @Config.get('ticket_agent_default_notifications') || {}

    @html App.view('settings/ticket_notifications')
      matrixTableHTML: @renderNotificationMatrix(ticketAgentDefaultNotifications)

  saveDefaultNotifications: (e) =>
    e.preventDefault()

    formParams = @formParam(e.target)

    App.Setting.set('ticket_agent_default_notifications', @updatedNotificationMatrixValues(formParams), notify: true)

  resetDefaultNotifications: (e) =>
    e.preventDefault()

    new App.ControllerConfirm(
      message: __('Are you sure? The agent default notifications settings will be reset to the system default.')
      callback: -> App.Setting.reset('ticket_agent_default_notifications', notify: true)
      container: @el.closest('.content')
    )

  applyDefaultNotificationsToAll: (e) =>
    e.preventDefault()

    @applyDefaultNotificationsToAllModal = new App.ControllerConfirmDelete(
      fieldDisplay:      __('Are you sure? Default notifications settings will be applied to all agents.')
      safeWord:          __('Confirm')
      head:              __('Confirmation')
      buttonSubmit:      __('Yes')
      notificationCallback: ->
        @close()
      callback: ->
        @el.find('.js-cancel, .js-submit').hide()

        @startLoading()
        App.Event.bind 'ticket_agent_default_notifications_applied', =>
          @notificationCallback()
        , 'ticket_agent_default_notifications_applied'

        @ajax(
          id:    'apply_ticket_agent_default_notifications_to_all'
          type:  'POST'
          url:   "#{@apiPath}/settings/ticket_agent_default_notifications/apply_to_all"
        )
      container: @el.closest('.content')
      release: ->
        super
        App.Event.unbindLevel 'ticket_agent_default_notifications_applied'
    )
