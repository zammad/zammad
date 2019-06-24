class App.DashboardStats extends App.Controller
  constructor: ->
    super
    @load()
    @bind('dashboard_stats_rebuild', @load)

  load: =>
    @setupStatsWidget('Stats', 'stats', @el)

  setupStatsWidget: (config, event, el) ->

    # load all statsWidgets ./stats/*
    App.Event.trigger(event + ':init')
    statsWidgets = App.Config.get(config)
    if statsWidgets
      widgets = $.map(statsWidgets, (v) -> v )
      widgets = _.sortBy(widgets, (item) -> return item.prio)

      for widget in widgets
        if @permissionCheck(widget.permission)
          try
            new widget.controller(
              el:  el
            )
            @$('.js-stat-help').tooltip()
          catch e
            @log 'error', "statsWidgets #{widget}:", e


    App.Event.trigger(event + ':ready')
