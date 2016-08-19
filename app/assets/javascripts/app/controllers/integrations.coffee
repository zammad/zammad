class Index extends App.ControllerContent
  requiredPermission: 'admin.integration'
  constructor: ->
    super

    @title 'Integrations', true

    @integrationItems = App.Config.get('NavBarIntegrations')

    if !@integration
      @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)
      return

    for key, value of @integrationItems
      if value.target is "#system/#{@target}/#{@integration}"
        config = value
        break

    new config.controller(
      el: @el.closest('.main')
    )

  render: =>
    integrations = []
    for key, value of @integrationItems
      value.key = key
      integrations.push value
    integrations = _.sortBy(integrations, (item) -> return item.name)

    @html App.view('integration/index')(
      head:         'Integrations'
      integrations: integrations
    )

  release: =>
    if @subscribeId
      App.Setting.unsubscribe(@subscribeId)

App.Config.set('Integration', { prio: 1000, name: 'Integrations', parent: '#system', target: '#system/integration', controller: Index, permission: ['admin.integration'] }, 'NavBarAdmin')
