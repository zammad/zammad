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

    // disable browser based image resizing, use shim anyway
    document.execCommand('enableObjectResizing', false, false);
    this.bindEvents()
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
      $img = $(img)
      editor = $img.data('objectResizingEditor')

      // remove editor by object
      if(editor){
        editor.destroy()
      }

      // remove editor fragments manually
      else {
        $img.removeClass('objectResizingEditorActive')
        $img.siblings().remove()
        $img.unwrap()
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
    var elem = this.$element.closest('[contenteditable=true]')
    var previous = this.$element.parent().parent().prev()
    this.destroy()

    switch (event.keyCode) {
      case 8: // backspace
        this.$element.remove()
        event.preventDefault()

        if(previous[0]){
          range = document.createRange()
          range.selectNode(previous[0])
          range.setStart(range.endContainer, range.endOffset)
          document.getSelection().removeAllRanges()
          document.getSelection().addRange(range)
        }

        elem.focus()

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
    var $handle = $(event.currentTarget),
      maxWidth = this.$element.closest('[contenteditable="true"]').width() || ''
    this.resizeCorner = $handle.index()
    this.resizeDir = this.resizeCorner == 0 || this.resizeCorner == 3 ? -1 : 1
    this.startX = event.pageX
    this.startWidth = this.$element.width()
    this.$clone = this.$element.clone().css({width: '', height: '', 'max-width': maxWidth}).addClass('enableObjectResizingShim-clone enableObjectResizingShim-clone--'+ this.resizeCorner)
    this.$element.after(this.$clone)
    this.isResizing = true
    $(document).on('mousemove.enableObjectResizing', this.resize.bind(this))
    $(document).on('mouseup.enableObjectResizing', this.resizeEnd.bind(this))
  }

  Editor.prototype.resize = function (event) {
    event.preventDefault()
    event.stopPropagation()
    var dx = event.pageX - this.startX
    this.$clone.css('width', this.startWidth + (this.resizeDir * dx))
  }

  Editor.prototype.resizeEnd = function (event) {
    var maxWidth = this.$element.closest('[contenteditable="true"]').width(),
      width = this.$clone.width(),
      height = this.$clone.height(),
      naturalWidth = this.$clone.get(0).naturalWidth,
      naturalHeight = this.$clone.get(0).naturalHeight

    if (maxWidth && maxWidth < width + 10) {
      height = ''
      width = ''
      if (naturalWidth) {
        width = naturalWidth / 2
      }
    }

    $(document).off('mousemove.enableObjectResizing')
    $(document).off('mouseup.enableObjectResizing')

    this.$element.css({
      width: width,
      height: height,
      'max-width': '100%'
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
