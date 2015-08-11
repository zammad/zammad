class App.ImageService

  @resizeForAvatar: (dataURL, x, y, callback) =>
    if @checkUrl(dataURL)
      callback(dataURL)
    else
      @resize( dataURL, x, y, 2, 'image/jpeg', 0.7, callback )

  @resizeForApp: (dataURL, x, y, callback) =>
    if @checkUrl(dataURL)
      callback(dataURL)
    else
      @resize( dataURL, x, y, 2, 'image/png', 0.7, callback )

  @resize: ( dataURL, x = 'auto', y = 'auto', sizeFactor = 1, type, quallity, callback) =>

    # load image from data url
    imageObject = new Image()
    imageObject.onload = =>
      imageWidth  = imageObject.width
      imageHeight = imageObject.height
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

      if x < imageWidth || y < imageHeight
        x = x * sizeFactor
        y = y * sizeFactor

      # create canvas and set dimensions
      canvas        = document.createElement('canvas')
      canvas.width  = x
      canvas.height = y

      # draw image on canvas and set image dimensions
      context = canvas.getContext('2d')
      context.drawImage( imageObject, 0, 0, x, y )

      # execute callback with resized image
      newDataUrl = canvas.toDataURL( type, quallity )
      callback(newDataUrl)

    # load image from data url
    imageObject.src = dataURL

  @checkUrl: (dataURL) ->
    ignore = /\.svg$/i
    ignore.test( dataURL )
