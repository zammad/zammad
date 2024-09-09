class App.SettingTicketDuplicateDetection extends App.ControllerSubContent
  @requiredPermission: 'admin.ticket_duplicate_detection'
  events:
    'change .js-ticketDuplicateDetection input': 'setTicketDuplicateDetection'
    'click .js-ticketDuplicateDetectionFilter': 'setFilter'
    'click .js-ticketDuplicateDetectionFilterReset': 'resetFilter'

  elements:
    '.js-ticketDuplicateDetection input': 'ticketDuplicateDetection'

  constructor: ->
    super
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    currentNewTagSetting = @Config.get('ticket_duplicate_detection') || false
    @lastNewTagSetting = currentNewTagSetting

    @html(App.view('settings/ticket_duplicate_detection')())

    options = {}

    for attribute in App.Ticket.configure_attributes
      if _.contains(['input', 'select', 'tree_select', 'user_autocompletion', 'boolean', 'date', 'datetime', 'integer'], attribute.tag)
        if attribute.readonly isnt 1
          options[attribute.name] = App.i18n.translateInline(attribute.display)

    configure_attributes = [
      { name: 'attributes', display: __('Attributes to compare'), tag: 'column_select', multiple: true, null: false, options: options, sortBy: 'firstname' },
      { name: 'title', display: __('Warning title'), tag: 'input', null: false },
      { name: 'body', display: __('Warning message'), tag: 'textarea', null: false },
      { name: 'role_ids', display: __('Available for the following roles'), tag: 'column_select', multiple: true, null: false, relation: 'Role', translate: true },
      { name: 'show_tickets', display: __('Show matching ticket(s) in the warning'), tag: 'boolean', null: false, default: false },
      { name: 'permission_level', display: __('Permission level for looking up tickets'), tag: 'select', null: false, options: { user: __('User'), system: __('System') }, default: 'user', translate: true },
      { name: 'ticket_search', display: __('Match tickets in following states'), tag: 'select', null: false, options: { all: __('All tickets'), open: __('Open tickets') }, default: 'all', translate: true },
    ]

    ticket_duplicate_detection_attributes = App.Setting.get('ticket_duplicate_detection_attributes')
    @filter = new App.ControllerForm(
      el: @$('.js-attributes')
      model:
        configure_attributes: configure_attributes,
      params:
        attributes: ticket_duplicate_detection_attributes
        title: @Config.get('ticket_duplicate_detection_title')
        body: @Config.get('ticket_duplicate_detection_body')
        role_ids: @Config.get('ticket_duplicate_detection_role_ids')
        show_tickets: @Config.get('ticket_duplicate_detection_show_tickets')
        permission_level: @Config.get('ticket_duplicate_detection_permission_level')
        ticket_search: @Config.get('ticket_duplicate_detection_search')

      autofocus: false
    )

  setFilter: (e) =>
    e.preventDefault()

    # get form data
    params = @formParam(@filter.form)

    errors = @filter.validate(params)
    if !_.isEmpty(errors)
      @formValidate( form: e.target, errors: errors )
      return false

    # save settings
    App.Setting.set('ticket_duplicate_detection_attributes', params.attributes, notify: false)
    App.Setting.set('ticket_duplicate_detection_title', params.title, notify: false)
    App.Setting.set('ticket_duplicate_detection_body', params.body, notify: false)
    App.Setting.set('ticket_duplicate_detection_role_ids', params.role_ids, notify: false)
    App.Setting.set('ticket_duplicate_detection_show_tickets', params.show_tickets, notify: false)
    App.Setting.set('ticket_duplicate_detection_permission_level', params.permission_level, notify: false)
    App.Setting.set('ticket_duplicate_detection_search', params.ticket_search, notify: false)

  resetFilter: (e) ->
    e.preventDefault()

    # save filter settings
    App.Setting.set('ticket_duplicate_detection_attributes', [], notify: false)

  setTicketDuplicateDetection: (e) =>
    value = @ticketDuplicateDetection.prop('checked')
    App.Setting.set('ticket_duplicate_detection', value)
