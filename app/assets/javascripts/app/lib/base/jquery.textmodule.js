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
  defaults = {}

  function Plugin( element, options ) {
    this.element    = element
    this.$element   = $(element)

    this.options    = $.extend( {}, defaults, options)

    this._defaults  = defaults
    this._name      = pluginName

    this.collection = []
    this.active = false
    this.buffer = ''

    // check if ce exists
    if ( $.data(element, 'plugin_ce') ) {
      this.ce = $.data(element, 'plugin_ce')
    }

    this.init();
  }

  Plugin.prototype.init = function () {
    this.baseTemplate()

    this.$element.on('keydown', $.proxy(function (e) {

      // esc
      if ( e.keyCode === 27 ) {
        this.close()
      }

      // navigate through widget
      if ( this.isActive() ) {
        console.log('WIDGET IS OPEN', e.keyCode)

        // enter
        if ( e.keyCode === 13 ) {
          e.preventDefault()
          var id = this.$widget.find('.dropdown-menu li.active a').data('id')
          console.log('ID', id)
          this.take(id)
        }

        // arrow keys
        if ( e.keyCode === 37 || e.keyCode === 38 || e.keyCode === 39 || e.keyCode === 40 ) {
          e.preventDefault()
        }

        // up
        if ( e.keyCode === 38 ) {
          if ( !this.$widget.find('.dropdown-menu li.active')[0] ) {
            var top = this.$widget.find('.dropdown-menu li').last().addClass('active').position().top
            this.$widget.find('.dropdown-menu').scrollTop( top );
          }
          else {
            var prev = this.$widget.find('.dropdown-menu li.active').removeClass('active').prev()
            var top = 300
            if ( prev[0] ) {
              top = prev.addClass('active').position().top
            }
            this.$widget.find('.dropdown-menu').scrollTop( top );
          }
        }

        // down
        if ( e.keyCode === 40 ) {
          if ( !this.$widget.find('.dropdown-menu li.active')[0] ) {
            var top = this.$widget.find('.dropdown-menu li').first().addClass('active').position().top
            this.$widget.find('.dropdown-menu').scrollTop( top );

          }
          else {
            var next = this.$widget.find('.dropdown-menu li.active').removeClass('active').next()
            var top = 300
            if ( next[0] ) {
              top = next.addClass('active').position().top
            }
            console.log('scrollTop', top, top-30)
            this.$widget.find('.dropdown-menu').scrollTop( top );

          }
        }

      }
    }, this ))

    this.$element.on('keydown', $.proxy(function (e) {

      // backspace
      if ( e.keyCode === 8 && this.buffer ) {
        if ( this.buffer === '::' ) {
          this.close()
        }
        this.buffer = this.buffer.substr( 0, this.buffer.length-1 )
        console.log('BS', this.buffer)
        this.result( this.buffer.substr(2,this.buffer.length) )
      }
    }, this ))

    this.$element.on('keypress', $.proxy(function (e) {
      var value = this.$element.text()
      console.log('BUFF', this.buffer, e.keyCode, String.fromCharCode(e.which) )
      a = $.proxy(function() {

        // shift
        if ( e.keyCode === 16 ) {
          return
        }

        // enter :
        if ( e.keyCode === 58 ) {
          this.buffer = this.buffer + ':'
        }

        if ( this.buffer && this.buffer.substr(0,2) === '::' ) {


          var sign = String.fromCharCode(e.which)
          if ( e.keyCode !== 58 ) {
            this.buffer = this.buffer + sign
          }
          console.log('BUFF HINT', this.buffer, this.buffer.length, e.which)

          this.result( this.buffer.substr(2,this.buffer.length) )

          if (!this.isActive()) {
            this.open()
          }

        }
      }, this)
      setTimeout(a, 400);

    }, this)).on('focus', $.proxy(function (e) {
      this.close()
    }, this)).on('blur', $.proxy(function (e) {
      // delay, to get click on text module before widget is closed
      a = $.proxy(function() {
        this.close()
      }, this)
      setTimeout(a, 600);
    }, this))

  };

  // create base template
  Plugin.prototype.baseTemplate = function() {
    this.$element.after('<div class="shortcut dropdown"><ul class="dropdown-menu" style="width: 360px; max-height: 200px;"><li><a>-</a></li></ul></div>')
    this.$widget = this.$element.next()
    this.updatePosition()
  }

  // get cursor position
  Plugin.prototype.getCaretPosition = function() {
    // not needed on IE
    if (document.selection) {
      return
    }
    else {
      document.execCommand('insertHTML', false, '<span id="hidden"></span>')
    }
    var hiddenNode = document.getElementById('hidden');
    if (!hiddenNode) {
        return 0;
    }
    var position = $(hiddenNode).position()
    hiddenNode.parentNode.removeChild(hiddenNode)
    return position
  }

  // update widget position
  Plugin.prototype.updatePosition = function() {
    this.$widget.find('.dropdown-menu').scrollTop( 300 );
    var position = this.getCaretPosition()
    var heightTextarea = this.$element.height()
    var widgetHeight = this.$widget.find('ul').height() + 40
    console.log('position', position)
    console.log('heightTextarea', heightTextarea)
    console.log('widgetHeight', widgetHeight)
    this.$widget.css('top', position.top - heightTextarea - widgetHeight)
    if ( !this.isActive() ) {
      this.$widget.css('left', position.left)
    }
  }

  // open widget
  Plugin.prototype.open = function() {
    this.active = true
    if (this.ce) {
      this.ce.input('off')
    }
    this.$widget.addClass('open')
  }

  // close widget
  Plugin.prototype.close = function() {
    this.active = false
    this.cutInput()
    if (this.ce) {
      this.ce.input('on')
    }
    this.$widget.removeClass('open')
  }

  // check if widget is active/open
  Plugin.prototype.isActive = function() {
    return this.active
  }

  // select text module and insert into text
  Plugin.prototype.take = function(id) {
    if (!id) {
      this.close()
      return
    }
    for (var i = 0; i < this.collection.length; i++) {
      var item = this.collection[i]
      if ( item.id == id ) {
        var content = item.content + "\n"
        this.cutInput()
        if (document.selection) {
          var range = document.selection.createRange()
          range.pasteHTML(content)
        }
        else {
          document.execCommand('insertHTML', false, content)
        }
        this.close()
        return
      }
    }
    return
  }

  // cut out search string from text
  Plugin.prototype.cutInput = function() {
    if (!this.buffer) return
    var sel = window.getSelection()
    if ( !sel || sel.rangeCount < 1) {
      this.buffer = ''
      return
    }
    var range = sel.getRangeAt(0)
    var clone = range.cloneRange()
    clone.setStart(range.startContainer, range.startOffset - this.buffer.length)
    clone.setEnd(range.startContainer, range.startOffset)
    clone.deleteContents()
    this.buffer = ''
  }

  // render result
  Plugin.prototype.result = function(term) {

    var result = _.filter( this.collection, function(item) {
      reg = new RegExp( term, 'i' )
      if ( item.name && item.name.match( reg ) ) {
        return item
      }
      if ( item.keywords && item.keywords.match( reg ) ) {
        return item
      }
      return
    })

    this.$widget.find('ul').html('')
    console.log('result', term, result)
    for (var i = 0; i < result.length; i++) {
      var item = result[i]
      template = "<li><a href=\"#\" class=\"u-textTruncate\" data-id=" + item.id + ">" + item.name
      if (item.keywords) {
        template = template + " (" + item.keywords + ")"
      }
      template = template + "</a></li>"
      this.$widget.find('ul').append(template)
    }
    if ( !result[0] ) {
      this.$widget.find('ul').append("<li><a href='#'>-</a></li>")
    }
    this.$widget.find('ul li').on(
      'click',
      $.proxy(function(e) {
        e.preventDefault()
        var id = $(e.target).data('id')
        this.take(id)
      }, this)
    )
    this.updatePosition()
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
