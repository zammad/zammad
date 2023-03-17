# coffeelint: disable=camel_case_classes
class App.Color extends Spine.Controller
  color:  undefined
  moving: undefined

  elements:
    '.js-input':                           'input'
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
    @color = new App.ColorObject(@attribute.value)

    @html App.view('generic/color')
      attribute: @attribute
      hsl: @color.asHslArray()

  onInput: ->
    @color.updateWithString @input.val()
    @renderPicker()
    @updateSwatch @color.asString()

  updateSwatch: (colorString) ->
    @swatch.css 'background-color', ''
    @swatch.css 'background-color', colorString

  onHueSaturationMousedown: (event) ->
    $(document).on 'mousemove.colorpicker', @onHueSaturationMousemove
    $(document).on 'mouseup.colorpicker', @onMouseup

    @onHueSaturationMousemove(event)

  onHueSaturationMousemove: (event) =>
    offset = @hueSaturation.offset()

    @color.updateWithHslComponent Math.max(0, Math.min(1, (event.pageX - offset.left)/@hueSaturation.width())), 0
    @color.updateWithHslComponent Math.max(0, Math.min(1, 1-(event.pageY - offset.top)/@hueSaturation.height())), 1
    @renderPicker()
    @renderPickerOutput()

  onLightnessMousedown: (event) ->
    $(document).on 'mousemove.colorpicker', @onLightnessMousemove
    $(document).on 'mouseup.colorpicker', @onMouseup

    @onLightnessMousemove(event)

  onLightnessMousemove: (event) =>
    offset = @lightness.offset()

    @color.updateWithHslComponent Math.max(0, Math.min(1, 1-(event.pageY - offset.top)/@lightness.height())), 2
    @renderPicker()
    @renderPickerOutput()

  onMouseup: ->
    $(document).off 'mousemove.colorpicker'
    $(document).off 'mouseup.colorpicker'

  renderPickerOutput: ->
    colorString = @color.asString()
    @updateSwatch colorString
    @input.val colorString

  renderPicker: ->
    components = @color.asHslArray()

    @lightnessPlane.css 'background-color': "hsla(0,0%,#{if components[2] > 0.5 then 100 else 0}%,#{2*Math.abs(components[2]-0.5)})"
    @saturationGradient.css 'background-image': "linear-gradient(transparent, hsl(0, 0%, #{components[2]*100}%))"
    @circle.css
      left: components[0]*100 +'%'
      top: 100 - components[1]*100 +'%'
      borderColor: if components[2] > 0.5 then 'black' else 'white'
    @huePlane.css 'background-color': "hsl(#{components[0]*360}, 100%, 50%)"
    @slider.css top: 100 - components[2]*100 +'%'
