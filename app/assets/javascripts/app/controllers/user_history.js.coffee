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

        # load collections
        App.Event.trigger 'loadAssets', data.assets

        # render page
        @render(data.history)
    )
