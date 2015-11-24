class App.OrganizationHistory extends App.GenericHistory
  fetch: =>
    @ajax(
      id:    'organization_history'
      type:  'GET'
      url:   "#{@apiPath}/organizations/history/#{@organization_id}"
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @items = data.history
        @render()
    )
