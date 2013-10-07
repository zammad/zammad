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

    # load collections
    App.Event.trigger 'loadAssets', data.assets

    @render(items)

  render: (items) ->

    for item in items

      item.link  = ''
      item.title = '???'

      # convert backend name space to local name space
      item.object = item.object.replace("::", '')

      if App[item.object]
        object      = App[item.object].find( item.o_id )
        item.link   = object.uiUrl()
        item.title  = object.displayName()
        item.object = object.objectDisplayName()

      item.created_by = App.User.find( item.created_by_id )

    html = App.view('dashboard/activity_stream')(
      head: 'Activity Stream',
      items: items
    )
    html = $(html)

    @html html

    # start user popups
    @userPopups('right')

    # update time
    @frontendTimeUpdate()
