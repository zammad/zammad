class Index extends App.Controller
  elements:
    '.js-upload':      'fileInput'
    '.avatar-gallery': 'avatarGallery'

  events:
    'click .js-openCamera': 'openCamera'
    'change .js-upload':    'onUpload'
    'click .avatar':        'onSelect'
    'click .avatar-delete': 'onDelete'

  constructor: ->
    super
    return if !@authenticate()
    @avatars = []
    @loadAvatarList()

  loadAvatarList: =>
    @ajax(
      id:   'avatar_list'
      type: 'GET'
      url:  @apiPath + '/users/avatar'
      processData: true
      success: (data, status, xhr) =>
        @avatars = data.avatars
        @render()
    )

  # check if the browser supports webcam access
  # doesnt render the camera button if not
  hasGetUserMedia: ->
    return !!(navigator.getUserMedia || navigator.webkitGetUserMedia ||
            navigator.mozGetUserMedia || navigator.msGetUserMedia)

  render: =>
    @html App.view('profile/avatar')
      webcamSupport: @hasGetUserMedia()
      avatars:       @avatars
    @$('.avatar[data-id="' + @Session.get('id') + '"]').attr('data-id', '').attr('data-avatar-id', '0')

  onSelect: (e) =>
    @pick( $(e.currentTarget) )

  onDelete: (e) =>
    e.stopPropagation()
    if confirm App.i18n.translateInline('Delete Avatar?')

      params =
        id: $(e.currentTarget).parent('.avatar-holder').find('.avatar').data('avatar-id')

      $(e.currentTarget).parent('.avatar-holder').remove()
      @pick @$('.avatar').last()

      # remove avatar globally
      @ajax(
        id:   'avatar_delete'
        type: 'DELETE'
        url:  @apiPath + '/users/avatar'
        data: JSON.stringify( params )
        processData: true
        success: (data, status, xhr) =>
    )

  pick: (avatar) =>
    @$('.avatar').removeClass('is-active')
    avatar.addClass('is-active')
    avatar_id = avatar.data('avatar-id')
    params    =
      id: avatar_id

    # update avatar globally
    @ajax(
      id:   'avatar_set_default'
      type: 'POST'
      url:  @apiPath + '/users/avatar/set'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>

        # update avatar in app at runtime
        activeAvatar = @$('.avatar.is-active')
        style = activeAvatar.attr('style')

        # set correct background size
        if activeAvatar.text()
          style += ';background-size:auto'
        else
          style += ';background-size:cover'

        # find old avatars and update them
        replaceAvatar = $('.avatar[data-id="' + @Session.get('id') + '"]')
        replaceAvatar.attr('style', style)

        # update avatar text if needed
        if activeAvatar.text()
          replaceAvatar.text(activeAvatar.text())
          replaceAvatar.addClass('unique')
        else
          replaceAvatar.text( '' )
          replaceAvatar.removeClass('unique')
    )
    avatar

  openCamera: =>
    new Camera
      callback: @storeImage

  storeImage: (src) =>

    # store avatar globally
    params =
      avatar_full: src

    # add resized image
    avatar = new App.ImageService( src )
    params['avatar_resize'] = avatar.toDataURLForAvatar( 'auto', 160 )

    # store on server site
    @ajax(
      id:   'avatar_new'
      type: 'POST'
      url:  @apiPath + '/users/avatar'
      data: JSON.stringify( params )
      processData: true
      success: (data, status, xhr) =>
        avatarHolder = $(App.view('profile/avatar-holder')( src: src, avatar: data.avatar ) )
        @avatarGallery.append(avatarHolder)
        @pick avatarHolder.find('.avatar')
    )

  onUpload: (event) =>
    callback = @storeImage
    EXIF.getData event.target.files[0], ->
      orientation   = this.exifdata.Orientation
      reader        = new FileReader()
      reader.onload = (e) =>
        new ImageCropper
          imageSource: e.target.result
          callback:    callback
          orientation: orientation

      reader.readAsDataURL(this)

App.Config.set( 'Avatar', { prio: 1100, name: 'Avatar', parent: '#profile', target: '#profile/avatar', controller: Index }, 'NavBarProfile' )


class ImageCropper extends App.ControllerModal
  elements:
    '.imageCropper-image': 'image'

  constructor: (options) ->
    super
    @head        = 'Crop Image'
    @cancel      = true
    @button      = 'Save'
    @buttonClass = 'btn--success'

    @show( App.view('profile/imageCropper')() )

    @size = 256

    orientationTransform =
      1: 0
      3: 180
      6: 90
      8: -90

    @angle = orientationTransform[ @options.orientation ]

    if @angle != 0
      @isOrientating = true
      image = new Image()
      image.addEventListener 'load', @orientateImage
      image.src = @options.imageSource
    else
      @image.attr src: @options.imageSource

  orientateImage: (e) =>
    image  = e.currentTarget
    canvas = document.createElement('canvas')
    ctx    = canvas.getContext('2d')

    # fit image into options.max bounding box
    # if image.width > @options.max
    #   image.height = @options.max * image.height/image.width
    #   image.width = @options.max
    # else if image.height > @options.max
    #   image.width = @options.max * image.width/image.height
    #   image.height = @options.max

    if @angle is 180
      canvas.width  = image.width
      canvas.height = image.height
    else
      canvas.width  = image.height
      canvas.height = image.width

    ctx.translate(canvas.width/2, canvas.height/2)
    ctx.rotate(@angle * Math.PI/180)
    ctx.drawImage(image, -image.width/2, -image.height/2, image.width, image.height)

    @image.attr src: canvas.toDataURL()
    @isOrientating = false
    @initializeCropper() if @isShown

  onShown: =>
    @isShown = true
    @initializeCropper() if not @isOrientating

  initializeCropper: =>
    @image.cropper
      aspectRatio: 1,
      dashed: false,
      preview: ".imageCropper-preview"

  onSubmit: (e) =>
    e.preventDefault()
    @options.callback( @image.cropper("getDataURL") )
    @image.cropper("destroy")
    @hide()


class Camera extends App.ControllerModal
  elements:
    '.js-shoot':       'shootButton'
    '.js-submit':      'submitButton'
    '.camera-preview': 'preview'
    '.camera':         'camera'
    'video':           'video'

  events:
    'click .js-shoot:not(.is-disabled)': 'onShootClick'

  constructor: (options) ->
    super
    @size            = 256
    @photoTaken      = false
    @backgroundColor = 'white'

    @head          = 'Camera'
    @cancel        = true
    @button        = 'Save'
    @buttonClass   = 'btn--success is-disabled'
    @centerButtons = [{
      className: 'btn--success js-shoot',
      text: 'Shoot'
    }]

    @show( App.view('profile/camera')() )

    @ctx = @preview.get(0).getContext('2d')

    requestWebcam = Modernizr.prefixed('getUserMedia', navigator)
    requestWebcam({video: true}, @onWebcamReady, @onWebcamError)

    @initializeCache()

  onShootClick: =>
    if @photoTaken
      @photoTaken = false
      @countdown  = 0
      @submitButton.addClass('is-disabled')
      @shootButton
        .removeClass('btn--danger')
        .addClass('btn--success')
        .text( App.i18n.translateInline('Shoot') )
      @updatePreview()
    else
      @shoot()
      @shootButton
        .removeClass('btn--success')
        .addClass('btn--danger')
        .text( App.i18n.translateInline('Discard') )

  shoot: =>
    @photoTaken = true
    @submitButton.removeClass('is-disabled')

  onWebcamReady: (stream) =>
    # in case the modal is closed before the
    # request was fullfilled
    if @hidden
      @stream.stop()
      return

    # cache stream so that we can later turn it off
    @stream = stream

    @video.attr 'src', window.URL.createObjectURL(stream)

    # setup the offset to center the webcam image perfectly
    # when the stream is ready
    @video.on('canplay', @setupPreview)

    # start to update the preview once its playing
    @video.on('play', @updatePreview)

    # start the stream
    @video.get(0).play()

  onWebcamError: (error) =>
    # in case the modal is closed before the
    # request was fullfilled
    if @hidden
      return

    convertToHumanReadable =
      'PermissionDeniedError':       App.i18n.translateInline('You have to allow access to your webcam.')
      'ConstraintNotSatisfiedError': App.i18n.translateInline('No camera found.')

    alert convertToHumanReadable[error.name]
    @hide()

  setupPreview: =>
    @video.attr 'height', @size
    @preview.attr
      width: @size
      height: @size
    @offsetX = (@video.width() - @size)/2
    @centerX = @size/2
    @centerY = @size/2

  updatePreview: =>
    @ctx.clearRect(0, 0, @preview.width(), @preview.height())

    # create circle clip area
    @ctx.save()

    @ctx.beginPath()
    @ctx.arc(@centerX, @centerY, @size/2, 0, 2 * Math.PI, false)
    @ctx.closePath()
    @ctx.clip()

    # flip the image to look like a mirror
    @ctx.scale(-1,1)

    # draw video frame
    @ctx.drawImage(@video.get(0), @offsetX, 0, -@video.width(), @size)

    # flip the image to look like a mirror
    @ctx.scale(-1,1)

    # add anti-aliasing
    # http://stackoverflow.com/a/12395939
    @ctx.strokeStyle = @backgroundColor
    @ctx.lineWidth = 2
    @ctx.arc(@centerX, @centerY, @size/2, 0, 2 * Math.PI, false)
    @ctx.stroke()

    # reset the clip area to be able to draw on the whole canvas
    @ctx.restore()

    # update the preview again as soon as
    # the browser is ready to draw a new frame
    if not @photoTaken
      requestAnimationFrame @updatePreview
    else
      # cache raw video data
      @cacheScreenshot()

  initializeCache: ->
    # create virtual canvas
    @cache = $('<canvas>')
    @cacheCtx = @cache.get(0).getContext('2d')

  cacheScreenshot: ->
    # reset video height
    @video.attr height: ''

    @cache.attr
      width:  @video.height()
      height: @video.height()

    offsetX = (@video.width() - @video.height())/2

    # draw full resolution screenshot
    @cacheCtx.save()

    # flip image
    @cacheCtx.scale(-1,1)
    @cacheCtx.drawImage(@video.get(0), offsetX, 0, -@video.width(), @video.height())

    @cacheCtx.restore()

    # reset video height
    @video.attr height: @size

  onHide: =>
    @stream.stop() if @stream
    @hidden = true

  onSubmit: (e) =>
    e.preventDefault()
    # send picture to the
    @options.callback( @cache.get(0).toDataURL() )
    @hide()
