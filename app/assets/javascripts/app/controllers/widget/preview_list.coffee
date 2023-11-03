class App.PreviewList extends App.Controller
  orderBy: null
  orderDirection: null

  constructor: ->
    super
    @render()

  show: =>
    if @table
      @table.show()

  hide: =>
    if @table
      @table.hide()

  render: =>

    openObject = (id, e) =>
      @navigate App[@object_name].findNative(id)?.uiUrl()

    callbackLinkToObject = (value, object, attribute, attributes) ->
      attribute.link = object.uiUrl()
      value

    # callbackHeader = [ ]
    callbackAttributes =
      login:
        [ callbackLinkToObject ]
      name:
        [ callbackLinkToObject ]

    list = []
    for object_id in @object_ids
      list.push App[@object_name].fullLocal(object_id)
    @el.html('')
    @table = new App.ControllerTable(
      tableId:  @tableId
      el:       @el
      overview: App[@object_name].configure_preview
      model:    App[@object_name]
      objects:  list
      checkbox: @checkbox
      #bindRow:
      #  events:
      #    'click': openTicket
      orderBy:        @orderBy
      orderDirection: @orderDirection
      # callbackHeader: callbackHeader
      callbackAttributes: callbackAttributes
      bindCheckbox: @bindCheckbox
      radio: @radio
      sortClickCallback: @sortClickCallback
      clone: false
    )
