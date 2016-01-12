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
          var id = _this.$widget.find('.dropdown-menu li.active a').data('id')
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
          if ( !_this.$widget.find('.dropdown-menu li.active')[0] ) {
            var top = _this.$widget.find('.dropdown-menu li').last().addClass('active').position().top
            _this.$widget.find('.dropdown-menu').scrollTop( top );
            return
          }
          else {
            var prev = _this.$widget.find('.dropdown-menu li.active').removeClass('active').prev()
            var top = 300
            if ( prev[0] ) {
              top = prev.addClass('active').position().top
            }
            _this.$widget.find('.dropdown-menu').scrollTop( top );
            return
          }
        }

        // down
        if ( e.keyCode === 40 ) {
          e.preventDefault()
          if ( !_this.$widget.find('.dropdown-menu li.active')[0] ) {
            var top = _this.$widget.find('.dropdown-menu li').first().addClass('active').position().top
            _this.$widget.find('.dropdown-menu').scrollTop( top );
            return
          }
          else {
            var next = _this.$widget.find('.dropdown-menu li.active').removeClass('active').next()
            var top = 300
            if ( next[0] ) {
              top = next.addClass('active').position().top
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
    }).on('blur', function (e) {
      // delay, to get click on text module before widget is closed
      a = $.proxy(function() {
        this.close()
      }, _this)
      setTimeout(a, 600);
    })

  };

  // create base template
  Plugin.prototype.baseTemplate = function() {
    this.$element.after('<div class="shortcut dropdown"><ul class="dropdown-menu" style="width: 360px; max-height: 200px;"><li><a>-</a></li></ul></div>')
    this.$widget = this.$element.next()
  }

  // set height of widget
  Plugin.prototype.movePosition = function() {
    if (!this._position) return
    var height       = this.$element.height() + 20
    var widgetHeight = this.$widget.find('ul').height() //+ 60 // + height
    var top          = -( widgetHeight + height ) + this._position.top
    this.$widget.css('top', top)
    this.$widget.css('left', this._position.left)
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
    b = $.proxy(function() {
      this.$widget.addClass('open')
    }, this)
    setTimeout(b, 400);
  }

  // close widget
  Plugin.prototype.close = function(cutInput) {
    this.$widget.removeClass('open')
    if ( cutInput && this.active ) {
      this.cutInput(true)
    }
    this.buffer = ''
    this.active = false
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

    this.$widget.find('ul').html('')
    this.log('result', term, result)
    for (var i = 0; i < result.length; i++) {
      var item = result[i]
      var template = "<li><a href=\"#\" class=\"u-textTruncate\" data-id=" + item.id + ">" + App.Utils.htmlEscape(item.name)
      if (item.keywords) {
        template = template + " (" + App.Utils.htmlEscape(item.keywords) + ")"
      }
      template = template + "</a></li>"
      this.$widget.find('ul').append(template)
    }
    if ( !result[0] ) {
      this.$widget.find('ul').append("<li><a href='#'>-</a></li>")
    }
    this.$widget.find('ul li').on(
      'click',
      function(e) {
        e.preventDefault()
        var id = $(e.target).data('id')
        _this.take(id)
      }
    )
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