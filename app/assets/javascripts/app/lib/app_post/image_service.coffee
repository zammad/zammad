class App.ImageService
  @supported_types: ['image/jpeg', 'image/png']

  @resizeForAvatar: (dataURL, x, y, type = @supported_types[0], callback) =>
    if @checkUrl(dataURL)
      callback(dataURL)
    else
      @resize(dataURL, x, y, 2, type, 0.7, callback)

  @resizeForApp: (dataURL, x, y, callback) =>
    if @checkUrl(dataURL)
      callback(dataURL)
    else
      @resize(dataURL, x, y, 2, 'image/png', 0.7, callback)

  @resize: (dataURL, x = 'auto', y = 'auto', sizeFactor = 1, type, quality, callback, force = true) ->

    # load image from data url
    imageObject = new Image()
    imageObject.onload = =>
      imageWidth  = imageObject.width
      imageHeight = imageObject.height
      console.log('ImageService', 'current size', imageWidth, imageHeight)
      console.log('ImageService', 'sizeFactor', sizeFactor)
      if y is 'auto' && x is 'auto'
        x = imageWidth
        y = imageHeight

      # set max x/y
      if x isnt 'auto' && x > imageWidth
        x = imageWidth

      if y isnt 'auto' && y > imageHeight
        y = imageHeight

      # get auto dimensions
      if y is 'auto'# && (y * factor) >= imageHeight
        factor = imageWidth / x
        y = imageHeight / factor

      if x is 'auto'# && (y * factor) >= imageWidth
        factor = imageHeight / y
        x = imageWidth / factor

      canvas = document.createElement('canvas')

      # check if resize is needed
      resize = false
      if (x < imageWidth && (x * sizeFactor < imageWidth)) || (y < imageHeight && (y * sizeFactor < imageHeight))
        resize = true
        x = x * sizeFactor
        y = y * sizeFactor

        # set dimensions
        canvas.width  = x
        canvas.height = y

        # draw image on canvas and set image dimensions
        context = canvas.getContext('2d')
        context.drawImage(imageObject, 0, 0, x, y)

      else

        # set dimensions
        canvas.width  = imageWidth
        canvas.height = imageHeight

        # draw image on canvas and set image dimensions
        context = canvas.getContext('2d')
        context.drawImage(imageObject, 0, 0, imageWidth, imageHeight)

      # set quality based on image size
      if quality == 'auto'
        if x < 200 && y < 200
          quality = 1
        else if x < 400 && y < 400
          quality = 0.9
        else if x < 600 && y < 600
          quality = 0.8
        else if x < 900 && y < 900
          quality = 0.7
        else
          quality = 0.6

      newType = @validateType(type)
      newDataUrl = canvas.toDataURL(newType, quality)
      newSizeInMb = (newDataUrl.length * 0.75)/1024/1024 # approx. file size

      # Nokogiri parser has a single text node limit of 10 million characters, which may be exceeded for certain file
      #   types very easily (e.g. image/png), even for resized images. Here we check if the new size exceeds this limit
      #   and prevent execution of the callback (#5359).
      if newDataUrl.length > 10000000
        console.error('ImageService', 'image file size too large', newType, newSizeInMb, 'in mb')
        new App.ControllerErrorModal(
          message: __('Image file size is too large, please try inserting a smaller file.')
        )
        return

      # execute callback with resized image
      if resize
        console.log('ImageService', 'resize', x/sizeFactor, y/sizeFactor, quality, newSizeInMb, 'in mb')
        callback(newDataUrl, x/sizeFactor, y/sizeFactor, true)
        return
      console.log('ImageService', 'no resize', x, y, quality, newSizeInMb, 'in mb')
      callback(newDataUrl, x, y, false)

    # load image from data url
    imageObject.src = dataURL

  @checkUrl: (dataURL) ->
    ignore = /\.svg$/i
    ignore.test(dataURL)

  # check if the image type is supported
  # otherwise return our standard image type (the first listed supported type)
  @validateType: (type) =>
    if @supported_types.indexOf(type) == -1
      return @supported_types[0]
    else
      return type
