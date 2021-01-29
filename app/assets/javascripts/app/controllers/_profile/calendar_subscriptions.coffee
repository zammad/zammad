class ProfileCalendarSubscriptions extends App.ControllerSubContent
  requiredPermission: 'user_preferences.calendar+ticket.agent'
  header: 'Calendar'
  elements:
    'input[type=checkbox]': 'options'
    'output': 'output'

  events:
    'change input[type=checkbox]': 'onOptionsChange'
    'click .js-select': 'selectAll'
    'click .js-showLink': 'showLink'

  constructor: ->
    super

    @translationTable =
      new_open: App.i18n.translatePlain('new & open')
      pending: App.i18n.translatePlain('pending')
      escalation: App.i18n.translatePlain('escalation')

    @render()

  render: =>
    userPreferences = @Session.get('preferences')
    @preferences    = App.Config.get('defaults_calendar_subscriptions_tickets')

    if userPreferences.calendar_subscriptions
      if userPreferences.calendar_subscriptions.tickets
        _.extend(@preferences, userPreferences.calendar_subscriptions.tickets)

    @html App.view('profile/calendar_subscriptions')
      baseurl: window.location.origin
      preferences: @preferences
      translationTable: @translationTable

  showLink: (e) ->
    $(e.currentTarget).next().removeClass('is-hidden')
    $(e.currentTarget).remove()

  onOptionsChange: =>
    @setAllPreferencesToFalse()

    for i, checkbox of @options.serializeArray()
      [state, option] = checkbox.name.split('/')
      if state && option
        @preferences[state][option] = true
      else
        @preferences[checkbox.name] = true

    @store()

  setAllPreferencesToFalse: ->
    @preferences.alarm = false
    for state of @preferences
      if _.isObject(@preferences)
        @preferences[state].own = false
        @preferences[state].not_assigned = false

  store: ->
    # get data
    data =
      calendar_subscriptions:
        tickets: @preferences

    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify data
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    App.User.full(
      App.Session.get('id')
      =>
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent('Successful!')
        )
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set('CalendarSubscriptions', { prio: 3000, name: 'Calendar', parent: '#profile', target: '#profile/calendar_subscriptions', permission: ['user_preferences.calendar+ticket.agent'], controller: ProfileCalendarSubscriptions }, 'NavBarProfile')
