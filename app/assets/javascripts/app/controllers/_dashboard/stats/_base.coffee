class App.ControllerDashboardStatsBase extends App.Controller
  constructor: (params) ->
    if params.parentEl
      el = params.parentEl.find(".column.#{params.className}")
      if !el.get(0)
        el = $("<div class=\"column #{params.className}\"></div>")
        params.parentEl.append(el)
      params.el = el
    super(params)
    @load()

  load: =>
    stats_store = App.StatsStore.first()
    if stats_store
      @render(stats_store.data)
    else
      @render()
