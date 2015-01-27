(function ($) {

/*
# mode:          textonly/richtext / disable b/i/u/enter + strip on paste
# pasteOnlyText: true
# maxlength:     123
# multiline:     true / disable enter + strip on paste
# placeholder:   'some placeholder'
*/

  var pluginName = 'ce',
  defaults = {
    mode:     'richtext',
    multiline: true,
    allowKey: {
      8: true, // backspace
      9: true, // tab
      16: true, // shift
      17: true, // ctrl
      18: true, // alt
      20: true, // cabslock
      37: true, // up
      38: true, // right
      39: true, // down
      40: true, // left
      91: true, // cmd left
      92: true, // cmd right
      224: true, // cmd left
    },
    extraAllowKey: {
      65: true, // a + ctrl - select all
      67: true, // c + ctrl - copy
      86: true, // v + ctrl - paste
      88: true, // x + ctrl - cut
      90: true, // z + ctrl - undo
    },
    richTextFormatKey: {
      66: true, // b
      73: true, // i
      85: true, // u
    },
    //maxlength: 20,
  };

  function Plugin( element, options ) {
    this.element  = element;
    this.$element = $(element)

    this.options = $.extend( {}, defaults, options) ;

    this._defaults = defaults;
    this._name     = pluginName;
    this._setTimeOutReformat = false;

    // take placeholder from markup
    if ( !this.options.placeholder && this.$element.data('placeholder') ) {
      this.options.placeholder = this.$element.data('placeholder')
    }

    this.preventInput = false

    this.init();
  }


  Plugin.prototype.init = function () {
    var _this = this

    // handle enter
    this.$element.on('keydown', function (e) {
      console.log('keydown', e.keyCode)
      if ( _this.preventInput ) {
        console.log('preventInput', _this.preventInput)
        return
      }

      // strap the return key being pressed
      if (e.keyCode === 13) {

        // disbale multi line
        if ( !_this.options.multiline ) {
          e.preventDefault()
          return
        }
      }

      // limit check
      if ( !_this.allowKey(e) ) {
        if ( !_this.maxLengthOk( 1 ) ) {
          e.preventDefault()
          return
        }
      }
    })

    // just paste text
    this.$element.on('paste', function (e) {
      console.log('paste')

      // check existing + paste text for limit
      var text
      if (window.clipboardData) { // IE
        text = window.clipboardData.getData('Text')
      }
      else {
        text = (e.originalEvent || e).clipboardData.getData('text/plain')
      }

      if ( !_this.maxLengthOk( text.length) ) {
        e.preventDefault()
        return
      }

      // use setTimeout() with 0 to execute it right after paste event
      if ( _this.options.mode === 'textonly' ) {
        if ( !_this.options.multiline ) {
          setTimeout($.proxy(function(){
            App.Utils.htmlRemoveTags(this.$element)
          }, _this), 0)
        }
        else {
          setTimeout($.proxy(function(){
            App.Utils.htmlRemoveRichtext(this.$element)
          }, _this), 0)
        }
      }
      else {
        setTimeout($.proxy(function(){
          App.Utils.htmlCleanup(this.$element)
        }, _this), 0)
      }

      return true
    })

    // disable rich text b/u/i
    if ( this.options.mode === 'textonly' ) {
      this.$element.on('keydown', function (e) {
        if ( _this.richTextKey(e) ) {
          e.preventDefault()
        }
      })
    }
  }

  // check if key is allowed, even if length limit is reached
  Plugin.prototype.allowKey = function(e) {
    if ( this.options.allowKey[ e.keyCode ] ) {
      return true
    }
    if ( ( e.ctrlKey || e.metaKey ) && this.options.extraAllowKey[ e.keyCode ] ) {
      return true
    }
    return false
  }

  // check if rich text key is pressed
  Plugin.prototype.richTextKey = function(e) {
    // e.altKey
    // e.ctrlKey
    // e.metaKey
    // on mac block e.metaKey + i/b/u
    if ( !e.altKey && e.metaKey && this.options.richTextFormatKey[ e.keyCode ] ) {
      return true
    }
    // on win block e.ctrlKey + i/b/u
    if ( !e.altKey && e.ctrlKey && this.options.richTextFormatKey[ e.keyCode ] ) {
      return true
    }
    return false
  }

  // max length check
  Plugin.prototype.maxLengthOk = function(typeAhead) {
    if ( !this.options.maxlength ) {
      return true
    }
    var length = this.$element.text().length
    if (typeAhead) {
      length = length + typeAhead
    }
    console.log('maxLengthOk', length, this.options.maxlength)
    if ( length > this.options.maxlength ) {

      // try to set error on framework form
      var parent = this.$element.parent().parent()
      if ( parent.hasClass('controls') ) {
        parent.addClass('has-error')
        setTimeout($.proxy(function(){
            parent.removeClass('has-error')
          }, this), 1000)

        return false
      }

      // set validation on element
      else {
        this.$element.addClass('invalid')
        setTimeout($.proxy(function(){
            this.$element.removeClass('invalid')
          }, this), 1000)

        return false
      }
    }
    return true
  }

  // get value
  Plugin.prototype.value = function() {
    //this.updatePlaceholder( 'remove' )

    // get text
    if ( this.options.mode === 'textonly' ) {

      // strip html signes if multi line exists
      if ( this.options.multiline ) {

        // for validation, do not retrun empty content by empty tags
        text_plain = this.$element.text().trim()
        if ( !text_plain || text_plain == '' ) {
          return text_plain
        }
        return this.$element.html()
      }
      return this.$element.text().trim()
    }

    // for validation, do not retrun empty content by empty tags
    text_plain = this.$element.text().trim()
    if ( !text_plain || text_plain == '' ) {
      return text_plain
    }
    return this.$element.html().trim()
  }

  $.fn[pluginName] = function ( options ) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName,
        new Plugin( this, options ));
      }
    });
  }

  // get correct val if textbox
  $.fn.ceg = function() {
    var plugin = $.data(this[0], 'plugin_' + pluginName)
    return plugin.value()
  }

}(jQuery));