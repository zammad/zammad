# coffeelint: disable=camel_case_classes
class App.IconPicker extends Spine.Controller
  library: null
  empty: false
  columns: 8
  currentItem: null

  events:
    'focus .js-input':        'onFocus'
    'input .js-filter-icons': 'filterIcons'
    'click .js-filter-icons': 'stopPropagation'
    'click .js-pick':         'onIconClick'
    'mouseenter .js-pick':    'highlightItem'
    'shown.bs.dropdown':      'onPickerOpen'
    'hidden.bs.dropdown':     'onPickerClose'
    'focus .js-shadow':       'onShadowFocus'

  elements:
    '.js-iconGrid':     'iconGrid'
    '.js-noMatch':      'noMatch'
    '.js-shadow':       'shadow'
    '.js-input':        'input'
    '.js-filter-icons': 'filter'
    '.js-pick':         'icons'

  stopPropagation: (event) ->
    event.stopPropagation()

  constructor: ->
    super
    @throttledRenderIcons = _.throttle(@renderIcons, 300)
    @render()
    App.Utils.loadIconFont(@attribute.iconset)
    App.Utils.loadIconFontInfo @attribute.iconset, (icons) =>
      @library = icons
      @renderIcons()

  element: =>
    @el

  render: ->
    attributeValue = @attribute.value
    @html App.view('generic/icon_picker')
      attribute: @attribute
      value: @attribute.value

  renderIcons: (filter) =>
    fragment = document.createDocumentFragment()
    regex = new RegExp(filter, 'i') if filter
    count = 0

    _.each @library, (icon) =>
      if !filter || filter && (regex.test(icon.name) || icon.filter && _.some(icon.filter, (w) -> regex.test(w)))
        count++
        fragment.appendChild $("<li class=\"icon js-pick\" data-font=\"#{@attribute.iconset}\" data-unicode=\"#{icon.unicode}\">#{String.fromCharCode('0x'+ icon.unicode)}</li>").get(0)

    if count
      @iconGrid.html fragment
      @empty = false
      @refreshElements()
    else
      if not @empty
        # show a random placeholder
        next = Math.floor(Math.random() * @noMatch.length)
        if next == @noMatch.filter('.is-active').index()
          next = (next + 1) % @noMatch.length
        @noMatch.removeClass('is-active').eq(next).addClass('is-active')
      @empty = true
      @iconGrid.empty()

  filterIcons: (event) =>
    @throttledRenderIcons event.currentTarget.value

  onIconClick: (event) ->
    @pick event.currentTarget.getAttribute('data-unicode')

  pick: (unicode) ->
    @shadow.val unicode
    @input.text String.fromCharCode("0x#{unicode}")
    @el.closest('form').trigger('input')

  # propergate focus to our visible input
  onShadowFocus: ->
    @input.focus()

  onPickerOpen: ->
    @filter.focus()
    @isOpen = true

  onPickerClose: ->
    @isOpen = false
    @filter.val ''
    @renderIcons()
    $(document).off 'keydown.icon_picker'

  onFocus: ->
    $(document).on 'keydown.icon_picker', @navigate

  navigate: (event) =>
    switch event.keyCode
      when 40 then @nudge event, 0, 1 # down
      when 38 then @nudge event, 0, -1 # up
      when 39 then @nudge event, 1 # right
      when 37 then @nudge event, -1 # left
      when 13 then @onEnter event
      when 27 then @onEscape()

  onEscape: ->
    @currentItem = null
    @toggle() if @isOpen

  onEnter: (event) ->
    if !@isOpen
      return @toggle()
    if @currentItem
      @pick @currentItem.attr('data-unicode')
      @toggle()

  toggle: ->
    @$('[data-toggle="dropdown"]').dropdown('toggle')

  nudge: (event, x, y) ->
    event.preventDefault()
    if !@currentItem
      selectedIndex = 0
    else
      selectedIndex = @currentItem.index()

      distance = switch
        when x > 0 then 1
        when x < 0 then -1
        when y > 0 then @columns
        when y < 0 then -@columns

      if selectedIndex + distance >= @icons.length or selectedIndex + distance < 0
        # out of boundary
        return

      selectedIndex += distance
      @unhighlightCurrentItem()

    @currentItem = @icons.eq(selectedIndex)
    @currentItem.addClass('is-active').get(0).scrollIntoView(behavior: 'instant')

  highlightItem: (event) =>
    @unhighlightCurrentItem()
    @currentItem = $(event.currentTarget)
    @currentItem.addClass('is-active')

  unhighlightCurrentItem: ->
    return if !@currentItem
    @currentItem.removeClass('is-active')
    @currentItem = null

