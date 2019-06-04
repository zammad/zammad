# coffeelint: disable=camel_case_classes
class App.IconsetPicker extends Spine.Controller
  sets:
    FontAwesome:
      name: 'Font Awesome'
      version: '4.7'
      website: 'https://fontawesome.com/v4.7.0/'
    anticon:
      name: 'Anticon'
      version: '2.10'
      website: 'https://2x.ant.design/components/icon/'
    material:
      name: 'Material'
      version: '2.2.0'
      website: 'https://material.io/icons/'
    ionicons:
      name: 'Ionicons'
      version: '2.0.1'
      website: 'https://ionicons.com/v2/'
    'Simple-Line-Icons':
      name: 'Simple Line Icons'
      version: '0.0.1'
      website: 'https://simplelineicons.github.io/'

  elements:
    '.js-set': 'setElements'
    'input':   'input'

  events:
    'click .js-set': 'pick'
    # 'mouseenter .icon': 'flip'

  constructor: ->
    super
    @render()

  element: =>
    @el

  render: ->
    @html App.view('generic/iconset_picker')
      attribute: @attribute
      sets: @sets

    for family, set of @sets
      App.Utils.loadIconFont(family)
      App.Utils.loadIconFontInfo family, @initializePreview.bind(@, family)

  initializePreview: (family, icons) ->
    @sets[family].icons = icons
    @renderPreview(family, icons)

  renderPreview: (family) ->
    fragment = document.createDocumentFragment()
    icons = _.shuffle(@sets[family].icons)

    for i in [0..(11*5-1)]
      fragment.appendChild $("<i class=\"icon\" data-font=\"#{family}\">#{String.fromCharCode('0x'+ icons[i].unicode)}</i>").get(0)

    @el.find("[data-family=\"#{family}\"] .js-preview").html fragment

  pick: (event) ->
    family = $(event.currentTarget).attr('data-family')
    @input.val family
    @setElements.removeClass('is-active')
    event.currentTarget.classList.add('is-active')

  flip: (event) ->
    $icon = $(event.currentTarget)
    family = $icon.closest('.js-set').attr('data-family')

    if $icon.hasClass('do-flash')
      $icon.removeClass('do-flash')
      # force redraw
      $icon.get(0).offsetWidth

    $icon.text String.fromCharCode('0x'+ _.sample(@sets[family].icons).unicode)
    $icon.addClass('do-flash')