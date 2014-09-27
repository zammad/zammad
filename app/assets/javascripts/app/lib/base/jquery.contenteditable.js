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
    multiline: true
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
      })
      this.bind('blur', function (e) {
        updatePlaceholder( $(e.target), 'add' )
      })
    }

    // maxlength check
    if ( options.maxlength ) {
      this.bind('keydown', function (e) {
        // check maxlength
        var field = $(e.target)
        var length = $(e.target).text().length
        if ( length >= options.maxlength ) {
          switch ( e.keyCode ) {
            case 8: // backspace
              // just go ahead
              break;
            case 37: // up
              // just go ahead
              break;
            case 38: // right
              // just go ahead
              break;
            case 39: // down
              // just go ahead
              break;
            case 40: // left
              // just go ahead
              break;
            case 65: // a + ctrl - select all
              // just go ahead
              if ( e.ctrlKey || e.metaKey ) {
                break;
              }
            case 65: // x + ctrl - cut
              // just go ahead
              if ( e.ctrlKey || e.metaKey ) {
                break;
              }
            default:
              field.addClass('invalid')
              e.preventDefault()
          }
        }
        else {
          if ( field.hasClass('invalid') ) {
            field.removeClass('invalid')
          }
        }
      })
    }

    // just paste text
    if ( options.mode === 'textonly' ) {
      this.bind('paste', function (e) {
        var text = (e.originalEvent || e).clipboardData.getData('text/plain');
        if (text) {

          // replace new lines
          if ( !options.multiline ) {
            text = text.replace(/\n/g, '')
            text = text.replace(/\r/g, '')
            text = text.replace(/\t/g, '')
          }

          // limit length
          if ( options.maxlength ) {
            var pasteLength   = text.length
            var currentLength = $(e.target).text().length
            var overSize      = ( currentLength + pasteLength ) - options.maxlength
            if ( overSize > 0 ) {
              text = text.substr( 0, pasteLength - overSize )
            }
          }

          // insert new text
          e.preventDefault()
          document.execCommand('inserttext', false, text);
        }

      });
    }

    // disable rich text b/u/i
    if ( options.mode === 'textonly' ) {
      this.bind('keydown', function (e) {
        if ( e.ctrlKey || e.metaKey ) {
          switch ( e.keyCode ) {
            case 66: // b
              e.preventDefault()
              break;
            case 73: // i
              e.preventDefault()
              break;
            case 85: // u
              e.preventDefault()
              break;
          }
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
