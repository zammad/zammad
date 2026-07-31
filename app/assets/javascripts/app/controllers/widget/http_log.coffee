class App.HttpLog extends App.Controller
  events:
    'click .js-relatedObject': 'openRelatedObject'
    'click .js-record':        'show'

  constructor: ->
    super
    @fetch()
    @records = []

  fetch: =>
    @ajax(
      id:   'http_logs'
      type: 'GET'
      url:  "#{@apiPath}/http_logs/#{@facility}"
      data:
        limit: @limit || 50
      processData: true
      success: (data) =>
        if !@records[0] || (data[0] && @records[0] && data[0].updated_at isnt @records[0].updated_at)
          @records = data
          @render()
        @delay(@fetch, 20000)
    )

  render: =>
    # Resolved up front rather than per row, so the view knows whether any record has a reference at
    # all: most facilities set none, and they should not get an empty column.
    relatedObjects = {}
    for record in @records
      related = @relatedObject(record)
      relatedObjects[record.id] = related if related

    @html App.view('widget/http_log')(
      records: @records
      description: @description
      relatedObjects: relatedObjects
      hasRelatedObjects: !_.isEmpty(relatedObjects)
    )

  # Names whatever caused the request, linking to its screen filtered down to that record. Works for
  # any model providing uiUrl (see App.Model), so no facility needs special casing here.
  relatedObject: (record) ->
    return if !record.related_object_type or !record.related_object_id or !record.related_object_label

    # The App namespace holds controllers next to the models, so resolving is not enough: App.HttpLog
    # for example is this controller, and instantiating it here would break the whole table.
    model = App[record.related_object_type.replace(/::/g, '')]
    return if !model or !(model.prototype instanceof App.Model)

    {
      label: record.related_object_label
      url:   @relatedObjectUrl(model, record.related_object_id)
    }

  # Nothing when the screen cannot be reached, leaving the reference named but unlinked: a model
  # without its own uiUrl would only yield a dead '#', and following a link to a screen the viewer
  # has no permission for just bounces off permissionCheckRedirect.
  relatedObjectUrl: (model, id) ->
    return if model.prototype.uiUrl is App.Model.prototype.uiUrl
    return if model.uiPermission and !App.User.current()?.permission(model.uiPermission)

    # uiUrl only needs the id, so an unsaved instance is enough and nothing has to be fetched.
    new model(id: id).uiUrl()

  # The row opens the log entry, so the reference has to keep its click to itself.
  openRelatedObject: (e) ->
    e.stopPropagation()

  show: (e) =>
    e.preventDefault()
    record_id = $(e.currentTarget).data('id')
    for record in @records
      if record_id.toString() is record.id.toString()
        new Show(
          record: record
          container: @el.closest('.content')
        )
        return

class Show extends App.ControllerModal
  authenticateRequired: true
  large: true
  head: __('HTTP Log')
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  constructor: ->
    super

  content: ->
    request_content  = App.Utils.text2html(JSON.stringify(@record.request.content, null, 2))
    response_content = App.Utils.text2html(JSON.stringify(@record.response.content, null, 2))

    # Special formatting for AI Provider + Webhook logs
    if @record?.facility and @record?.facility in ['AI::Provider', 'webhook']
      request_content  = @formatJsonData(@record.request.content)
      response_content = @formatJsonData(@record.response.content)

    App.view('widget/http_log_show')(
      record: @record
      request_content: request_content
      response_content: response_content
    )

  formatJsonData: (data) ->
    try
      [header, body] = data.split('\n\n')

      header = header?.replace(/\\n/g, '<br>')
      if !body
        return App.Utils.text2html(header).replace(/\\n/g, '<br>')

      body_json = JSON.parse(body)
      body_pretty = JSON.stringify(body_json, null, 2)
      return App.Utils.text2html(header + '\n\n' + body_pretty).replace(/\\n/g, '<br>')
    catch error
      App.Log.error 'App.HttpLog - Show', 'Invalid JSON value', error
      App.Utils.text2html(JSON.stringify(data))
