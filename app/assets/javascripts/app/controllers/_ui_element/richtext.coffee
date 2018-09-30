# coffeelint: disable=camel_case_classes
class App.UiElement.richtext
  @render: (attribute, params) ->
    item = $( App.view('generic/richtext')(attribute: attribute) )
    item.find('[contenteditable]').ce(
      mode:      attribute.type
      maxlength: attribute.maxlength
    )

    if attribute.plugins
      for plugin in attribute.plugins
        params = plugin.params || {}
        params.el = item.find('[contenteditable]').parent()
        new App[plugin.controller](params)

    if attribute.upload
      @attachments = []
      item.append( $( App.view('generic/attachment')(attribute: attribute) ) )

      renderFile = (file) =>
        item.find('.attachments').append(App.view('generic/attachment_item')(file))
        @attachments.push file

      if params && params.attachments
        for file in params.attachments
          renderFile(file)

      # remove items
      item.find('.attachments').on('click', '.js-delete', (e) =>
        id = $(e.currentTarget).data('id')
        @attachments = _.filter(
          @attachments,
          (item) ->
            return if item.id.toString() is id.toString()
            item
        )

        # delete attachment from storage
        App.Ajax.request(
          type:        'DELETE'
          url:         "#{App.Config.get('api_path')}/ticket_attachment_upload"
          data:        JSON.stringify(id: id),
          processData: false
        )

        # remove attachment from dom
        element = $(e.currentTarget).closest('.attachments')
        $(e.currentTarget).closest('.attachment').remove()
        if element.find('.attachment').length == 0
          element.empty()
      )

      @progressBar           = item.find('.attachmentUpload-progressBar')
      @progressText          = item.find('.js-percentage')
      @attachmentPlaceholder = item.find('.attachmentPlaceholder')
      @attachmentUpload      = item.find('.attachmentUpload')
      @attachmentsHolder     = item.find('.attachments')
      @cancelContainer       = item.find('.js-cancel')

      u = => html5Upload.initialize(
        uploadUrl:              App.Config.get('api_path') + '/ticket_attachment_upload'
        dropContainer:          item.closest('form').get(0)
        cancelContainer:        @cancelContainer
        inputField:             item.find('input').get(0)
        maxSimultaneousUploads: 1,
        key:                    'File'
        data:
          form_id: item.closest('form').find('[name=form_id]').val()
        onFileAdded: (file) =>

          file.on(
            onStart: =>
              @attachmentPlaceholder.addClass('hide')
              @attachmentUpload.removeClass('hide')
              @cancelContainer.removeClass('hide')
              item.find('[contenteditable]').trigger('fileUploadStart')
              App.Log.debug 'UiElement.richtext', 'upload start'

            onAborted: =>
              @attachmentPlaceholder.removeClass('hide')
              @attachmentUpload.addClass('hide')
              item.find('input').val('')
              item.find('[contenteditable]').trigger('fileUploadStop', ['aborted'])

            # Called after received response from the server
            onCompleted: (response) =>
              response = JSON.parse(response)

              @attachmentPlaceholder.removeClass('hide')
              @attachmentUpload.addClass('hide')

              # reset progress bar
              @progressBar.width(parseInt(0) + '%')
              @progressText.text('')

              renderFile(response.data)
              item.find('input').val('')
              item.find('[contenteditable]').trigger('fileUploadStop', ['completed'])
              App.Log.debug 'UiElement.richtext', 'upload complete', response.data

            # Called during upload progress, first parameter
            # is decimal value from 0 to 100.
            onProgress: (progress, fileSize, uploadedBytes) =>
              @progressBar.width(parseInt(progress) + '%')
              @progressText.text(parseInt(progress))
              # hide cancel on 90%
              if parseInt(progress) >= 90
                @cancelContainer.addClass('hide')
              App.Log.debug 'UiElement.richtext', 'uploadProgress ', parseInt(progress)

          )
      )
      App.Delay.set(u, 100, undefined, 'form_upload')

    item
