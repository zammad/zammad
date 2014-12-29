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
  };

  function Plugin( element, options ) {
    this.element  = element;
    this.$element = $(element)

    this.options = $.extend( {}, defaults, options) ;

    this._defaults = defaults;
    this._name     = pluginName;

    // take placeholder from markup
    if ( !this.options.placeholder && this.$element.data('placeholder') ) {
      this.options.placeholder = this.$element.data('placeholder')
    }

    // link input
    if ( !this.options.multiline ) {
      editorMode = Medium.inlineMode
    }

    // link textarea
    else if ( this.options.multiline && this.options.mode != 'richtext' ) {
      editorMode = Medium.partialMode
    }

    // rich text
    else {
      editorMode = Medium.richMode
    }

    // max length validation
    var validation = function(element) {

      // try to set error on framework form
      var parent = $(element).parent().parent()
      if ( parent.hasClass('controls') ) {
        parent.addClass('has-error')
        setTimeout($.proxy(function(){
            parent.removeClass('has-error')
          }, this), 1000)

        return false
      }

      // set validation on element
      else {
        $(element).addClass('invalid')
        setTimeout($.proxy(function(){
            $(element).removeClass('invalid')
          }, this), 1000)

        return false
      }
    }
    new Medium({
        element:          element,
        modifier:         'auto',
        placeholder:      this.options.placeholder || '',
        autofocus:        false,
        autoHR:           false,
        mode:             editorMode,
        maxLength:        this.options.maxlength || -1,
        maxLengthReached: validation,
        tags: {
          'break': 'br',
          'horizontalRule': 'hr',
          'paragraph': 'div',
          'outerLevel': ['pre', 'blockquote', 'figure'],
          'innerLevel': ['a', 'b', 'u', 'i', 'img', 'strong']
        },
    });
  }

  // get value
  Plugin.prototype.value = function() {
    //this.updatePlaceholder( 'remove' )

    // get text
    if ( this.options.mode === 'textonly' ) {

      // strip html signes if multi line exists
      if ( this.options.multiline ) {
        return this.$element.html()
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