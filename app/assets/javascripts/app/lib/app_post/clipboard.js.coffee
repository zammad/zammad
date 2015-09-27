class App.ClipBoard
  _instance = undefined

  @bind: (el) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.bind(el)

  @getSelected: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.getSelected()

  @getSelectedLast: ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.getSelectedLast()

  @getPosition: (el) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.getPosition(el)

  @setPosition: ( el, pos ) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.setPosition( el, pos )

  @keycode: (code) ->
    if _instance == undefined
      _instance ?= new _Singleton
    _instance.keycode(code)

class _Singleton
  constructor: ->
    @selection     = ''
    @selectionLast = ''

  # bind to fill selected text into
  bind: (el) ->
    $(el).bind('mouseup', =>

      # check selection on mouse up
      @selection = @_getSelected()
      if @selection
        @selectionLast = @selection
    )
    $(el).bind('keyup', (e) =>

      # check selection on sonder key
      if e.keyCode == 91
        @selection = @_getSelected()
        if @selection
          @selectionLast = @selection

      # check selection of arrow keys
      if e.keyCode == 37 || e.keyCode == 38 || e.keyCode == 39 || e.keyCode == 40
        @selection = @_getSelected()
        if @selection
          @selectionLast = @selection
    )

  # get cross browser selected string
  _getSelected: ->
    text = ''
    if window.getSelection
      text = window.getSelection()
    else if document.getSelection
      text = document.getSelection()
    else if document.selection
      text = document.selection.createRange().text
    if text
#      text = text.toString().trim()
      text = $.trim( text.toString() )
    text

  # get current selection
  getSelected: ->
    @selection

  # get latest selection
  getSelectedLast: ->
    @selectionLast

  getPosition: (el) ->
    pos = 0
    el = document.getElementById(el)

    # IE Support
    if document.selection
      el.focus()
      Sel = document.selection.createRange()
      Sel.moveStart( 'character', -el.value.length )
      pos = Sel.text.length

    # Firefox support
    else if (el.selectionStart || el.selectionStart == '0')
      pos = el.selectionStart
    return pos

  setPosition: (el, pos) ->
    el = document.getElementById(el)

    # IE Support
    if el.setSelectionRange
      el.focus()
      el.setSelectionRange( pos, pos )

    # Firefox support
    else if el.createTextRange
      range = el.createTextRange()
      range.collapse(true)
      range.moveEnd( 'character', pos )
      range.moveStart('character', pos)
      range.select()

  keycode: (code) ->
    for key, value of @keycodesTable()
      if value.toString() is code.toString()
        return key

  keycodesTable: ->
    map = {
      'backspace' : 8,
      'tab' : 9,
      'enter' : 13,
      'shift' : 16,
      'ctrl' : 17,
      'alt' : 18,
      'space' : 32,
      'pause_break' : '19',
      'caps_lock' : '20',
      'escape' : '27',
      'page_up' : '33',
      'page down' : '34',
      'end' : '35',
      'home' : '36',
      'left_arrow' : '37',
      'up_arrow' : '38',
      'right_arrow' : '39',
      'down_arrow' : '40',
      'insert' : '45',
      'delete' : '46',
      '0' : '48',
      '1' : '49',
      '2' : '50',
      '3' : '51',
      '4' : '52',
      '5' : '53',
      '6' : '54',
      '7' : '55',
      '8' : '56',
      '9' : '57',
      'a' : '65',
      'b' : '66',
      'c' : '67',
      'd' : '68',
      'e' : '69',
      'f' : '70',
      'g' : '71',
      'h' : '72',
      'i' : '73',
      'j' : '74',
      'k' : '75',
      'l' : '76',
      'm' : '77',
      'n' : '78',
      'o' : '79',
      'p' : '80',
      'q' : '81',
      'r' : '82',
      's' : '83',
      't' : '84',
      'u' : '85',
      'v' : '86',
      'w' : '87',
      'x' : '88',
      'y' : '89',
      'z' : '90',
      'left_window key' : '91',
      'right_window key' : '92',
      'select_key' : '93',
      'numpad 0' : '96',
      'numpad 1' : '97',
      'numpad 2' : '98',
      'numpad 3' : '99',
      'numpad 4' : '100',
      'numpad 5' : '101',
      'numpad 6' : '102',
      'numpad 7' : '103',
      'numpad 8' : '104',
      'numpad 9' : '105',
      'multiply' : '106',
      'add' : '107',
      'subtract' : '109',
      'decimal point' : '110',
      'divide' : '111',
      'f1' : '112',
      'f2' : '113',
      'f3' : '114',
      'f4' : '115',
      'f5' : '116',
      'f6' : '117',
      'f7' : '118',
      'f8' : '119',
      'f9' : '120',
      'f10' : '121',
      'f11' : '122',
      'f12' : '123',
      'num_lock' : '144',
      'scroll_lock' : '145',
      'semi_colon' : '186',
      'equal_sign' : '187',
      'comma' : '188',
      'dash' : '189',
      'period' : '190',
      'forward_slash' : '191',
      'grave_accent' : '192',
      'open_bracket' : '219',
      'backslash' : '220',
      'closebracket' : '221',
      'single_quote' : '222'
    }
    map
