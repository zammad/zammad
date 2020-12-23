(function ($) {

/*
# mode:          textonly/richtext / disable b/i/u/enter + strip on paste
# pasteOnlyText: true
# maxlength:     123
# multiline:     true / disable enter + strip on paste
# placeholder:   'some placeholder'
# imageWidth:    absolute (<img style="width: XXpx; height: XXXpx" src="">) || relative (<img style="width: 100%; max-width: XXpx;" src="">)
*/

  var pluginName = 'ce',
  defaults = {
    debug:     false,
    mode:      'richtext',
    multiline: true,
    imageWidth: 'absolute',
    allowKey:  {
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
      83: true, // s
    },
    //maxlength: 20,
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

    this.preventInput = false

    // handle contenteditable issues
    this.browserMagicKey = App.Browser.magicKey()
    this.browserHotkeys = App.Browser.hotkeys()

    this.init()
  }


  Plugin.prototype.init = function () {
    this.bindEvents()
    this.$element.enableObjectResizingShim()
  }

  Plugin.prototype.bindEvents = function () {
    this.$element.on('keydown', this.onKeydown.bind(this))
    this.$element.on('paste', this.onPaste.bind(this))
    this.$element.on('dragover', this.onDragover.bind(this))
    this.$element.on('drop', this.onDrop.bind(this))
  }

  Plugin.prototype.toggleBlock = function(tag) {
    sel = window.getSelection()
    node = $(sel.anchorNode)
    if (node.is(tag) || node.parent().is(tag) || node.parent().parent().is(tag)) {
      document.execCommand('formatBlock', false, 'div')
      //document.execCommand('RemoveFormat')
    }
    else {
      document.execCommand('formatBlock', false, tag)
    }
  }

  Plugin.prototype.onKeydown = function (e) {
    this.log('keydown', e.keyCode)
    if (this.preventInput) {
      this.log('preventInput', this.preventInput)
      return
    }

    // strap the return key being pressed
    if (e.keyCode === 13) {

      // disbale multi line
      if (!this.options.multiline) {
        e.preventDefault()
        return
      }

      // break <blockquote> after enter on empty line
      sel = window.getSelection()
      if (sel) {
        node = $(sel.anchorNode)
        if (node && node.parent() && node.parent().is('blockquote')) {
          e.preventDefault()
          document.execCommand('Insertparagraph')
          document.execCommand('Outdent')
          return
        }
      }

      // behavior to enter new line on alt+enter
      //  on alt + enter not realy newline is fired, to make
      //  it compat. to other systems, do it here
      if (!e.shiftKey && e.altKey && !e.ctrlKey && !e.metaKey) {
        e.preventDefault()
        this.paste('<br><br>')
        return
      }
    }

    // on zammad magicKey + i/b/u/s
    //  hotkeys + u -> Toggles the current selection between underlined and not underlined
    //  hotkeys + b -> Toggles the current selection between bold and non-bold
    //  hotkeys + i -> Toggles the current selection between italic and non-italic
    //  hotkeys + v -> Toggles the current selection between strike and non-strike
    //  hotkeys + f -> Removes the formatting tags from the current selection
    //  hotkeys + y -> Removes the formatting from while textarea
    //  hotkeys + z -> Inserts a Horizontal Rule
    //  hotkeys + l -> Toggles the text selection between an unordered list and a normal block
    //  hotkeys + k -> Toggles the text selection between an ordered list and a normal block
    //  hotkeys + o -> Draws a line through the middle of the current selection
    //  hotkeys + w -> Removes any hyperlink from the current selection
    var richtTextControl = false
    if (this.browserMagicKey == 'cmd') {
      if (!e.altKey && !e.ctrlKey && e.metaKey) {
        richtTextControl = true
      }
    }
    else {
      if (!e.altKey && e.ctrlKey && !e.metaKey) {
        richtTextControl = true
      }
    }
    if (richtTextControl && this.options.richTextFormatKey[ e.keyCode ]) {
      e.preventDefault()
      if (e.keyCode == 66) {
        document.execCommand('bold')
        return true
      }
      if (e.keyCode == 73) {
        document.execCommand('italic')
        return true
      }
      if (e.keyCode == 85) {
        document.execCommand('underline')
        return true
      }
      if (e.keyCode == 83) {
        document.execCommand('strikeThrough')
        return true
      }
    }

    var hotkeys = false
    if (this.browserHotkeys == 'ctrl+shift') {
      if (!e.altKey && e.ctrlKey && !e.metaKey && e.shiftKey) {
        hotkeys = true
      }
    }
    else {
      if (e.altKey && e.ctrlKey && !e.metaKey) {
        hotkeys = true
      }
    }

    if (hotkeys && (this.options.richTextFormatKey[ e.keyCode ]
      || e.keyCode == 49
      || e.keyCode == 50
      || e.keyCode == 51
      || e.keyCode == 66
      || e.keyCode == 70
      || e.keyCode == 90
      || e.keyCode == 70
      || e.keyCode == 73
      || e.keyCode == 75
      || e.keyCode == 76
      || e.keyCode == 85
      || e.keyCode == 83
      || e.keyCode == 88
      || e.keyCode == 90
      || e.keyCode == 89)) {
      e.preventDefault()

      // disable rich text b/u/i
      if ( this.options.mode === 'textonly' ) {
        return
      }

      if (e.keyCode == 49) {
        this.toggleBlock('h1')
      }
      if (e.keyCode == 50) {
        this.toggleBlock('h2')
      }
      if (e.keyCode == 51) {
        this.toggleBlock('h3')
      }
      if (e.keyCode == 66) {
        document.execCommand('bold')
      }
      if (e.keyCode == 70) {
        document.execCommand('removeFormat')
      }
      if (e.keyCode == 73) {
        document.execCommand('italic')
      }
      if (e.keyCode == 75) {
        document.execCommand('insertOrderedList')
      }
      if (e.keyCode == 76) {
        document.execCommand('insertUnorderedList')
      }
      if (e.keyCode == 85) {
        document.execCommand('underline')
      }
      if (e.keyCode == 83) {
        document.execCommand('strikeThrough')
      }
      if (e.keyCode == 88) {
        document.execCommand('unlink')
      }
      if (e.keyCode == 89) {
        var cleanHtml = App.Utils.htmlRemoveRichtext(this.$element.html())
        this.$element.html(cleanHtml)
      }
      if (e.keyCode == 90) {
        document.execCommand('insertHorizontalRule')
      }
      this.log('content editable richtext key', e.keyCode)
      return true
    }

    // limit check
    if ( !this.allowKey(e) ) {
      if ( !this.maxLengthOk(1) ) {
        e.preventDefault()
        return
      }
    }
  }

  Plugin.prototype.getHtmlFromClipboard = function(clipboardData) {
    try {
      return clipboardData.getData('text/html')
    }
    catch (e) {
      console.log('Sorry, can\'t get html of clipboard because browser is not supporting it.')
      return
    }
  }

  Plugin.prototype.getTextFromClipboard = function(clipboardData) {
    var text
    try {
      text = clipboardData.getData('text/plain')
      if (!text || text.length === 0) {
        text = clipboardData.getData('text')
      }
      return text
    }
    catch (e) {
      console.log('Sorry, can\'t get text of clipboard because browser is not supporting it.')
      return
    }
  }

  Plugin.prototype.getClipboardData = function(e) {
    var clipboardData
    if (e.clipboardData) { // ie
      clipboardData = e.clipboardData
    }
    else if (window.clipboardData) { // ie
      clipboardData = window.clipboardData
    }
    else if (e.originalEvent.clipboardData) { // other browsers
      clipboardData = e.originalEvent.clipboardData
    }
    else {
      throw "No clipboardData support"
    }
    return clipboardData
  }

  Plugin.prototype.getClipboardDataImage = function(clipboardData) {
    if (!clipboardData.items || !clipboardData.items[0]) {
      return
    }
    return $.grep(clipboardData.items, function(item){
      return item.kind == 'file' && (item.type == 'image/png' || item.type == 'image/jpeg')
    })[0]
  }

  Plugin.prototype.onPaste = function (e) {
    e.preventDefault()
    var clipboardData, clipboardImage, text, htmlRaw, htmlString

    this.log('paste')

    clipboardData = this.getClipboardData(e)

    // look for image only if no HTML with textual content is available.
    // E.g. Excel provides images of the spreadsheet along with HTML.
    // While some browsers make images available in clipboard as HTML,
    // sometimes wrapped in multiple nodes.
    htmlRaw = this.getHtmlFromClipboard(clipboardData)

    if (!App.Utils.clipboardHtmlIsWithText(htmlRaw)) {

      // insert and in case, resize images
      clipboardImage = this.getClipboardDataImage(clipboardData)
      if (clipboardImage) {

        this.log('paste image', clipboardImage)

        var imageFile = clipboardImage.getAsFile()
        var reader = new FileReader()

        reader.onload = $.proxy(function (e) {
          var result = e.target.result
          var img = document.createElement('img')
          img.src = result
          maxWidth = 1000
          if (this.$element.width() > 1000) {
            maxWidth = this.$element.width()
          }
          scaleFactor = 2
          //scaleFactor = 1
          //if (window.isRetina && window.isRetina()) {
          //  scaleFactor = 2
          //}

          insert = $.proxy(function(dataUrl, width, height, isResized) {
            //console.log('dataUrl', dataUrl)
            //console.log('scaleFactor', scaleFactor, isResized, maxWidth, width, height)
            this.log('image inserted')
            result = dataUrl
            if (this.options.imageWidth == 'absolute') {
              img = "<img tabindex=\"0\" style=\"width: " + width + "px; max-width: 100%;\" src=\"" + result + "\">"
            }
            else {
              img = "<img tabindex=\"0\" style=\"width: 100%; max-width: " + width + "px;\" src=\"" + result + "\">"
            }
            this.paste(img)
          }, this)

          // resize if to big
          App.ImageService.resize(img.src, maxWidth, 'auto', scaleFactor, 'image/jpeg', 'auto', insert)
        }, this)

        reader.readAsDataURL(imageFile)
        return true
      }
    }

    // insert html
    if (htmlRaw) {
      htmlString = App.Utils.clipboardHtmlInsertPreperation(htmlRaw, this.options)
      if (htmlString) {
        this.log('insert html from clipboard', htmlString)
        this.paste(htmlString)
        App.Utils.htmlImage2DataUrlAsyncInline(this.$element)
        return true
      }
    }

    // insert text
    text = this.getTextFromClipboard(clipboardData)
    if (!text) {
      return false
    }
    htmlString = App.Utils.text2html(text)

    // check length limit
    if (!this.maxLengthOk(htmlString.length)) {
      return
    }

    htmlString = App.Utils.removeEmptyLines(htmlString)
    this.log('insert text from clipboard', htmlString)
    this.paste(htmlString)
    return true
  }

  Plugin.prototype.onDragover = function (e) {
    e.stopPropagation()
    e.preventDefault()
    this.log('dragover')
  }

  Plugin.prototype.onDrop = function (e) {
    e.stopPropagation();
    e.preventDefault();
    this.log('drop')

    var dataTransfer
    if (window.dataTransfer) { // ie
      dataTransfer = window.dataTransfer
    }
    else if (e.originalEvent.dataTransfer) { // other browsers
      dataTransfer = e.originalEvent.dataTransfer
    }
    else {
      throw "No clipboardData support"
    }

    // x and y coordinates of dropped item
    x = e.clientX
    y = e.clientY
    var file = dataTransfer.files[0]

    // look for images
    if (file.type.match('image.*')) {
      var reader = new FileReader()
      reader.onload = (function(e) {
        var result = e.target.result
        var img = document.createElement('img')
        img.src = result
        maxWidth = this.$element.width() || 500
        scaleFactor = 2
        //scaleFactor = 1
        //if (window.isRetina && window.isRetina()) {
        //  scaleFactor = 2
        //}

        //Insert the image at the carat
        insert = function(dataUrl, width, height, isResized) {

          //console.log('dataUrl', dataUrl)
          //console.log('scaleFactor', scaleFactor, isResized, maxWidth, width, height)
          this.log('image inserted')
          result = dataUrl
          if (this.options.imageWidth == 'absolute') {
            img = "<img tabindex=\"0\" style=\"width: " + width + "px; max-width: 100%;\" src=\"" + result + "\">"
          }
          else {
            img = "<img tabindex=\"0\" style=\"width: 100%; max-width: " + width + "px;\" src=\"" + result + "\">"
          }

          if (document.caretPositionFromPoint) {
            var pos = document.caretPositionFromPoint(x, y)
            range = document.createRange();
            range.setStart(pos.offsetNode, pos.offset)
            range.collapse()
            range.insertNode(img)
          }
          else if (document.caretRangeFromPoint) {
            range = document.caretRangeFromPoint(x, y)
            range.insertNode(img)
          }
          else {
            console.log('could not find carat')
          }
        }

        // resize if to big
        App.ImageService.resize(img.src, maxWidth, 'auto', scaleFactor, 'image/jpeg', 'auto', insert)
      })
      reader.readAsDataURL(file)
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

  // max length check
  Plugin.prototype.maxLengthOk = function(typeAhead) {
    if ( !this.options.maxlength ) {
      return true
    }
    var length = this.$element.text().length
    if (typeAhead) {
      length = length + typeAhead
    }
    this.log('maxLengthOk', length, this.options.maxlength)
    if ( length > this.options.maxlength ) {
      this.log('maxLengthOk, text too long')

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
    if ( (!text_plain || text_plain == '') && !this.$element.find('img').get(0) ) {
      return text_plain
    }
    return this.$element.html().trim()
  }

  // log method
  Plugin.prototype.log = function() {
    if (App && App.Log) {
      App.Log.debug('contenteditable', arguments)
    }
    if (this.options.debug) {
      console.log(this._name, arguments)
    }
  }

  // paste some content
  Plugin.prototype.paste = function(string) {
    var isIE11 = !!window.MSInputMethodContext && !!document.documentMode;

    // IE <= 10
    if (document.selection && document.selection.createRange) {
      var range = document.selection.createRange()
      if (range.pasteHTML) {
        range.pasteHTML(string)
      }
    }
    // IE == 11
    else if (isIE11 && document.getSelection) {
      var range = document.getSelection().getRangeAt(0)
      var nnode = document.createElement('div')
          range.surroundContents(nnode)
          nnode.innerHTML = string
    }
    else {
      document.execCommand('insertHTML', false, string)
    }
  }

  $.fn[pluginName] = function (options) {
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
    if (!plugin) {
      return
    }
    return plugin.value()
  }

}(jQuery));