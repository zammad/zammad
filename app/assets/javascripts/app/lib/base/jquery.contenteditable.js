(function ($) {

/*
# mode: textonly/richtext / disable b/i/u/enter + strip on paste
# pasteOnlyText: true
# maxlength: 123
# multiline: true / disable enter + strip on paste
# placeholder: 'some placeholder'
#
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
    }
  };

  function Plugin( element, options ) {
    this.element    = element;
    this.$element   = $(element)

    this.options = $.extend( {}, defaults, options) ;

    // take placeholder from markup
    if ( !this.options.placeholder && this.$element.data('placeholder') ) {
      this.options.placeholder = this.$element.data('placeholder')
    }

    this._defaults = defaults;
    this._name = pluginName;

    this.preventInput = false

    this.init();
  }

  Plugin.prototype.init = function () {

    // set focus class
    this.$element.on('focus', $.proxy(function (e) {
      this.$element.closest('.form-control').addClass('focus')
    }, this)).on('blur', $.proxy(function (e) {
      this.$element.closest('.form-control').removeClass('focus')
    }, this))

    // process placeholder
    if ( this.options.placeholder ) {
      this.updatePlaceholder( 'add' )
      this.$element.on('focus', $.proxy(function (e) {
        this.updatePlaceholder( 'remove' )
      }, this)).on('blur', $.proxy(function (e) {
        this.updatePlaceholder( 'add' )
      }, this))
    }

    // maxlength check
    //this.options.maxlength = 10
    if ( this.options.maxlength ) {
      this.$element.on('keydown', $.proxy(function (e) {
        console.log('maxlength', e.keyCode, this.allowKey(e))
        // check control key
        if ( this.allowKey(e) ) {
          this.maxLengthOk()
        }
        // check type ahead key
        else {
          if ( !this.maxLengthOk( true ) ) {
            e.preventDefault()
          }
        }
      }, this)).on('keyup', $.proxy(function (e) {
        // check control key
        if ( this.allowKey(e) ) {
          this.maxLengthOk()
        }
        // check type ahead key
        else {
          if ( !this.maxLengthOk( true ) ) {
            e.preventDefault()
          }
        }
      }, this)).on('focus', $.proxy(function (e) {
        this.maxLengthOk()
      }, this)).on('blur', $.proxy(function (e) {
        this.maxLengthOk()
      }, this))
    }

    // handle enter
    this.$element.on('keydown', $.proxy(function (e) {
      console.log('keydown', e.keyCode)
      if (this.preventInput) {
        console.log('preventInput', this.preventInput)
        return
      }

      // trap the return key being pressed
      if (e.keyCode === 13) {
        // disbale multi line
        if ( !this.options.multiline ) {
          e.preventDefault()
          return
        }
        // limit check
        if ( !this.maxLengthOk( true ) ) {
          e.preventDefault()
          return
        }

        newLine = "<br>"
        if ( this.options.mode === 'textonly' ) {
          newLine = "\n"
        }
        if (document.selection) {
          var range = document.selection.createRange()
          newLine = "<br/>" // ie is not supporting \n :(
          range.pasteHTML(newLine)
        }
        else {
          document.execCommand('insertHTML', false, newLine)
        }

        // prevent the default behaviour of return key pressed
        return false
      }
    }, this))

    // just paste text
    if ( this.options.mode === 'textonly' ) {
      this.$element.on('paste', $.proxy(function (e) {
        var text = (e.originalEvent || e).clipboardData.getData('text/plain')
        var overlimit = false
        if (text) {

          // replace new lines
          if ( !this.options.multiline ) {
            text = text.replace(/\n/g, '')
            text = text.replace(/\r/g, '')
            text = text.replace(/\t/g, '')
          }

          // limit length, limit paste string
          if ( this.options.maxlength ) {
            var pasteLength   = text.length
            var currentLength = this.$element.text().length
            var overSize      = ( currentLength + pasteLength ) - this.options.maxlength
            if ( overSize > 0 ) {
              text = text.substr( 0, pasteLength - overSize )
              overlimit = true
            }
          }

          // insert new text
          e.preventDefault()
          document.execCommand('inserttext', false, text)
          this.maxLengthOk( overlimit )
        }

      }, this))
    }

    // disable rich text b/u/i
    if ( this.options.mode === 'textonly' ) {
      this.$element.on('keydown', $.proxy(function (e) {
        if ( this.richTextKey(e) ) {
          e.preventDefault()
        }
      }, this))
    }
  };

  // add/remove placeholder
  Plugin.prototype.updatePlaceholder = function(type) {
    if (!this.options.placeholder) {
      return
    }
    var holder = this.$element
    var text = holder.text().trim()
    var placeholder = '<span class="placeholder">' + this.options.placeholder + '</span>'

    // add placholder if no text exists
    if ( type === 'add') {
      if ( !text ) {
        holder.html( placeholder )
      }
    }

    // empty placeholder text
    else {
      if ( text === this.options.placeholder ) {
        setTimeout(function(){
          document.execCommand('selectAll', false, '');
          document.execCommand('delete', false, '');
          document.execCommand('selectAll', false, '');
          document.execCommand('removeFormat', false, '');
        }, 100);
      }
    }
  }

  // disable/enable input
  Plugin.prototype.input = function(type) {
    if (type === 'off') {
      this.preventInput = true
    }
    else {
      this.preventInput = false
    }
  }

  // max length check
  Plugin.prototype.maxLengthOk = function(typeAhead) {
    var length = this.$element.text().length
    if (typeAhead) {
      length = length + 1
    }
    if ( length > this.options.maxlength ) {

      // try to set error on framework form
      parent = this.$element.parent().parent()
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

  // get value
  Plugin.prototype.value = function() {
    this.updatePlaceholder( 'remove' )

    // get text
    if ( this.options.mode === 'textonly' ) {

      // strip html signes if multi line exists
      if ( this.options.multiline ) {
        text = this.$element.html()
        text = text.replace(/<br>/g, "\n") // new line as br
        text = text.replace(/<div>/g, "\n") // in some caes, new line als div
        text = $("<div>" + text + "</div>").text().trim()
        return text
      }
      return this.$element.text().trim()
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

/* TODO: paste
    @$('.ticket-title-update').bind(
      'drop'
      (e) =>
        e.preventDefault()

        t2 = e.originalEvent.dataTransfer.getData("text/plain")# : window.event.dataTransfer.getData("Text");

        @log('drop', t2, e.keyCode, e.clipboardData, e, $(e.target).text().length)

        document.execCommand('inserttext', false, '123123');
        #document.execCommand('inserttext', false, prompt('Paste something.'));
    )
*/
