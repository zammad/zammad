# coffeelint: disable=camel_case_classes
class App.UiElement.richtext
  @render: (attribute, params, form) ->
    if _.isObject(attribute.value)
      attribute.attachments = attribute.value.attachments
      attribute.value = attribute.value.text

    item = $( App.view('generic/richtext')(attribute: attribute, toolButtons: @toolButtons) )
    @contenteditable = item.find('[contenteditable]').ce(
      mode:      attribute.type
      maxlength: attribute.maxlength
      buttons:   attribute.buttons
    )

    item.find('a.btn--action[data-action]').click (event) => @toolButtonClicked(event, form)

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

      if attribute.attachments
        for file in attribute.attachments
          renderFile(file)

      App.Event.bind('ui::ticket::addArticleAttachent', (data) ->
        form_id = item.closest('form').find('[name=form_id]').val()

        return if data.form_id isnt form_id
        return if _.isEmpty(data.attachments)
        for file in data.attachments
          renderFile(file)
      , form.form_id)

      # remove items
      item.find('.attachments').on('click', '.js-delete', (e) =>
        id = $(e.currentTarget).data('id')
        @attachments = _.filter(
          @attachments,
          (item) ->
            return if item.id.toString() is id.toString()
            item
        )

        form_id = item.closest('form').find('[name=form_id]').val()

        # delete attachment from storage
        App.Ajax.request(
          type:        'DELETE'
          url:         "#{App.Config.get('api_path')}/upload_caches/#{form_id}/items/#{id}"
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
        uploadUrl:              "#{App.Config.get('api_path')}/attachments"
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

  @toolButtonClicked: (event, form) ->
    action = $(event.currentTarget).data('action')
    @toolButtons[action]?.onClick(event, form)

  @toolButtons = {}
  @additions   = {}

  # 1 next, -1 previous
  # jQuery's helper doesn't work because it doesn't include non-element nodes
  @allDirectionalSiblings: (elem, direction, to = null) ->
    if !elem?
      return []

    output = []
    next = elem

    while sibling = App.UiElement.richtext.directionalSibling(next, direction)
      next = sibling
      if to? and sibling is to
        break

      output.push sibling

    output

  # 1 next, -1 previous
  @directionalSibling: (elem, direction) ->
    if direction > 0
      elem.nextSibling
    else
      elem.previousSibling

  @buildParentsList: (elem, container) ->
    $(elem)
      .parentsUntil(container)
      .toArray()

  @buildParentsListWithSelf: (elem, container) ->
    output = App.UiElement.richtext.buildParentsList(elem, container)
    output.unshift(elem)
    output
