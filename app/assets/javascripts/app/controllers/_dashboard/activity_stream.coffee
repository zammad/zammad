class App.DashboardActivityStream extends App.Controller
  constructor: ->
    super

    @fetch()

    # bind to rebuild view event
    @bind('activity_stream_rebuild', @load)

  fetch: =>

    # use cache of first page
    cache = App.SessionStorage.get('activity_stream')
    if cache
      @load(cache)

    # init fetch via ajax, all other updates on time via websockets
    else
      @ajax(
        id:    'dashoard_activity_stream'
        type:  'GET'
        url:   @apiPath + '/activity_stream'
        data:  {
          limit: @limit || 8
        }
        processData: true
        success: (data) =>
          @load(data)
      )

  load: (data) =>

    App.SessionStorage.set('activity_stream', data)

    items = data.activity_stream

    App.Collection.loadAssets(data.assets)

    @render(items)

  render: (items) ->

    # show description of activity stream
    return if _.isEmpty(items)

    # remove description of activity stream
    @$('.activity-description').removeClass('activity-description')

    items = @prepareForObjectList(items)

    html = $('<div class="activity-entries"></div>')
    for item in items
      html.append(@renderItem(item))

    @el.html html

  renderItem: (item) ->
    html = $(App.view('dashboard/activity_stream')(
      item: item
    ))
    new App.WidgetAvatar(
      el:       html.find('.js-avatar')
      user_id:  item.created_by_id
      size:     40
    )
    html