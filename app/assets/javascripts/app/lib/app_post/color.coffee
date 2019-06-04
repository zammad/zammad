# coffeelint: disable=camel_case_classes
class App.Color extends Spine.Controller
  hsl: undefined

  elements:
    '.js-input':                           'input'
    '.js-shadow':                          'shadow'
    '.js-swatch':                          'swatch'
    '.js-colorpicker-hue-saturation':      'hueSaturation'
    '.js-colorpicker-lightness-plane':     'lightnessPlane'
    '.js-colorpicker-saturation-gradient': 'saturationGradient'
    '.js-colorpicker-circle':              'circle'
    '.js-colorpicker-lightness':           'lightness'
    '.js-colorpicker-hue-plane':           'huePlane'
    '.js-colorpicker-slider':              'slider'

  events:
    'input .js-input':                          'onInput'
    'mousedown .js-colorpicker-hue-saturation': 'onHueSaturationMousedown'
    'mousedown .js-colorpicker-lightness':      'onLightnessMousedown'
    'click .js-dropdown':                       'stopPropagation'

  stopPropagation: (event) ->
    event.stopPropagation()

  constructor: ->
    super
    @render()

  element: =>
    @el

  render: ->
    @hsl = @rgbToHsl(@parseColor(@attribute.value))
    @html App.view('generic/color')
      attribute: @attribute
      hsl: @hsl

  onInput: ->
    @update @input.val()
    @output()

  update: (color) ->
    @updateSwatch(color)
    @hsl = @rgbToHsl(@parseColor(color))
    @renderPicker()

  updateSwatch: (color) ->
    @swatch.css 'background-color', ''
    @swatch.css 'background-color', color

  output: ->
    hslString = @hslString(@hsl)
    @input.val hslString
    @updateSwatch hslString
    @shadow.val @rgbToHex(@parseColor(hslString))

  componentToHex: (c) ->
    hex = c.toString(16)
    if hex.length == 1 then '0' + hex else hex

  rgbToHex: (rgba) ->
    '#' + @componentToHex(rgba[0]) + @componentToHex(rgba[1]) + @componentToHex(rgba[2])

  parseColor: (color) ->
    canvas = document.createElement('canvas')
    canvas.width = canvas.height = 1
    ctx = canvas.getContext('2d')
    ctx.clearRect(0, 0, 1, 1)
    ctx.fillStyle = color
    ctx.fillRect(0, 0, 1, 1)
    ctx.getImageData(0, 0, 1, 1).data

  rgbToHsl: (rgb) ->
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

  hslString: ->
    "hsl(#{Math.round(360 * @hsl[0])},#{Math.round(100 * @hsl[1])}%,#{Math.round(100 * @hsl[2])}%)"

  onHueSaturationMousedown: (event) ->
    @offset = @hueSaturation.offset()
    $(document).on 'mousemove.colorpicker', @onHueSaturationMousemove
    $(document).on 'mouseup.colorpicker', @onMouseup
    @onHueSaturationMousemove(event)

  onHueSaturationMousemove: (event) =>
    @hsl[0] = Math.max(0, Math.min(1, (event.pageX - @offset.left)/@hueSaturation.width()))
    @hsl[1] = Math.max(0, Math.min(1, 1-(event.pageY - @offset.top)/@hueSaturation.height()))
    @renderPicker()
    @output()

  onLightnessMousedown: (event) ->
    @offset = @lightness.offset()
    $(document).on 'mousemove.colorpicker', @onLightnessMousemove
    $(document).on 'mouseup.colorpicker', @onMouseup
    @onLightnessMousemove(event)

  onLightnessMousemove: (event) =>
    @hsl[2] = Math.max(0, Math.min(1, 1-(event.pageY - @offset.top)/@lightness.height()))
    @renderPicker()
    @output()

  onMouseup: ->
    $(document).off 'mousemove.colorpicker'
    $(document).off 'mouseup.colorpicker'

  renderPicker: ->
    @lightnessPlane.css 'background-color': "hsla(0,0%,#{if @hsl[2] > 0.5 then 100 else 0}%,#{2*Math.abs(@hsl[2]-0.5)})"
    @saturationGradient.css 'background-image': "linear-gradient(transparent, hsl(0, 0%, #{@hsl[2]*100}%))"
    @circle.css
      left: @hsl[0]*100 +'%'
      top: 100 - @hsl[1]*100 +'%'
      borderColor: if @hsl[2] > 0.5 then 'black' else 'white'
    @huePlane.css 'background-color': "hsl(#{@hsl[0]*360}, 100%, 50%)"
    @slider.css top: 100 - @hsl[2]*100 +'%'


