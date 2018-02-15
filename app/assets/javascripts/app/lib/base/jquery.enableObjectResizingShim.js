(function ($, window, undefined) {

/*
# mode: textonly/richtext / disable b/i/u/enter + strip on paste
# pasteOnlyText: true
# maxlength: 123
# multiline: true / disable enter + strip on paste
# placeholder: 'some placeholder'
#
*/

  var pluginName = 'enableObjectResizingShim',
  defaults = {
    debug: false
  }

  function Plugin(element, options) {
    this.element    = element
    this.$element   = $(element)

    this.options    = $.extend({}, defaults, options)

    this._defaults  = defaults
    this._name      = pluginName

    this.isActive    = false

    // only run if needed
    if (!document.queryCommandSupported('enableObjectResizing')) {
      this.init()
    }
  }

  Plugin.prototype.init = function () {
    this.bindEvents()
  }

  Plugin.prototype.bindEvents = function () {
    this.$element.on('focus', 'img', this.addResizeHandles.bind(this))
    this.$element.on('blur', 'img', this.removeResizeHandles.bind(this))
    this.$element.on('mousedown', '.enableObjectResizingShim-handle', this.startResize.bind(this))
  }

  Plugin.prototype.addResizeHandles = function (event) {
    if(this.isActive) return
    var $img = $(event.currentTarget)
    var $holder = $('<div class="enableObjectResizingShim" contenteditable="false"></div>')
    $img.wrap($holder)

    for (var i=0; i<4; i++) {
      $img.before('<div class="enableObjectResizingShim-handle"></div>')
    }

    this.isActive = true
  }

  Plugin.prototype.removeResizeHandles = function (event) {
    console.log("removeResizeHandles")
    if(this.isResizing) return
    var $img = this.$element.find('.enableObjectResizingShim img')
    $img.siblings().remove()
    $img.unwrap()
    this.isActive = false
  }

  Plugin.prototype.startResize = function (event) {
    $(document).on('mousemove.enableObjectResizing', this.resize.bind(this))
    $(document).on('mouseup.enableObjectResizing', this.resizeEnd.bind(this))
    var $handle = $(event.currentTarget)
    this.resizeCorner = $handle.index()
    this.$img = this.$element.find('.enableObjectResizingShim img')
    this.startX = event.pageX
    this.startWidth = this.$img.width()
    this.$clone = this.$img.clone().css({width: '', height: ''}).addClass('enableObjectResizingShim-clone enableObjectResizingShim-clone--'+ this.resizeCorner)
    this.$img.after(this.$clone)
    this.isResizing = true
  }

  Plugin.prototype.resize = function (event) {
    event.preventDefault()
    var dx = event.pageX - this.startX
    this.$clone.css('width', this.startWidth + dx)
  }

  Plugin.prototype.resizeEnd = function (event) {
    $(document).off('mousemove.enableObjectResizing')
    $(document).off('mouseup.enableObjectResizing')

    this.$img.css({
      width: this.$clone.width(),
      height: this.$clone.height()
    })
    this.$clone.remove()
    this.isResizing = false
  }

  $.fn[pluginName] = function (options) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName, new Plugin(this, options))
      }
    });
  }

}(jQuery, window));