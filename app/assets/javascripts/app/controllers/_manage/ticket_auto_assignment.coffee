class App.SettingTicketAutoAssignment extends App.ControllerSubContent
  requiredPermission: 'admin.ticket_auto_assignment'
  events:
    'change .js-ticketAutoAssignment input': 'setTicketAutoAssignment'
    'click .js-timeAccountingFilter': 'setFilter'
    'click .js-timeAccountingFilterReset': 'resetFilter'

  elements:
    '.js-ticketAutoAssignment input': 'ticketAutoAssignment'

  constructor: ->
    super
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    currentNewTagSetting = @Config.get('ticket_auto_assignment') || false
    @lastNewTagSetting = currentNewTagSetting

    @html(App.view('settings/ticket_auto_assignment')())

    configure_attributes = [
      { name: 'condition',  display: 'Conditions for effected objects', tag: 'ticket_selector', null: false, preview: false, action: false, hasChanged: false },
    ]

    filter_params = App.Setting.get('ticket_auto_assignment_selector')
    @filter = new App.ControllerForm(
      el: @$('.js-selector')
      model:
        configure_attributes: configure_attributes,
      params: filter_params
      autofocus: true
    )


  setFilter: (e) =>
    e.preventDefault()

    # get form data
    params = @formParam(@filter.form)

    # save filter settings
    App.Setting.set('ticket_auto_assignment_selector', params, notify: true)

  resetFilter: (e) ->
    e.preventDefault()

    # save filter settings
    App.Setting.set('ticket_auto_assignment_selector', {}, notify: true)

  setTicketAutoAssignment: (e) =>
    value = @ticketAutoAssignment.prop('checked')
    App.Setting.set('ticket_auto_assignment', value)
