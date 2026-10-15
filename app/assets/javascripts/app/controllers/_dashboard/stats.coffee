class App.DashboardStats extends App.Controller
  @settingName: (widget) ->
    "dashboard_stats_#{widget.className}"

  # Widgets without such a setting, e.g. from an addon, stay visible.
  @isVisible: (widget) ->
    App.Config.get(App.DashboardStats.settingName(widget)) isnt false

  @anyVisible: ->
    _.some(App.Config.get('Stats'), @isVisible)

  @anyVisibleToCurrentUser: ->
    _.some(App.Config.get('Stats'), (widget) => @isVisible(widget) and App.User.current()?.permission(widget.permission))

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
        continue if !App.DashboardStats.isVisible(widget)

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
              widget: widget
            )
            @$('.js-stat-help').tooltip()
          catch e
            @log 'error', "statsWidgets #{widget}:", e

    App.Event.trigger(event + ':ready')
