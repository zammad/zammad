class App.UserHistory extends App.GenericHistory
  fetch: =>
    @ajax(
      id:    'user_history'
      type:  'GET'
      url:   "#{@apiPath}/users/history/#{@user_id}"
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @items = data.history
        @render()
    )
