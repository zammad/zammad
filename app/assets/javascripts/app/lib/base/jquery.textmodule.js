(function ($, window, undefined) {

/*
# mode: textonly/richtext / disable b/i/u/enter + strip on paste
# pasteOnlyText: true
# maxlength: 123
# multiline: true / disable enter + strip on paste
# placeholder: 'some placeholder'
#
*/

  var pluginName = 'textmodule',
  defaults = {
    debug: false
  }

  function Plugin(element, options) {
    this.element    = element
    this.$element   = $(element)

    this.options    = $.extend({}, defaults, options)

    this._defaults   = defaults
    this._name       = pluginName
    this._fixedWidth = true

    this.collection = []
    this.active     = false
    this.buffer     = ''
    this.oldElementText = ''

    // check if ce exists
    if ( $.data(element, 'plugin_ce') ) {
      this.ce = $.data(element, 'plugin_ce')
    }

    this.init()
  }

  Plugin.prototype.init = function () {
    this.renderBase()
    this.bindEvents()
  }

  Plugin.prototype.bindEvents = function () {
    this.$element.on('keydown', this.onKeydown.bind(this))
    this.$element.on('keyup', this.onKeyup.bind(this))
    // using onInput event to trigger onKeyPress behavior
    // since keyPress doesn't work on Mobile Chrome / Android
    this.$element.on('input', this.onKeypress.bind(this))
    this.$element.on('focus', this.onFocus.bind(this))
  }

  Plugin.prototype.onFocus = function (e) {
    this.close()
  }

  Plugin.prototype.onKeydown = function (e) {
    // Saves the old element text for some special situations.
    this.oldElementText = this.$element.text()

    // navigate through item
    if (this.isActive()) {
      // esc
      if (e.keyCode === 27) {
        e.preventDefault()
        e.stopPropagation()
        this.close()
        return
      }

      // enter
      if (e.keyCode === 13) {
        e.preventDefault()
        e.stopPropagation()
        var elem = this.$widget.find('.dropdown-menu li.is-active')[0]

        // as fallback use hovered element
        if (!elem) {
          elem = this.$widget.find('.dropdown-menu li:hover')[0]
        }

        // as fallback first element
        if (!elem) {
          elem = this.$widget.find('.dropdown-menu li:first-child')[0]
        }
        this.take(elem)
        return
      }

      // arrow keys left/right
      if (e.keyCode === 37 || e.keyCode === 39) {
        e.preventDefault()
        e.stopPropagation()
        return
      }

      // up or down
      if (e.keyCode === 38 || e.keyCode === 40) {
        e.preventDefault()
        e.stopPropagation()
        var active = this.$widget.find('.dropdown-menu li.is-active')
        active.removeClass('is-active')

        if (e.keyCode == 38 && active.prev().length) {
          active = active.prev()
        }
        else if (e.keyCode == 40 && active.next().length) {
          active = active.next()
        }

        active.addClass('is-active')

        var menu = this.$widget.find('.dropdown-menu')

        if (!active.get(0)) {
          return
        }
        if (active.position().top < 0) {
          // scroll up
          menu.scrollTop( menu.scrollTop() + active.position().top )
        }
        else if ( active.position().top + active.height() > menu.height() ) {
          // scroll down
          var invisibleHeight = active.position().top + active.height() - menu.height()
          menu.scrollTop( menu.scrollTop() + invisibleHeight )
        }
      }
    }

    // esc
    if (e.keyCode === 27) {
      this.close()
    }

    // reduce buffer, in case close it
    // backspace
    if (e.keyCode === 8 && !( e.ctrlKey || e.metaKey ) && this.buffer) {

      var trigger = this.findTrigger(this.buffer)
      // backspace + buffer === :: -> close textmodule
      if (trigger && trigger.trigger === this.buffer) {
        this.close(true)
        e.preventDefault()
        return
      }

      // reduce buffer and show new result
      var length   = this.buffer.length
      this.buffer = this.buffer.substr(0, length-1)
      this.log('BS backspace', this.buffer)
      this.result(trigger)
    }
  }

  Plugin.prototype.onKeyup = function (e) {

    // in normal use we make sure that mentions
    // which has no text anymore get deleted
    if (e.keyCode == 8 && !this.buffer) {
      this.removeInvalidMentions()
    }
  }

  Plugin.prototype.onKeypress = function (e) {
    this.log('BUFF', this.buffer, e.keyCode, String.fromCharCode(e.which))
    // gets the character and keycode from event
    // this event does not have keyCode and which value set
    // so we take char and set those values to not break the flow
    // if originalEvent.data is null that means a non char key is pressed like delete, space
    if(e.originalEvent && e.originalEvent.data) {
      var char = e.originalEvent.data
      var keyCode = char.charCodeAt(0)
      e.keyCode = e.which = keyCode
    }

    // ignore invalid key codes if search is opened (issue #3637)
    if (this.isActive() && e.keyCode === undefined) {

      // Check if the trigger still exists in the new text, after a special key was pressed, otherwise
      //  close the collection.
      var indexOfBuffer = this.oldElementText.indexOf(this.buffer)
      var trigger = this.findTrigger(this.buffer)

      if (this.buffer && indexOfBuffer !== -1 && trigger) {
        foundCurrentBuffer = this.$element.text().substr(indexOfBuffer, this.buffer.length)

        if ( this.$element.text().substr(indexOfBuffer, trigger.trigger.length) !== trigger.trigger ) {
          this.close(true)
        }

        // Check on how many characters the trigger needs to be reduced, in the case it's not the same.
        else if ( foundCurrentBuffer !== this.buffer ) {
          var existingLength = 0
          for (var i = 0; i < this.buffer.length; i++) {
            if (this.buffer.charAt(i) !== foundCurrentBuffer.charAt(i)) {
              existingLength = i
              break
            }
          }

          this.buffer = this.buffer.substr(0, existingLength)
          this.result(trigger)
        }
      }
      return
    }

    // skip on shift + arrow_keys
    if (_.contains([16, 37, 38, 39, 40], e.keyCode)) return

    // enter
    if (e.keyCode === 13) {
      this.buffer = ''
      return
    }

    var newChar = String.fromCharCode(e.which)
    // observe other keys
    if (this.hasAvailableTriggers(this.buffer)) {
      if(this.hasAvailableTriggers(this.buffer + newChar)) {
        this.buffer = this.buffer + newChar
      } else if (!this.findTrigger(this.buffer)) {
        this.buffer = ''
      }
    }

    // oberserve first :
    if (!this.buffer && this.hasAvailableTriggers(newChar)) {
      this.buffer = this.buffer + newChar
    }

    var trigger = this.findTrigger(this.buffer)
    if (trigger) {
      this.log('BUFF HINT', this.buffer, this.buffer.length, e.which, String.fromCharCode(e.which))

      if (!this.isActive()) {
        this.open()
      }

      this.result(trigger)
    }
  }

  // remove invalid mentions
  Plugin.prototype.removeInvalidMentions = function() {
    this.$element.find('a[data-mention-user-id]').each(function() {
      if ($(this).text() != '') return true

      $(this).remove()
    })
  }

  // check if at least one trigger is available with the given prefix
  Plugin.prototype.hasAvailableTriggers = function(prefix) {
    var result = _.find(this.helpers, function(helper) {
      var trigger = helper.trigger
      return trigger.substr(0, prefix.length) == prefix.substr(0, trigger.length)
    })

    return result != undefined
  }

  // find a matching trigger
  Plugin.prototype.findTrigger = function(string) {
    return _.find(this.helpers, function(helper) {
      return helper.trigger == string.substr(0, helper.trigger.length)
    })
  }

  // create base template
  Plugin.prototype.renderBase = function() {
    this.$element.after('<div class="shortcut dropdown dropdown--actions"><ul class="dropdown-menu text-modules-box"></ul></div>')
    this.$widget = this.$element.next()
    this.$widget.on('mousedown', 'li', $.proxy(this.onEntryClick, this))
    this.$widget.on('mouseenter', 'li', $.proxy(this.onMouseEnter, this))
  }

  // set height of widget
  Plugin.prototype.movePosition = function() {
    if (!this._position) return
    var height         = this.$element.outerHeight() + 2
    var widgetHeight   = this.$widget.find('ul').height() //+ 60 // + height
    var rtl            = document.dir == 'rtl'
    var top            = -( widgetHeight + height ) + this._position.top
    var start          = this._position.left - 6
    var availableWidth = this.$element.innerWidth()
    var width          = this.$widget.find('.dropdown-menu').width()

    if(rtl){
      start = availableWidth - start
    }

    // position the element further left if it would break out of the textarea width
    if (start + width > availableWidth) {
      start = availableWidth - width
    }

    var css = {
      top: top
    }

    css[rtl ? 'right' : 'left'] = start

    this.$widget.css(css)
  }

  // set position of widget
  Plugin.prototype.updatePosition = function() {
    this.$widget.find('.dropdown-menu').scrollTop(300)
    if (!this.$element.is(':visible')) return

    // get cursor position
    var marker = '<span id="js-cursor-position"></span>'
    var range = this.getFirstRange();
    var clone = range.cloneRange()
    clone.pasteHtml(marker)
    this._position = $('#js-cursor-position').position()
    $('#js-cursor-position').remove()
    if (!this._position) return

    // set position of widget
    this.movePosition()
  }

  // open widget
  Plugin.prototype.open = function() {
    this.active = true
    this.updatePosition()
    this.renderBase()
    this.$widget.addClass('open')
    $(window).on('click.textmodule', $.proxy(this.close, this))
  }

  // close widget
  Plugin.prototype.close = function(cutInput) {
    this.$widget.removeClass('open')
    if ( cutInput && this.active ) {
      this.cutInput(true)
    }
    this.buffer = ''
    this.active = false
    this.$widget.remove()
    $(window).off('click.textmodule')
  }

  // check if widget is active/open
  Plugin.prototype.isActive = function() {
    return this.active
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
    else if (document.queryCommandSupported && document.queryCommandSupported('insertHTML')) {
      if(!!window.chrome) { // Is Chrome-like browser? It will eat up the single trailing space!
        range = document.getSelection().getRangeAt(0)

        var walker         = document.createTreeWalker(document.body, NodeFilter.SHOW_ALL);
        walker.currentNode = range.startContainer;
        var previousNode   = walker.previousNode()

        if(previousNode && !range.startContainer.previousSibling && ['<p></p>', '<div></div>'].includes(previousNode.outerHTML)) {
          document.execCommand('insertHTML', false, "<br><br>")
        }

        if(range && range.endContainer.textContent && range.endContainer.textContent.match(/(?<=\S) $/)) {
          document.execCommand('insertHTML', false, '&nbsp;')
        }
      }

      document.execCommand('insertHTML', false, string)
    }
    else {
      var sel = rangy.getSelection();
      if (!sel.rangeCount) return

      var range = sel.getRangeAt(0);
      range.collapse(false);
      $('<div>').append(string).contents().each(function() {
        range.insertNode($(this).get(0));
        range.collapseAfter($(this).get(0));
      })
      sel.setSingleRange(range);
    }
  }

  // cut some content
  Plugin.prototype.cut = function(string) {
    var range = this.getFirstRange();
    if (!range) return
    /*
    var sel = window.getSelection()
    if ( !sel || sel.rangeCount < 1) {
      return
    }
    var range = sel.getRangeAt(0)
    */
    var clone = range.cloneRange()

    // improve error handling
    start = range.startOffset - string.length
    if (start < 0) {
      start = 0
    }

    //this.log('CUT FOR', string, "-"+clone.toString()+"-", start, range.startOffset)
    clone.setStart(range.startContainer, start)
    clone.setEnd(range.startContainer, range.startOffset)
    clone.deleteContents()
  }

  Plugin.prototype.onMouseEnter = function(event) {
    this.$widget.find('.is-active').removeClass('is-active')
    $(event.currentTarget).addClass('is-active')
  }

  Plugin.prototype.onEntryClick = function(event) {
    event.preventDefault()
    this.take(event.currentTarget)
  }

  // select text module and insert into text
  Plugin.prototype.take = function(elem) {
    if (!elem) {
      this.close(true)
      return
    }

    var trigger = this.findTrigger(this.buffer)

    if (trigger) {
      var _this     = this;

      var form_id = this.$element.closest('form').find('[name=form_id]').val()

      trigger.renderValue(this, elem, function(text, attachments) {
        _this.cutInput()
        _this.paste(text)
        _this.close(true)

        App.Event.trigger('ui::ticket::addArticleAttachent', {
          attachments: attachments,
          form_id: form_id
        })
      })
    }
  }

  Plugin.prototype.getFirstRange = function() {
    var sel = rangy.getSelection();
    return sel.rangeCount ? sel.getRangeAt(0) : null;
  }

  // cut out search string from text
  Plugin.prototype.cutInput = function() {
    if (!this.buffer) return
    if (!this.$element.text()) return
    this.cut(this.buffer)
    this.buffer = ''
  }

  // render result
  Plugin.prototype.result = function(trigger) {
    if (!trigger) return

    var term      = this.buffer.substr(trigger.trigger.length, this.buffer.length)
    trigger.renderResults(this, term)
  }

  Plugin.prototype.emptyResultsContainer = function() {
    this.$widget.find('ul').empty()
  }

  Plugin.prototype.appendResults = function(collection) {
    this.$widget.find('ul').append(collection).scrollTop(9999)
    this.afterResultRendering()
  }

  Plugin.prototype.afterResultRendering = function() {
    // keep the width of the dropdown the same even when longer items got filtered out
    if(this._fixedWidth){
      var elem = this.$widget.find('ul')

      var currentMinWidth = parseInt(elem.css('min-width'))
      var realWidth       = elem.width()

      if(!currentMinWidth || realWidth > currentMinWidth) {
        elem.css('min-width', realWidth + 'px')
      }
    }

    this.movePosition()
  }

  // log method
  Plugin.prototype.log = function() {
    if (App && App.Log) {
      App.Log.debug(this._name, arguments)
    }
    if (this.options.debug) {
      console.log(this._name, arguments)
    }
  }

  $.fn[pluginName] = function (options) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName, new Plugin(this, options))
      }
    });
  }

  function Collection() {}

  Collection.renderValue = function(textmodule, elem, callback) {
    var id   = $(elem).data('id')
    var item = _.find(textmodule.collection, function(elem) { return elem.id == id })

    if (!item) return

    callback(item.content, [])
  }

  function matchItemWithRegExp(item, regex) {
    return (item.name && item.name.match(regex)) || (item.keywords && item.keywords.match(regex))
  }

  function compareItem(a, b) {
    if (a.name < b.name) return 1;
    if (a.name > b.name) return -1;
    return 0;
  }

  Collection.renderResults = function(textmodule, term) {
    var reg     = new RegExp(term, 'i')
    var regFull = new RegExp('\\b' + term + '\\b', 'i')
    var result  = textmodule.collection.filter(function(item) {
      return matchItemWithRegExp(item, reg) && !matchItemWithRegExp(item, regFull)
    })
    var resultFull = textmodule.collection.filter(function(item) {
      return matchItemWithRegExp(item, regFull)
    })
    result.sort(compareItem)
    if (resultFull.length) {
      resultFull.sort(compareItem)
      result = result.concat(resultFull)
    }

    textmodule.emptyResultsContainer()

    var elements = result.map(function(elem, index, array){
      var element = $('<li>')
        .attr('data-id', elem.id)
        .text(elem.name)
        .addClass('u-clickable u-textTruncate')

      if (index == array.length-1) {
        element.addClass('is-active')
      }

      if (elem.keywords) {
        element.append($('<kbd>').text(elem.keywords))
      }

      return element
    })

    textmodule.appendResults(elements)
  }

  Collection.trigger = '::'

  function KbAnswer() {}

  KbAnswer.renderValue = function(textmodule, elem, callback) {
    textmodule.emptyResultsContainer()

    var element = $('<li>').text(App.i18n.translateInline('Please wait…'))
    textmodule.appendResults(element)

    var form_id = textmodule.$element.closest('form').find('[name=form_id]').val()

    App.Ajax.request({
      id:   'textmoduleKbAnswer',
      type: 'GET',
      url:  $(elem).data('url'),
      success: function(data, status, xhr) {
        App.Collection.loadAssets(data.assets)

        var translation = App.KnowledgeBaseAnswerTranslation.find($(elem).data('id'))

        var body = translation.content().bodyWithPublicURLs()

        App.Ajax.request({
          id:   'textmoduleKbAnswerAttachments',
          type: 'POST',
          data: JSON.stringify({
            form_id: form_id
          }),
          url:  translation.parent().generateURL('/attachments/clone_to_form'),
          success: function(data, status, xhr) {
            App.Utils.htmlImage2DataUrlAsync(body, function(output){
              callback(output, data.attachments)
            })
          },
          error: function(xhr) {
            callback('')
          }
        })
      },
      error: function(xhr) {
        callback('')
      }
    })
  }

  KbAnswer.renderResults = function(textmodule, term) {
    textmodule.emptyResultsContainer()

    // skip in admin interface (ticket is needed)
    if (!textmodule.searchCondition) {
      return
    }
    if(!term) {
      var element = $('<li>').text(App.i18n.translateInline('Start typing to search in Knowledge Base…'))
      textmodule.appendResults(element)

      return
    }

    var element = $('<li>').text(App.i18n.translateInline('Loading…'))
    textmodule.appendResults(element)

    App.Delay.set(function() {
      App.Ajax.request({
        id:   'textmoduleKbAnswer',
        type: 'POST',
        url:  App.Config.get('api_path') + '/knowledge_bases/search',
        data: JSON.stringify({
          'query':             term,
          'flavor':            'agent',
          'index':             'KnowledgeBase::Answer::Translation',
          'url_type':          'agent',
          'highlight_enabled': false,
          'include_locale': true,
        }),
        processData: true,
        success: function(data, status, xhr) {
          textmodule.emptyResultsContainer()

          var items = data
            .result
            .map(function(elem) {
              if(result = _.find(data.details, function(detailElem) { return detailElem.type == elem.type && detailElem.id == elem.id })) {
                return {
                  'category': result.subtitle,
                  'name':     result.title,
                  'value':    elem.id,
                  'url':      result.url
                }
              }
            })
            .filter(function(elem){ return elem != undefined })
            .map(function(elem, index, array) {
              var element = $('<li>')
                .attr('data-id',  elem.value)
                .attr('data-url', elem.url)
                .addClass('u-clickable u-textTruncate with-category')

              element.append($('<small>').text(elem.category))
              element.append('<br>')
              element.append($('<span>').text(elem.name))

              if (index == array.length-1) {
                element.addClass('is-active')
              }

              return element
            })

          if(items.length == 0) {
            items.push($('<li>').text(App.i18n.translateInline('No results found')))
          }

          textmodule.appendResults(items)
        }
      })
    }, 200, 'textmoduleKbAnswerDelay', 'textmodule')
  }

  KbAnswer.trigger = '??'

  function Mention() {}

  Mention.renderValue = function(textmodule, elem, callback) {
    textmodule.emptyResultsContainer()

    var element = $('<li>').text(App.i18n.translateInline('Please wait…'))
    textmodule.appendResults(element)

    var form_id = textmodule.$element.closest('form').find('[name=form_id]').val()

    var user_id = $(elem).data('id')
    var user    = App.User.find(user_id)
    if (!user) {
      return callback('')
    }

    fqdn      = App.Config.get('fqdn')
    http_type = App.Config.get('http_type')

    $replace = $('<a></a>', {
      href: http_type + '://' + fqdn + '/' + user.uiUrl(),
      'data-mention-user-id': user_id,
      text: user.firstname + ' ' + user.lastname
    })

    callback($replace[0].outerHTML)
  }

  Mention.renderResults = function(textmodule, term) {
    textmodule.emptyResultsContainer()

    // skip in admin interface (ticket is needed)
    if (!textmodule.searchCondition) {
      return
    }
    if(!term) {
      var element = $('<li>').text(App.i18n.translateInline('Start typing to search for users…'))
      textmodule.appendResults(element)

      return
    }

    var element = $('<li>').text(App.i18n.translateInline('Loading…'))
    textmodule.appendResults(element)

    App.Delay.set(function() {
      items = []

      if (textmodule.searchCondition.group_id) {
        App.Mention.searchUser(term, textmodule.searchCondition.group_id, function(data) {
          textmodule.emptyResultsContainer()

          activeSet = false
          $.each(data.record_ids, function(index, user_id) {
            user = App.User.find(user_id)
            if (!user) return true
            if (!user.active) return true

            item = $('<li>', {
              'data-id': user_id,
              text: user.firstname + ' ' + user.lastname + ' <' + user.email + '>'
            })
            if (!activeSet) {
              activeSet = true
              item.addClass('is-active')
            }

            items.push(item)
          })

          if(items.length == 0) {
            items.push($('<li>').text(App.i18n.translateInline('No results found')))
          }

          textmodule.appendResults(items)
        })
      }
      else {
        textmodule.emptyResultsContainer()
        items.push($('<li>').text(App.i18n.translateInline('Before you mention a user, please select a group.')))
        textmodule.appendResults(items)
      }
    }, 200, 'textmoduleMentionDelay', 'textmodule')
  }

  Mention.trigger = '@@'

  Plugin.prototype.helpers = [Collection, KbAnswer, Mention]

}(jQuery, window));
