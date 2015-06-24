class App.DashboardActivityStream extends App.Controller
  constructor: ->
    super

    @fetch()

    # bind to rebuild view event
    @bind( 'activity_stream_rebuild', @load )

  fetch: =>

    # use cache of first page
    cache = App.Store.get( 'activity_stream' )
    if cache
      @load( cache )

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
          App.Store.write( 'activity_stream', data )
          @load(data)
      )

  load: (data) =>
    items = data.activity_stream

    # load assets
    App.Collection.loadAssets( data.assets )

    @render(items)

  render: (items) ->
    if _.isEmpty(items)
      @$('.activity-description').removeClass('hidden')
      return

    items = @prepareForObjectList(items)

    html = $('<div class="activity-entries"></div>')
    for item in items
      html.append( @renderItem(item) )

    @$('.activity-entries').remove()
    @el.append html

    # update time
    @frontendTimeUpdate()

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