// Expanding Textareas v0.1.1
// MIT License
// https://github.com/bgrins/ExpandingTextareas

(function(factory) {
  // Add jQuery via AMD registration or browser globals
  if (typeof define === 'function' && define.amd) {
    define([ 'jquery' ], factory);
  }
  else {
    factory(jQuery);
  }
}(function ($) {

  var Expanding = function($textarea, opts) {
    Expanding._registry.push(this);

    this.$textarea = $textarea;
    this.$textCopy = $("<span />");
    this.$clone = $("<pre class='expanding-clone'><br /></pre>").prepend(this.$textCopy);

    this._resetStyles();
    this._setCloneStyles();
    this._setTextareaStyles();

    $textarea
      .wrap($("<div class='expanding-wrapper' style='position:relative' />"))
      .after(this.$clone);

    this.attach();
    this.update();
    if (opts.update) $textarea.bind("update.expanding", opts.update);
  };

  // Stores (active) `Expanding` instances
  // Destroyed instances are removed
  Expanding._registry = [];

  // Returns the `Expanding` instance given a DOM node
  Expanding.getExpandingInstance = function(textarea) {
    var $textareas = $.map(Expanding._registry, function(instance) {
        return instance.$textarea[0];
      }),
      index = $.inArray(textarea, $textareas);
    return index > -1 ? Expanding._registry[index] : null;
  };

  // Returns the version of Internet Explorer or -1
  // (indicating the use of another browser).
  // From: http://msdn.microsoft.com/en-us/library/ms537509(v=vs.85).aspx#ParsingUA
  var ieVersion = (function() {
    var v = -1;
    if (navigator.appName === "Microsoft Internet Explorer") {
      var ua = navigator.userAgent;
      var re = new RegExp("MSIE ([0-9]{1,}[\\.0-9]{0,})");
      if (re.exec(ua) !== null) v = parseFloat(RegExp.$1);
    }
    return v;
  })();

  // Check for oninput support
  // IE9 supports oninput, but not when deleting text, so keyup is used.
  // onpropertychange _is_ supported by IE8/9, but may not be fired unless
  // attached with `attachEvent`
  // (see: http://stackoverflow.com/questions/18436424/ie-onpropertychange-event-doesnt-fire),
  // and so is avoided altogether.
  var inputSupported = "oninput" in document.createElement("input") && ieVersion !== 9;

  Expanding.prototype = {

    // Attaches input events
    // Only attaches `keyup` events if `input` is not fully suported
    attach: function() {
      var events = 'input.expanding change.expanding',
        _this = this;
      if(!inputSupported) events += ' keyup.expanding';
      this.$textarea.bind(events, function() { _this.update(); });
    },

    // Updates the clone with the textarea value
    update: function() {
      this.$textCopy.text(this.$textarea.val().replace(/\r\n/g, "\n"));

      // Use `triggerHandler` to prevent conflicts with `update` in Prototype.js
      this.$textarea.triggerHandler("update.expanding");
    },

    // Tears down the plugin: removes generated elements, applies styles
    // that were prevously present, removes instance from registry,
    // unbinds events
    destroy: function() {
      this.$clone.remove();
      this.$textarea
        .unwrap()
        .attr('style', this._oldTextareaStyles || '');
      delete this._oldTextareaStyles;
      var index = $.inArray(this, Expanding._registry);
      if (index > -1) Expanding._registry.splice(index, 1);
      this.$textarea.unbind(
        'input.expanding change.expanding keyup.expanding update.expanding');
    },

    // Applies reset styles to the textarea and clone
    // Stores the original textarea styles in case of destroying
    _resetStyles: function() {
      this._oldTextareaStyles = this.$textarea.attr('style');

      this.$textarea.add(this.$clone).css({
        margin: 0,
        webkitBoxSizing: "border-box",
        mozBoxSizing: "border-box",
        boxSizing: "border-box",
        width: "100%"
      });
    },

    // Sets the basic clone styles and copies styles over from the textarea
    _setCloneStyles: function() {
      var css = {
        display: 'block',
        border: '0 solid',
        visibility: 'hidden',
        minHeight: this.$textarea.outerHeight()
      };

      if(this.$textarea.attr("wrap") === "off") css.overflowX = "scroll";
      else css.whiteSpace = "pre-wrap";

      this.$clone.css(css);
      this._copyTextareaStylesToClone();
    },

    _copyTextareaStylesToClone: function() {
      var _this = this,
        properties = [
          'lineHeight', 'textDecoration', 'letterSpacing',
          'fontSize', 'fontFamily', 'fontStyle',
          'fontWeight', 'textTransform', 'textAlign',
          'direction', 'wordSpacing', 'fontSizeAdjust',
          'wordWrap', 'word-break',
          'borderLeftWidth', 'borderRightWidth',
          'borderTopWidth','borderBottomWidth',
          'paddingLeft', 'paddingRight',
          'paddingTop','paddingBottom', 'maxHeight'];

      $.each(properties, function(i, property) {
        var val = _this.$textarea.css(property);

        // Prevent overriding percentage css values.
        if(_this.$clone.css(property) !== val) {
          _this.$clone.css(property, val);
          if(property === 'maxHeight' && val !== 'none') {
            _this.$clone.css('overflow', 'hidden');
          }
        }
      });
    },

    _setTextareaStyles: function() {
      this.$textarea.css({
        position: "absolute",
        top: 0,
        left: 0,
        height: "100%",
        resize: "none",
        overflow: "auto"
      });
    }
  };

  $.expanding = $.extend({
    autoInitialize: true,
    initialSelector: "textarea.expanding",
    opts: {
      update: function() { }
    }
  }, $.expanding || {});

  $.fn.expanding = function(o) {

    if (o === "destroy") {
      this.each(function() {
        var instance = Expanding.getExpandingInstance(this);
        if (instance) instance.destroy();
      });
      return this;
    }

    // Checks to see if any of the given DOM nodes have the
    // expanding behaviour.
    if (o === "active") {
      return !!this.filter(function() {
        return !!Expanding.getExpandingInstance(this);
      }).length;
    }

    var opts = $.extend({ }, $.expanding.opts, o);

    this.filter("textarea").each(function() {
      var visible = this.offsetWidth > 0 || this.offsetHeight > 0,
          initialized = Expanding.getExpandingInstance(this);

      if(visible && !initialized) new Expanding($(this), opts);
      else {
        if(!visible) _warn("ExpandingTextareas: attempt to initialize an invisible textarea. Call expanding() again once it has been inserted into the page and/or is visible.");
        if(initialized) _warn("ExpandingTextareas: attempt to initialize a textarea that has already been initialized. Subsequent calls are ignored.");
      }
    });
    return this;
  };

  function _warn(text) {
    if(window.console && console.warn) console.warn(text);
  }

  $(function () {
    if ($.expanding.autoInitialize) {
      $($.expanding.initialSelector).expanding();
    }
  });

}));