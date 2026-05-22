# Faithful Agent Dashboard — matches docs/ui-references/agent-console/.
# Replaces the legacy App.Dashboard for users with ticket.agent permission.
# Dispatched from the shared DashboardRouter in dashboard.coffee.
class App.AgentDashboardFaithful extends App.ControllerAppContent
  @requiredPermission: 'ticket.agent'

  constructor: ->
    super
    @title __('Dashboard'), true
    @navupdate '#dashboard'

    @slaAtRisk     = []
    @workload      = []
    @myOpenCount   = 0
    @unassignedCount = 0

    @fetchSla()
    @fetchWorkload()
    @fetchOverviewCounts()

    @render()

  release: =>
    super

  fetchSla: =>
    @ajax(
      id:    'agent_dashboard_sla'
      type:  'GET'
      url:   "#{@apiPath}/agent_dashboard/sla_at_risk?within_hours=24"
      processData: true
      success: (data) =>
        @slaAtRisk = data
        @render()
    )

  fetchWorkload: =>
    @ajax(
      id:    'agent_dashboard_workload'
      type:  'GET'
      url:   "#{@apiPath}/agent_dashboard/workload"
      processData: true
      success: (data) =>
        @workload = data
        @render()
    )

  fetchOverviewCounts: =>
    # Use the same OverviewIndexCollection the regular overview navbar
    # uses — its 'count' field is what the wireframe displays.
    handle = (overviews) =>
      return if !overviews
      mine  = _.find(overviews, (o) -> o.link is 'my_assigned')
      unass = _.find(overviews, (o) -> o.link is 'unassigned_open')
      @myOpenCount     = mine?.count or 0
      @unassignedCount = unass?.count or 0
      @render()

    @overviewBindId = App.OverviewIndexCollection.bind(handle, false)
    handle(App.OverviewIndexCollection.get())

  greetingFor: ->
    hour = new Date().getHours()
    salute =
      if hour < 12 then __('Good morning')
      else if hour < 18 then __('Good afternoon')
      else __('Good evening')
    user = App.User.current()
    name = user?.firstname or user?.login or ''
    if name then "#{salute}, #{name}" else salute

  relTime: (iso) ->
    return '' if !iso
    diff = new Date(iso).getTime() - Date.now()
    abs = Math.abs(diff)
    minute = 60 * 1000
    hour = 60 * minute
    day = 24 * hour
    sign = if diff >= 0 then '' else '−'
    if abs < minute then "now"
    else if abs < hour then "#{sign}#{Math.round(abs / minute)}m"
    else if abs < day then "#{sign}#{Math.round(abs / hour)}h"
    else "#{sign}#{Math.round(abs / day)}d"

  slaUrgency: (iso) ->
    return null if !iso
    diff = new Date(iso).getTime() - Date.now()
    minute = 60 * 1000
    hour = 60 * minute
    if diff < 0 then 'breach'
    else if diff < 30 * minute then 'breach'
    else if diff < 2 * hour then 'soon'
    else null

  render: =>
    @html App.view('agent_dashboard_faithful')(
      greeting:        @greetingFor()
      myOpen:          @myOpenCount
      unassigned:      @unassignedCount
      slaAtRisk:       @slaAtRisk
      workload:        @workload
      relTime:         (iso) => @relTime(iso)
      slaUrgency:      (iso) => @slaUrgency(iso)
    )

App.Config.set('AgentDashboardFaithful', { controller: 'AgentDashboardFaithful', permission: ['ticket.agent'] }, 'permanentTask')
