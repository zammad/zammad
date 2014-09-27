(function ($) {

/*
# mode: textonly/richtext / disable b/i/u/enter + strip on paste
# pasteOnlyText: true
# maxlength: 123
# multiline: true / disable enter + strip on paste
# placeholder: 'some placeholder'
#
*/

  var DEFAULTS = {
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
  }
  var OPTIONS = {}

  // add/remove placeholder
  var updatePlaceholder = function(target, type) {
    var text = target.text().trim()
    var placeholder = '<span class="placeholder">' + OPTIONS.placeholder + '</span>'

    // add placholder if no text exists
    if ( type === 'add') {
      if ( !text ) {
        target.html( placeholder )
      }
    }

    // empty placeholder text
    else {
      if ( text === OPTIONS.placeholder ) {
        setTimeout(function(){
          document.execCommand('selectAll', false, '');
          document.execCommand('delete', false, '');
          document.execCommand('selectAll', false, '');
          document.execCommand('removeFormat', false, '');
        }, 100);
      }
    }
  }

  // max length check
  var maxLengthOk = function(field, typeAhead) {
    var length = field.text().length
    if (typeAhead) {
      length = length + 1
    }
    if ( length > OPTIONS.maxlength ) {
      field.addClass('invalid')
      setTimeout(function(){
        field.removeClass('invalid')
      }, 1000);
      return false
    }
    return true
  }

  // check if key is allowed, even if length limit is reached
  var allowKey = function(e) {
    if ( OPTIONS.allowKey[ e.keyCode ] ) {
      return true
    }
    if ( ( e.ctrlKey || e.metaKey ) && OPTIONS.extraAllowKey[ e.keyCode ] ) {
      return true
    }
    return false
  }

  // check if rich text key is pressed
  var richTextKey = function(e) {
    if ( ( e.ctrlKey || e.metaKey ) && OPTIONS.richTextFormatKey[ e.keyCode ] ) {
      return true
    }
    return false
  }

  // get correct val if textbox
  $.fn.ceg = function(option) {
    var options = $.extend({}, DEFAULTS, option)
    updatePlaceholder( this, 'remove' )

    // get text
    if ( options.mode === 'textonly' ) {

      // strip html signes if multi line exists
      if ( options.multiline ) {
        text = this.html()
        text = text.replace(/<br>/g, "\n") // new line as br
        text = text.replace(/<div>/g, "\n") // in some caes, new line als div
        text = $("<div>" + text + "</div>").text().trim()
        return text
      }
      return this.text().trim()
    }
    return this.html().trim()
  }

  $.fn.ce = function(option) {
    var options = $.extend({}, DEFAULTS, option)
    options.placeholder = options.placeholder || this.data('placeholder')
    OPTIONS = options

    // process placeholder
    if ( options.placeholder ) {
      updatePlaceholder( this, 'add' )
      this.bind('focus', function (e) {
        updatePlaceholder( $(e.target), 'remove' )
      }).bind('blur', function (e) {
        updatePlaceholder( $(e.target), 'add' )
      })
    }

    // maxlength check
    if ( options.maxlength ) {
      this.bind('keydown', function (e) {

        // check control key
        if ( allowKey(e) ) {
          maxLengthOk( $(e.target) )
        }

        // check type ahead key
        else {
          if ( !maxLengthOk( $(e.target), true ) ) {
            e.preventDefault()
          }
        }
      }).bind('keyup', function (e) {

        // check control key
        if ( allowKey(e) ) {
          maxLengthOk( $(e.target) )
        }

        // check type ahead key
        else {
          if ( !maxLengthOk( $(e.target), true ) ) {
            e.preventDefault()
          }
        }
      }).bind('focus', function (e) {
        maxLengthOk( $(e.target) )
      }).bind('blur', function (e) {
        maxLengthOk( $(e.target) )
      })
    }

    // just paste text
    if ( options.mode === 'textonly' ) {
      this.bind('paste', function (e) {
        var text = (e.originalEvent || e).clipboardData.getData('text/plain')
        var overlimit = false
        if (text) {

          // replace new lines
          if ( !options.multiline ) {
            text = text.replace(/\n/g, '')
            text = text.replace(/\r/g, '')
            text = text.replace(/\t/g, '')
          }

          // limit length, limit paste string
          if ( options.maxlength ) {
            var pasteLength   = text.length
            var currentLength = $(e.target).text().length
            var overSize      = ( currentLength + pasteLength ) - options.maxlength
            if ( overSize > 0 ) {
              text = text.substr( 0, pasteLength - overSize )
              overlimit = true
            }
          }

          // insert new text
          e.preventDefault()
          document.execCommand('inserttext', false, text)
          maxLengthOk( $(e.target), overlimit )
        }

      });
    }

    // disable rich text b/u/i
    if ( options.mode === 'textonly' ) {
      this.bind('keydown', function (e) {
        if ( richTextKey(e) ) {
          e.preventDefault()
        }
      });
    }

    // disable multi line
    if ( !options.multiline ) {
      this.bind('keydown', function (e) {
        switch ( e.keyCode ) {
          case 13: // enter
            e.preventDefault()
            break;
        }
      })
    }

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
