(function ($, window, undefined) {

/*
# mode: textonly/richtext / disable b/i/u/enter + strip on paste
# pasteOnlyText: true
# maxlength: 123
# multiline: true / disable enter + strip on paste
# placeholder: 'some placeholder'
#
*/

  var pluginName = 'textmodule',
  defaults = {
    debug: false
  }

  function Plugin(element, options) {
    this.element    = element
    this.$element   = $(element)

    this.options    = $.extend({}, defaults, options)

    this._defaults  = defaults
    this._name      = pluginName

    this.collection = []
    this.active     = false
    this.buffer     = ''

    this._width = 380

    // check if ce exists
    if ( $.data(element, 'plugin_ce') ) {
      this.ce = $.data(element, 'plugin_ce')
    }

    this.init()
  }

  Plugin.prototype.init = function () {
    this.renderBase()
    this.bindEvents()
  }

  Plugin.prototype.bindEvents = function () {
    this.$element.on('keydown', this.onKeydown.bind(this))
    this.$element.on('keypress', this.onKeypress.bind(this))
    this.$element.on('focus', this.onFocus.bind(this))
  }

  Plugin.prototype.onFocus = function (e) {
    this.close()
  }

  Plugin.prototype.onKeydown = function (e) {
    //console.log("onKeydown", this.isActive())
    // navigate through item
    if (this.isActive()) {

      // esc
      if (e.keyCode === 27) {
        e.preventDefault()
        e.stopPropagation()
        this.close()
        return
      }

      // enter
      if (e.keyCode === 13) {
        e.preventDefault()
        e.stopPropagation()
        var id = this.$widget.find('.dropdown-menu li.is-active').data('id')

        // as fallback use hovered element
        if (!id) {
          id = this.$widget.find('.dropdown-menu li:hover').data('id')
        }

        // as fallback first element
        if (!id) {
          id = this.$widget.find('.dropdown-menu li:first-child').data('id')
        }
        this.take(id)
        return
      }

      // arrow keys left/right
      if (e.keyCode === 37 || e.keyCode === 39) {
        e.preventDefault()
        e.stopPropagation()
        return
      }

      // up or down
      if (e.keyCode === 38 || e.keyCode === 40) {
        e.preventDefault()
        e.stopPropagation()
        var active = this.$widget.find('.dropdown-menu li.is-active')
        active.removeClass('is-active')

        if (e.keyCode == 38 && active.prev().size()) {
          active = active.prev()
        }
        else if (e.keyCode == 40 && active.next().size()) {
          active = active.next()
        }

        active.addClass('is-active')

        var menu = this.$widget.find('.dropdown-menu')

        if (!active.get(0)) {
          return
        }
        if (active.position().top < 0) {
          // scroll up
          menu.scrollTop( menu.scrollTop() + active.position().top )
        }
        else if ( active.position().top + active.height() > menu.height() ) {
          // scroll down
          var invisibleHeight = active.position().top + active.height() - menu.height()
          menu.scrollTop( menu.scrollTop() + invisibleHeight )
        }
      }
    }

    // esc
    if (e.keyCode === 27) {
      this.close()
    }

    // reduce buffer, in case close it
    // backspace
    if (e.keyCode === 8 && this.buffer) {

      // backspace + buffer === :: -> close textmodule
      if (this.buffer === '::') {
        this.close(true)
        e.preventDefault()
        return
      }

      // reduce buffer and show new result
      var length   = this.buffer.length
      this.buffer = this.buffer.substr(0, length-1)
      this.log('BS backspace', this.buffer)
      this.result(this.buffer.substr(2, length-1))
    }
  }

  Plugin.prototype.onKeypress = function (e) {
    this.log('BUFF', this.buffer, e.keyCode, String.fromCharCode(e.which))

    // shift
    if (e.keyCode === 16) return

    // enter
    if (e.keyCode === 13) return

    // arrow keys
    if (e.keyCode === 37 || e.keyCode === 38 || e.keyCode === 39 || e.keyCode === 40) return

    // observer other second key
    if (this.buffer === ':' && String.fromCharCode(e.which) !== ':') {
      this.buffer = ''
    }

    // oberserve second :
    if (this.buffer === ':' && String.fromCharCode(e.which) === ':') {
      this.buffer = this.buffer + ':'
    }

    // oberserve first :
    if (!this.buffer && String.fromCharCode(e.which) === ':') {
      this.buffer = this.buffer + ':'
    }

    if (this.buffer && this.buffer.substr(0,2) === '::') {

      var sign = String.fromCharCode(e.which)
      if ( sign && sign !== ':' && e.which != 8 ) { // 8 == backspace
        this.buffer = this.buffer + sign
        //this.log('BUFF ADD', sign, this.buffer, sign.length, e.which)
      }
      this.log('BUFF HINT', this.buffer, this.buffer.length, e.which, String.fromCharCode(e.which))

      if (!this.isActive()) {
        this.open()
      }

      this.result(this.buffer.substr(2, this.buffer.length))
    }
  }

  // create base template
  Plugin.prototype.renderBase = function() {
    this.$element.after('<div class="shortcut dropdown"><ul class="dropdown-menu" style="max-height: 200px;"></ul></div>')
    this.$widget = this.$element.next()
    this.$widget.on('mousedown', 'li', $.proxy(this.onEntryClick, this))
    this.$widget.on('mouseenter', 'li', $.proxy(this.onMouseEnter, this))
  }

  // set height of widget
  Plugin.prototype.movePosition = function() {
    if (!this._position) return
    var height         = this.$element.outerHeight() + 2
    var widgetHeight   = this.$widget.find('ul').height() //+ 60 // + height
    var rtl            = document.dir == 'rtl'
    var top            = -( widgetHeight + height ) + this._position.top
    var start          = this._position.left - 6
    var availableWidth = this.$element.innerWidth()

    if(rtl){
      start = availableWidth - start
    }

    // position the element further left if it would break out of the textarea width
    if (start + this._width > availableWidth) {
      start = this.$element.innerWidth() - this._width
    }

    var css = {
      top: top,
      width: this._width
    }

    css[rtl ? 'right' : 'left'] = start

    this.$widget.css(css)
  }

  // set position of widget
  Plugin.prototype.updatePosition = function() {
    this.$widget.find('.dropdown-menu').scrollTop(300)
    if (!this.$element.is(':visible')) return

    // get cursor position
    var marker = '<span id="js-cursor-position"></span>'
    var range = this.getFirstRange();
    var clone = range.cloneRange()
    clone.pasteHtml(marker)
    this._position = $('#js-cursor-position').position()
    $('#js-cursor-position').remove()
    if (!this._position) return

    // set position of widget
    this.movePosition()
  }

  // open widget
  Plugin.prototype.open = function() {
    this.active = true
    this.updatePosition()
    this.renderBase()
    this.$widget.addClass('open')
    $(window).on('click.textmodule', $.proxy(this.close, this))
  }

  // close widget
  Plugin.prototype.close = function(cutInput) {
    this.$widget.removeClass('open')
    if ( cutInput && this.active ) {
      this.cutInput(true)
    }
    this.buffer = ''
    this.active = false
    this.$widget.remove()
    $(window).off('click.textmodule')
  }

  // check if widget is active/open
  Plugin.prototype.isActive = function() {
    return this.active
  }

  // paste some content
  Plugin.prototype.paste = function(string) {
    var isIE11 = !!window.MSInputMethodContext && !!document.documentMode;

    // IE <= 10
    if (document.selection && document.selection.createRange) {
      var range = document.selection.createRange()
      if (range.pasteHTML) {
        range.pasteHTML(string)
      }
    }
    // IE == 11
    else if (isIE11 && document.getSelection) {
      var range = document.getSelection().getRangeAt(0)
      var nnode = document.createElement('div')
          range.surroundContents(nnode)
          nnode.innerHTML = string
    }
    else {
      document.execCommand('insertHTML', false, string)
    }
  }

  // cut some content
  Plugin.prototype.cut = function(string) {
    var range = this.getFirstRange();
    if (!range) return
    /*
    var sel = window.getSelection()
    if ( !sel || sel.rangeCount < 1) {
      return
    }
    var range = sel.getRangeAt(0)
    */
    var clone = range.cloneRange()

    // improve error handling
    start = range.startOffset - string.length
    if (start < 0) {
      start = 0
    }

    // for chrome, remove also leading space, add it later - otherwice space will be tropped
    if (start) {
      clone.setStart(range.startContainer, start-1)
      clone.setEnd(range.startContainer, start)
      var spacerChar = clone.toString()
      if (spacerChar === ' ') {
        start = start - 1
      }
    }
    //this.log('CUT FOR', string, "-"+clone.toString()+"-", start, range.startOffset)
    clone.setStart(range.startContainer, start)
    clone.setEnd(range.startContainer, range.startOffset)
    clone.deleteContents()

    // for chrome, insert space again
    if (start) {
      if (spacerChar === ' ') {
        this.paste('&nbsp;')
      }
    }
  }

  Plugin.prototype.onMouseEnter = function(event) {
    this.$widget.find('.is-active').removeClass('is-active')
    $(event.currentTarget).addClass('is-active')
  }

  Plugin.prototype.onEntryClick = function(event) {
    event.preventDefault()
    var id = $(event.currentTarget).data('id')
    this.take(id)
  }

  // select text module and insert into text
  Plugin.prototype.take = function(id) {
    if (!id) {
      this.close(true)
      return
    }
    for (var i = 0; i < this.collection.length; i++) {
      var item = this.collection[i]
      if (item.id == id) {
        var content = item.content
        this.cutInput()
        this.paste(content)
        this.close(true)
        return
      }
    }
    return
  }

  Plugin.prototype.getFirstRange = function() {
    var sel = rangy.getSelection();
    return sel.rangeCount ? sel.getRangeAt(0) : null;
  }

  // cut out search string from text
  Plugin.prototype.cutInput = function() {
    if (!this.buffer) return
    if (!this.$element.text()) return
    this.cut(this.buffer)
    this.buffer = ''
  }

  // render result
  Plugin.prototype.result = function(term) {
    var _this = this
    var result = _.filter(this.collection, function(item) {
      var reg = new RegExp(term, 'i')
      if (item.name && item.name.match(reg)) {
        return item
      }
      if (item.keywords && item.keywords.match(reg)) {
        return item
      }
      return
    })

    result.reverse()

    this.$widget.find('ul').html('')
    this.log('result', term, result)

    var elements = $()

    for (var i = 0; i < result.length; i++) {
      var item = result[i]
      var element = $('<li>')
      element.attr('data-id', item.id)
      element.text(item.name)
      element.addClass('u-clickable u-textTruncate')
      if (i == result.length-1) {
        element.addClass('is-active')
      }
      if (item.keywords) {
        element.append($('<kbd>').text(item.keywords))
      }
      elements = elements.add(element)
    }

    this.$widget.find('ul').append(elements).scrollTop(9999)
    this.movePosition()
  }

  // log method
  Plugin.prototype.log = function() {
    if (App && App.Log) {
      App.Log.debug(this._name, arguments)
    }
    if (this.options.debug) {
      console.log(this._name, arguments)
    }
  }

  $.fn[pluginName] = function (options) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName, new Plugin(this, options))
      }
    });
  }

}(jQuery, window));