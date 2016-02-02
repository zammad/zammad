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

  function Plugin( element, options ) {
    this.element    = element
    this.$element   = $(element)

    this.options    = $.extend( {}, defaults, options)

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

    this.init();
  }

  Plugin.prototype.init = function () {
    this.baseTemplate()
    var _this = this

    this.$element.on('keydown', function (e) {

      // esc
      if ( e.keyCode === 27 ) {
        _this.close()
      }

      // navigate through item
      if ( _this.isActive() ) {

        // enter
        if ( e.keyCode === 13 ) {
          e.preventDefault()
          var id = _this.$widget.find('.dropdown-menu li.is-active').data('id')

          // as fallback use hovered element
          if (!id) {
            id = _this.$widget.find('.dropdown-menu li:hover').data('id')
          }

          // as fallback first element
          if (!id) {
            id = _this.$widget.find('.dropdown-menu li:first-child').data('id')
          }
          _this.take(id)
          return
        }

        // arrow keys left/right
        if ( e.keyCode === 37 || e.keyCode === 39 ) {
          e.preventDefault()
          return
        }

        // up
        if ( e.keyCode === 38 ) {
          e.preventDefault()
          if ( !_this.$widget.find('.dropdown-menu li.is-active')[0] ) {
            var top = _this.$widget.find('.dropdown-menu li').last().addClass('is-active').position().top
            _this.$widget.find('.dropdown-menu').scrollTop( top );
            return
          }
          else {
            var prev = _this.$widget.find('.dropdown-menu li.is-active').removeClass('is-active').prev()
            var top = 300
            if ( prev[0] ) {
              top = prev.addClass('is-active').position().top
            }
            _this.$widget.find('.dropdown-menu').scrollTop( top );
            return
          }
        }

        // down
        if ( e.keyCode === 40 ) {
          e.preventDefault()
          if ( !_this.$widget.find('.dropdown-menu li.is-active')[0] ) {
            var top = _this.$widget.find('.dropdown-menu li').first().addClass('is-active').position().top
            _this.$widget.find('.dropdown-menu').scrollTop( top );
            return
          }
          else {
            var next = _this.$widget.find('.dropdown-menu li.is-active').removeClass('is-active').next()
            var top = 300
            if ( next[0] ) {
              top = next.addClass('is-active').position().top
            }
            _this.$widget.find('.dropdown-menu').scrollTop( top );
            return
          }
        }

      }
    })

    // reduce buffer, in case close it
    this.$element.on('keydown', function (e) {

      // backspace
      if ( e.keyCode === 8 && _this.buffer ) {

        // backspace + buffer === :: -> close textmodule
        if ( _this.buffer === '::' ) {
          _this.close(true)
          e.preventDefault()
          return
        }

        // reduce buffer and show new result
        var length   = _this.buffer.length
        _this.buffer = _this.buffer.substr( 0, length-1 )
        _this.log( 'BS backspace', _this.buffer )
        _this.result( _this.buffer.substr( 2, length-1 ) )
      }
    })

    // build buffer
    this.$element.on('keypress', function (e) {
      _this.log('BUFF', _this.buffer, e.keyCode, String.fromCharCode(e.which) )

      // shift
      if ( e.keyCode === 16 ) return

      // enter
      if ( e.keyCode === 13 ) return

      // arrow keys
      if ( e.keyCode === 37 || e.keyCode === 38 || e.keyCode === 39 || e.keyCode === 40 ) return

      // observer other second key
      if ( _this.buffer === ':' && String.fromCharCode(e.which) !== ':' ) {
        _this.buffer = ''
      }

      // oberserve second :
      if ( _this.buffer === ':' && String.fromCharCode(e.which) === ':' ) {
        _this.buffer = _this.buffer + ':'
      }

      // oberserve first :
      if ( !_this.buffer && String.fromCharCode(e.which) === ':' ) {
        _this.buffer = _this.buffer + ':'
      }

      if ( _this.buffer && _this.buffer.substr(0,2) === '::' ) {

        var sign = String.fromCharCode(e.which)
        if ( sign && sign !== ':' && e.which != 8 ) { // 8 == backspace
          _this.buffer = _this.buffer + sign
          //_this.log('BUFF ADD', sign, this.buffer, sign.length, e.which)
        }
        _this.log('BUFF HINT', _this.buffer, _this.buffer.length, e.which, String.fromCharCode(e.which))

        b = $.proxy(function() {
          this.result( this.buffer.substr(2,this.buffer.length) )
        }, _this)
        setTimeout(b, 400);

        if (!_this.isActive()) {
          _this.open()
        }

      }

    }).on('focus', function (e) {
      _this.close()
    })
  };

  // create base template
  Plugin.prototype.baseTemplate = function() {
    this.$element.after('<div class="shortcut dropdown"><ul class="dropdown-menu" style="max-height: 200px;"><li><a>-</a></li></ul></div>')
    this.$widget = this.$element.next()
    this.$widget.on('click', 'li', $.proxy(this.onEntryClick, this))
    this.$widget.on('mousemove', $.proxy(this.onMouseover, this))
  }

  // set height of widget
  Plugin.prototype.movePosition = function() {
    if (!this._position) return
    var height       = this.$element.height() + 2
    var widgetHeight = this.$widget.find('ul').height() //+ 60 // + height
    var top          = -( widgetHeight + height ) + this._position.top
    var left = this._position.left - 6

    // position the element further left if it would break out of the textarea width
    if (left + this._width > this.$element.innerWidth()) {
      left = this.$element.innerWidth() - this._width
    }

    this.$widget.css({
      top: top,
      left: left,
      width: this._width
    })
  }

  // set position of widget
  Plugin.prototype.updatePosition = function() {
    this.$widget.find('.dropdown-menu').scrollTop( 300 );
    if ( !this.$element.is(':visible') ) return

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
    $(window).off('click.textmodule')
  }

  // check if widget is active/open
  Plugin.prototype.isActive = function() {
    return this.active
  }

  // paste some content
  Plugin.prototype.paste = function(string) {
    string = App.Utils.text2html(string) + '<br>'
    if (document.selection) { // IE
      var range = document.selection.createRange()
      range.pasteHTML(string)
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
      if ( spacerChar === ' ' ) {
        start = start - 1
      }
    }
    //this.log('CUT FOR', string, "-"+clone.toString()+"-", start, range.startOffset)
    clone.setStart(range.startContainer, start)
    clone.setEnd(range.startContainer, range.startOffset)
    clone.deleteContents()

    // for chrome, insert space again
    if (start) {
      if ( spacerChar === ' ' ) {
        string = "&nbsp;"
        if (document.selection) { // IE
          var range = document.selection.createRange()
          range.pasteHTML(string)
        }
        else {
          document.execCommand('insertHTML', false, string)
        }
      }
    }
  }

  Plugin.prototype.onMouseover = function(event) {
    this.$widget.find('.is-active').removeClass('is-active')
  }

  Plugin.prototype.onEntryClick = function(event) {
    var id = $(event.target).data('id')
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
      if ( item.id == id ) {
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
    var result = _.filter( this.collection, function(item) {
      var reg = new RegExp( term, 'i' )
      if ( item.name && item.name.match( reg ) ) {
        return item
      }
      if ( item.keywords && item.keywords.match( reg ) ) {
        return item
      }
      return
    })

    result.reverse()

    this.$widget.find('ul').html('')
    this.log('result', term, result)

    if (!result[0]) {
      return this.close()
    }

    if (!this.active) {
      this.open()
    }

    for (var i = 0; i < result.length; i++) {
      var item = result[i]
      var element = $('<li>')
      element.attr('data-id', item.id)
      element.text(App.Utils.htmlEscape(item.name))
      element.addClass('u-clickable u-textTruncate')
      if (i == result.length-1) {
        element.addClass('is-active')
      }
      this.$widget.find('ul').append(element)
    }
    
    this.$widget.find('ul').scrollTop(9999)
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

  $.fn[pluginName] = function ( options ) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName,
        new Plugin( this, options ));
      }
    });
  }

}(jQuery, window));