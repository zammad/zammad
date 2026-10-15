# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shows the clues on the page agents land on after login: the dashboard,
#   or the overviews while the dashboard is turned off.
#
# Relies on @shown and @appEl instance variables
App.CluesShowable =
  clueAccess: true

  mayBeClues: ->
    return if @Config.get('after_auth')
    return if !@clueAccess
    return if !@shown
    return if !@permissionCheck('ticket.agent')
    return if @Config.get('switch_back_to_possible')
    preferences = @Session.get('preferences')
    @clueAccess = false

    # If the initial clue has been already completed by the user, show the rest of the clues.
    if preferences['intro']
      for clue in _.sortBy(App.Config.get('Clues'), 'prio')
        continue if preferences[clue.preference_key] # skip already completed clues
        continue if clue.config_key and not App.Config.get(clue.config_key) # skip clues about inactive features
        continue if clue.permission and not _.every(clue.permission, (permission) -> App.User.current()?.permission(permission)) # skip clues without required permissions

        new clue.controller(
          appEl: @appEl
          onComplete: =>
            App.Ajax.request(
              id:          'preferences'
              type:        'PUT'
              url:         "#{@apiPath}/users/preferences"
              data:        JSON.stringify("#{clue.preference_key}": true)
              processData: true
            )
        )

        return # show only one clue at a time

      return

    @clues()

  clues: (e) ->
    @clueAccess = false
    if e
      e.preventDefault()

    # Initial clue has its own controller, so it can be triggered via a route change later.
    @navigate '#clues'
