class Monitoring extends App.ControllerSubContent
  requiredPermission: 'admin.monitoring'
  header: 'Monitoring'
  events:
    'click .js-resetToken': 'resetToken'
    'click .js-select': 'selectAll'
    'click .js-restartFailedJobs': 'restartFailedJobs'

  constructor: ->
    super
    @load()
    @interval(
      =>
        @load()
      35000
    )

  # fetch data, render view
  load: ->
    @startLoading()
    @ajax(
      id:    'health_check'
      type:  'GET'
      url:   "#{@apiPath}/monitoring/health_check"
      success: (data) =>
        @stopLoading()
        return if @data && data.token is @data.token && data.healthy is @data.healthy && data.message is @data.message
        @data = data
        @render()
    )

  render: =>
    @html App.view('monitoring')(data: @data)

  resetToken: (e) =>
    e.preventDefault()
    @formDisable(e)
    @ajax(
      id:    'health_check_token'
      type:  'POST'
      url:   "#{@apiPath}/monitoring/token"
      success: (data) =>
        @load()
    )

  restartFailedJobs: (e) =>
    e.preventDefault()
    @ajax(
      id:    'restart_failed_jobs_request'
      type:  'POST'
      url:   "#{@apiPath}/monitoring/restart_failed_jobs"
      success: (data) =>
        @load()
    )

App.Config.set('Monitoring', { prio: 3600, name: 'Monitoring', parent: '#system', target: '#system/monitoring', controller: Monitoring, permission: ['admin.monitoring'] }, 'NavBarAdmin')
