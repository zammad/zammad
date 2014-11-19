class App.ImageService
  constructor: (url) ->
    @orgDataURL = url

  src: (url) =>
    @orgDataURL = url

  resize: ( x = 'auto', y = 'auto') =>
    @canvas  = document.createElement('canvas')
    context = @canvas.getContext('2d')

    # load image from data url
    imageObject     = new Image()
    imageObject.src = @orgDataURL
    imageWidth      = imageObject.width
    imageHeight     = imageObject.height

    if y is 'auto' && x is 'auto'
      x = imageWidth
      y = imageHeight

    # get auto dimensions
    if y is 'auto'
      factor = imageWidth / x
      y = imageHeight / factor

    if x is 'auto'
      factor = imageWidth / y
      x = imageHeight / factor

    console.log('BB', x, y)
    # set canvas dimensions
    @canvas.width  = x
    @canvas.height = y

    # draw image on canvas and set image dimensions
    context.drawImage( imageObject, 0, 0, x, y )
    @canvas

  toDataURL: (type, quallity = 1) =>
    #@resize()
    @canvas.toDataURL( type, quallity )

  toDataURLForApp: ( x, y ) =>
    @resize( x * 2, y * 2 )
    @toDataURL( 'image/jpeg', 0.7 )
