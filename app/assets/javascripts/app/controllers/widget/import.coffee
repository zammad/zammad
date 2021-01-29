class App.Import extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Import'
  autoFocusOnFirstInput: false
  head: 'Import'
  large: true
  templateDirectory: 'generic/object_import'
  baseUrl: '/api/v1/text_modules'

  content: =>

    # show start dialog
    content = $(App.view("#{@templateDirectory}/index")(
      head: 'Import'
      import_example_url: "#{@baseUrl}/import_example"
      deleteOption: @deleteOption
    ))

    # check if data is processing...
    if @data
      result = App.view("#{@templateDirectory}/result")(
        @data
      )
      content.find('.js-error').html(result)
      if result
        content.find('.js-error').removeClass('hide')
      else
        content.find('.js-error').addClass('hide')
    content

  onSubmit: (e) =>
    params = new FormData($(e.currentTarget).closest('form').get(0))
    params.set('try', true)
    if _.isEmpty(params.get('data'))
      params.delete('data')
    @formDisable(e)
    @ajax(
      id:          'csv_import'
      type:        'POST'
      url:         "#{@baseUrl}/import"
      processData: false
      contentType: false
      cache:       false
      data:        params
      success:     (data, status, xhr) =>
        if data.result is 'success'
          new App.ImportTryResult(
            container: @el.closest('.content')
            result: data
            params: params
            templateDirectory: @templateDirectory
            baseUrl: @baseUrl
          )
          @close()
          return
        @data = data
        @update()
        @formEnable(e)
      error: (data) =>
        details = data.responseJSON || {}
        @notify
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to import!')
          timeout: 6000
        @formEnable(e)
    )
