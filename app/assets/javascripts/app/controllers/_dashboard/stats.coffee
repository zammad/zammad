class App.DashboardStats extends App.Controller
  constructor: ->
    super
    @setupStatsWidgets()
    @controllerBind('dashboard_stats_rebuild', @setupStatsWidgets)

  setupStatsWidgets: =>
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

            el = @el.find(".column.#{widget.className}")
            localEl = $("<div class=\"column #{widget.className}\"></div>")

            if !el.get(0)
              @el.append(localEl)
            else
              el.replaceWith(localEl)

            new widget.controller(
              el: localEl
              className: widget.className
            )
            @$('.js-stat-help').tooltip()
          catch e
            @log 'error', "statsWidgets #{widget}:", e

    App.Event.trigger(event + ':ready')
