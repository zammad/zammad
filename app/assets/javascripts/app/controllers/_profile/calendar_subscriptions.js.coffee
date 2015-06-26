class CalendarSubscriptions extends App.Controller
  elements:
    'input[type=checkbox]': 'options'
    'output': 'output'

  events:
    'change input[type=checkbox]': 'onOptionsChange'
    'click .js-select': 'selectAll'
    'click .js-showLink': 'showLink'

  constructor: ->
    super
    return if !@authenticate()

    @translationTable =
      new_open: App.i18n.translatePlain('new & open')
      pending: App.i18n.translatePlain('pending')
      escalation: App.i18n.translatePlain('escalation')

    @render()

  render: =>
    userPreferences = @Session.get('preferences')
    @preferences =
      new_open:
        own: true
        not_assigned: false
      pending:
        own: true
        not_assigned: false
      escalation:
        own: true
        not_assigned: false

    if userPreferences.ical
      if userPreferences.ical.ticket
        _.extend(@preferences, userPreferences.ical.ticket)

    @html App.view('profile/calendar_subscriptions')
      baseurl: window.location.origin
      preferences: @preferences
      translationTable: @translationTable

  showLink: (e) ->
    $(e.currentTarget).next().removeClass('is-hidden')
    $(e.currentTarget).remove()

  selectAll: (e) ->
    e.currentTarget.focus()
    e.currentTarget.select()

  onOptionsChange: =>
    @setAllPreferencesToFalse()

    for i, checkbox of @options.serializeArray()
      [state, option] = checkbox.name.split('/')
      @preferences[state][option] = true

    @store()

  setAllPreferencesToFalse: ->
    for state of @preferences
      @preferences[state].own = false
      @preferences[state].not_assigned = false

  store: ->
    # get data
    data =
      user:
        ical:
          ticket: @preferences

    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         @apiPath + '/users/preferences'
      data:        JSON.stringify data
      success:     @success
      error:       @error
    )

  success: (data, status, xhr) =>
    App.User.full(
      App.Session.get( 'id' ),
      =>
        App.i18n.set( @locale )
        App.Event.trigger( 'ui:rerender' )
        @notify(
          type: 'success'
          msg:  App.i18n.translateContent( 'Successfully!' )
        )
      ,
      true
    )

  error: (xhr, status, error) =>
    @render()
    data = JSON.parse( xhr.responseText )
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent( data.message )
    )

App.Config.set( 'CalendarSubscriptions', { prio: 4000, name: 'Calendar Subscriptions', parent: '#profile', target: '#profile/calendar_subscriptions', controller: CalendarSubscriptions }, 'NavBarProfile' )