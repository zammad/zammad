class App.TaskbarInit
  @DATA = undefined

  @set: (value) ->
    @DATA = value
    App.Collection.loadAssets(value.assets)

  @ticket: (id) ->
    return @DATA?.ticket_all?[id]

  @ticket_stats_organization: (id) ->
    return @DATA?.ticket_stats_organization?[id]

  @ticket_stats_user: (id) ->
    return @DATA?.ticket_stats_user?[id]

  @ticket_create: ->
    return @DATA?.ticket_create
