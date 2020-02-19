class App.ColorObject
  original: undefined

  constructor: (original) ->
    @original = original

  asHslArray: ->
    if _.isArray(@original)
      @original
    else
      @constructor.anyToHslArray @original

  asString: ->
    if _.isArray(@original)
      @constructor.hslArrayToHslString(@original)
    else
      @original

  updateWithString: (newValue) ->
    @original = newValue

  updateWithHslComponent: (value, index) ->
    if !_.isArray(@original)
      @original = @constructor.anyToHslArray @original

    @original[index] = value

  @anyToRgb: (color) ->
    canvas = document.createElement('canvas')
    canvas.width = canvas.height = 1
    ctx = canvas.getContext('2d')
    ctx.clearRect(0, 0, 1, 1)
    ctx.fillStyle = color
    ctx.fillRect(0, 0, 1, 1)
    ctx.getImageData(0, 0, 1, 1).data

  @anyToHslArray: (color) ->
    @rgbToHslArray @anyToRgb(color)

  @anyToHslString: (color) ->
    @hslArrayToHslString @rgbToHslArray @anyToRgb color

  @rgbToHslArray: (rgb) ->
    return [0, 0, 0] if !rgb

    r = rgb[0] / 255
    g = rgb[1] / 255
    b = rgb[2] / 255

    max = Math.max(r, g, b)
    min = Math.min(r, g, b)
    l = (max + min) / 2

    if (max == min)
      h = s = 0 # achromatic
    else
      d = max - min
      s = if l > 0.5 then d / (2 - max - min) else d / (max + min)

      h = switch
        when r is max then (g - b) / d + (g < b ? 6 : 0)
        when g is max then (b - r) / d + 2
        when b is max then (r - g) / d + 4

      h /= 6

    [h, s, l]

  @hslArrayToHslString: (hslArray) ->
    "hsl(#{Math.round(360 * hslArray[0])},#{Math.round(100 * hslArray[1])}%,#{Math.round(100 * hslArray[2])}%)"
