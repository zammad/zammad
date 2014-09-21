class App.UserHistory extends App.GenericHistory
  constructor: ->
    super
    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:    'user_history',
      type:  'GET',
      url:   @apiPath + '/users/history/' + @user_id,
      success: (data, status, xhr) =>

        # load assets
        App.Collection.loadAssets( data.assets )

        @items = data.history

        # render page
        @render()
    )
