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
      { name: 'condition', display: 'Conditions for effected objects', tag: 'ticket_selector', null: false, preview: false, action: false, hasChanged: false, article: false },
    ]

    ticket_auto_assignment_selector = App.Setting.get('ticket_auto_assignment_selector')
    @filter = new App.ControllerForm(
      el: @$('.js-selector')
      model:
        configure_attributes: configure_attributes,
      params:
        condition: ticket_auto_assignment_selector.condition
      autofocus: true
    )

    configure_attributes = [
      { name: 'user_ids', display: 'Exception users', tag: 'column_select', multiple: true, null: true, relation: 'User', sortBy: 'firstname' },
    ]

    ticket_auto_assignment_user_ids_ignore = App.Setting.get('ticket_auto_assignment_user_ids_ignore')
    @filter = new App.ControllerForm(
      el: @$('.js-users')
      model:
        configure_attributes: configure_attributes,
      params:
        user_ids: ticket_auto_assignment_user_ids_ignore
      autofocus: false
    )

  setFilter: (e) =>
    e.preventDefault()

    # get form data
    params = @formParam(@filter.form)

    # save settings
    App.Setting.set('ticket_auto_assignment_selector', { condition: params.condition }, notify: true)
    App.Setting.set('ticket_auto_assignment_user_ids_ignore', params.user_ids, notify: false)

  resetFilter: (e) ->
    e.preventDefault()

    # save filter settings
    App.Setting.set('ticket_auto_assignment_selector', {}, notify: true)
    App.Setting.set('ticket_auto_assignment_user_ids_ignore', [], notify: false)

  setTicketAutoAssignment: (e) =>
    value = @ticketAutoAssignment.prop('checked')
    App.Setting.set('ticket_auto_assignment', value)
