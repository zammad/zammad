class App.WidgetPayloadExample extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: false
  head: __('Example Payload')
  large: true

  content: =>
    if !@payloadExample
      @load()
      return

    @payloadExample

  load: =>
    @ajax(
      id:          'example_payload'
      type:        'get'
      url:         @baseUrl
      processData: false
      contentType: 'text/plain'
      dataType:    'text'
      cache:       false
      success:     (data, status, xhr) =>
        @payloadExample = $(App.view('widget/payload_example')(
          payload: data
        ))

        @update()
      error: (data) =>
        details = data.responseJSON || {}
        @notify
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || __('Loading failed.'))
          timeout: 6000
    )
