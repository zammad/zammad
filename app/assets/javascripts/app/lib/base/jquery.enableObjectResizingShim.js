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

    // only run if needed
    if (!document.queryCommandSupported('enableObjectResizing')) {
      this.bindEvents()
    }
  }

  Plugin.prototype.bindEvents = function () {
    this.$element.on('click', 'img', this.createEditor.bind(this))
    this.$element.on('click', this.destroyEditors.bind(this))
  }

  Plugin.prototype.createEditor = function (event) {
    event.stopPropagation()
    this.destroyEditors()
    var $img = $(event.currentTarget)

    if (!$img.hasClass('objectResizingEditorActive')) {
      new Editor($img)
    }
  }

  Plugin.prototype.destroyEditors = function () {
    this.$element.find('img.objectResizingEditorActive').each(function(i, img){
      editor = $(img).data('objectResizingEditor')
      if(editor){
        editor.destroy()
      }
    })
  }



  /*

    Resize Editor

  */

  function Editor($element) {
    this.$element = $element
    this.isResizing = false

    this.$element.data('objectResizingEditor', this)
    this.$element.addClass('objectResizingEditorActive')
    this.$element.wrap('<div class="enableObjectResizingShim" contenteditable="false"></div>')

    for (var i=0; i<4; i++) {
      this.$element.before('<div class="enableObjectResizingShim-handle"></div>')
    }

    $(document).one('click.objectResizingEditor', this.destroy.bind(this))
    $(document).one('keydown.objectResizingEditor', this.onKeydown.bind(this))
    this.$element.on('click.objectResizingEditor', this.stopPropagation.bind(this))
    this.$element.parent().find('.enableObjectResizingShim-handle').on('mousedown', this.startResize.bind(this))
  }

  Editor.prototype.onKeydown = function (event) {
    this.destroy()

    switch (event.keyCode) {
      case 8: // backspace
        this.$element.remove()
        break
      default:
        event.stopPropagation()
        break
    }
  }

  Editor.prototype.stopPropagation = function (event) {
    event.stopPropagation()
  }

  Editor.prototype.destroy = function (event) {
    if(this.isResizing) return
    this.$element.off('click.objectResizingEditor')
    $(document).off('click.objectResizingEditor')
    $(document).off('keydown.objectResizingEditor')
    this.$element.removeClass('objectResizingEditorActive')
    this.$element.siblings().remove()
    this.$element.unwrap()
  }

  Editor.prototype.startResize = function (event) {
    var $handle = $(event.currentTarget)
    this.resizeCorner = $handle.index()
    this.resizeDir = this.resizeCorner == 0 || this.resizeCorner == 3 ? -1 : 1
    this.startX = event.pageX
    this.startWidth = this.$element.width()
    this.$clone = this.$element.clone().css({width: '', height: ''}).addClass('enableObjectResizingShim-clone enableObjectResizingShim-clone--'+ this.resizeCorner)
    this.$element.after(this.$clone)
    this.isResizing = true
    $(document).on('mousemove.enableObjectResizing', this.resize.bind(this))
    $(document).on('mouseup.enableObjectResizing', this.resizeEnd.bind(this))
  }

  Editor.prototype.resize = function (event) {
    event.preventDefault()
    var dx = event.pageX - this.startX
    this.$clone.css('width', this.startWidth + (this.resizeDir * dx))
  }

  Editor.prototype.resizeEnd = function (event) {
    $(document).off('mousemove.enableObjectResizing')
    $(document).off('mouseup.enableObjectResizing')

    this.$element.css({
      width: this.$clone.width(),
      height: this.$clone.height()
    })
    this.$clone.remove()

    // reset isResizing with a delay to prevent a mouseup in the editor to trigger a editor-destroy
    setTimeout(function(){
      this.isResizing = false
    }.bind(this))
  }




  $.fn[pluginName] = function (options) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName, new Plugin(this, options))
      }
    });
  }

}(jQuery, window));