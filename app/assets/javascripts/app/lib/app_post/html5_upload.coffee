class App.Html5Upload extends App.Controller
  uploadUrl:              null
  maxSimultaneousUploads: 1
  key:                    'File'
  data:                   null

  onFileStartCallback:     null
  onFileCompletedCallback: null
  onFileAbortedCallback:   null
  onFileErrorCallback:     null

  dropContainer:         null
  cancelContainer:       null
  inputField:            null
  attachmentPlaceholder: null
  attachmentUpload:      null
  progressBar:           null
  progressText:          null

  render: =>
    html5Upload.initialize(
      uploadUrl:              @uploadUrl
      dropContainer:          @dropContainer.get(0)
      cancelContainer:        @cancelContainer
      inputField:             @inputField.get(0)
      maxSimultaneousUploads: @maxSimultaneousUploads
      key:                    @key
      data:                   @data
      onFileAdded:            @onFileAdded
      canUploadFiles:         @canUploadFiles
    )
    @inputField.attr('data-initialized', true)

  onFileAdded: (file) =>
    file.on(
      onStart:     @onFileStart
      onAborted:   @onFileAborted
      onCompleted: @onFileCompleted
      onProgress:  @onFileProgress
      onError:     @onFileError
    )

  onFileStart: =>
    @attachmentPlaceholder.addClass('hide')
    @attachmentUpload.removeClass('hide')
    @cancelContainer.removeClass('hide')

    App.Log.debug 'Html5Upload', 'upload start'
    @onFileStartCallback?()

  onFileProgress: (progress, fileSize, uploadedBytes) =>
    progress = parseInt(progress)

    @progressBar.width(progress + '%')
    @progressText.text(progress)
    # hide cancel on 90%
    if progress >= 90
      @cancelContainer.addClass('hide')

    App.Log.debug 'Html5Upload', 'uploadProgress ', progress


  onFileCompleted: (response) =>
    response = JSON.parse(response)

    @hideFileUploading()
    @onFileCompletedCallback?(response)

    App.Log.debug 'Html5Upload', 'upload complete', response.data

  onFileAborted: =>
    @hideFileUploading()
    @onFileAbortedCallback?()

    App.Log.debug 'Html5Upload', 'upload aborted'

  onFileError: (message) =>
    @hideFileUploading()
    @inputField.val('')

    if message
      try
        message = JSON.parse(message)
      catch
        message = {}

    @onFileErrorCallback?()

    @notify
      type: 'error'
      msg:  message['error_human'] || message['error'] || __('The file could not be uploaded.')

    App.Log.debug 'Html5Upload', 'upload error'

  hideFileUploading: =>
    @attachmentPlaceholder.removeClass('hide')
    @attachmentUpload.addClass('hide')

    @progressBar.width('0%')
    @progressText.text('0')
