class App.OrganizationHistory extends App.GenericHistory
  constructor: ->
    super
    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'organization_history',
      type:  'GET',
      url:   @apiPath + '/organizations/history/' + @organization_id,
      success: (data, status, xhr) =>

        # load assets
        App.Collection.loadAssets( data.assets )

        @items = data.history

        # render page
        @render()
    )