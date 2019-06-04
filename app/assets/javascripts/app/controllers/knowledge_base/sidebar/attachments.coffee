class App.KnowledgeBaseSidebarAttachments extends App.Controller
  className: 'sidebar-block'

  events:
    'click .js-delete':          'delete'
    'html5Upload.dropZone.show': 'showDropZone'
    'html5Upload.dropZone.hide': 'hideDropZone'

  elements:
    '.attachmentUpload-progressBar': 'progressBar'
    '.js-percentage':                'progressText'
    '.attachmentPlaceholder':        'attachmentPlaceholder'
    '.attachmentUpload':             'attachmentUpload'
    '.js-cancel':                    'cancelContainer'
    'input':                         'input'
    '.dropContainer':                'dropContainer'

  constructor: ->
    super

    @render()
    @listenTo @object, 'refresh', @needsUpdate

  needsUpdate: =>
    @render()

  render: ->
    @html App.view('knowledge_base/sidebar/attachments')(
      attachments: @object.attachments
    )

    html5Upload.initialize(
      uploadUrl:              @object.generateURL('attachments')
      dropContainer:          @el.get(0)
      cancelContainer:        @cancelContainer
      inputField:             @input.get(0)
      maxSimultaneousUploads: 1,
      key:                    'file'
      onFileAdded:            @onFileAdded
    )

  delete: (e) =>
    e.preventDefault()
    id = parseInt($(e.currentTarget).attr('data-object-id'))
    attachment = @object.attachments.filter((elem) -> elem.id == id)[0]

    new DeleteConfirm(
      container:        @container
      answer:           @object
      attachment:       attachment
      parentController: @
    )

  fetch: =>
    @ajax(
      id:   "attachments_#{@object.id}_knowledge_base_answer"
      type: 'GET'
      url: @object.generateURL() + '?full=true'
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @render()
    )

  onFileAdded: (file) =>
    file.on(
      onStart:     @onStart
      onAborted:   @onAborted
      onCompleted: @onCompleted
      onProgress:  @onProgress
    )

  onStart: =>
    @attachmentPlaceholder.addClass('hide')
    @attachmentUpload.removeClass('hide')
    @cancelContainer.removeClass('hide')

  onAborted: =>
    @attachmentPlaceholder.removeClass('hide')
    @attachmentUpload.addClass('hide')
    @input.val('')

  onCompleted: (response) =>
    @attachmentPlaceholder.removeClass('hide')
    @attachmentUpload.addClass('hide')

    @progressBar.width(parseInt(0) + '%')
    @progressText.text('')

    @input.val('')

    data = JSON.parse(response)
    App.Collection.loadAssets(data)

  onProgress: (progress, fileSize, uploadedBytes) =>
    @progressBar.width(parseInt(progress) + '%')
    @progressText.text(parseInt(progress))
    # hide cancel on 90%
    if parseInt(progress) >= 90
      @cancelContainer.addClass('hide')

  showDropZone: ->
    if @dropContainer.hasClass('is-dropTarget')
      return

    @dropContainer.addClass('is-dropTarget')

  hideDropZone: ->
    @dropContainer.removeClass('is-dropTarget')

class DeleteConfirm extends App.ControllerConfirm
  content: ->
    sentence = App.i18n.translateContent('Are you sure to delete')
    "#{sentence} #{@attachment.filename}?"
  buttonSubmit: 'delete'
  onSubmit: ->
    @formDisable(@el)

    @ajax(
      id:   'attachment_delete'
      type: 'DELETE'
      url:  @answer.generateURL("attachments/#{@attachment.id}")
      processData: true
      success: @success
      error: @error
    )

  success: (data, status, xhr) =>
    @close()
    App.Collection.loadAssets(data)
    @parentController.render()

  error: (xhr) =>
    @formEnable(@el)
    @showAlert(xhr.responseJSON?.error || 'Unable to save changes')
