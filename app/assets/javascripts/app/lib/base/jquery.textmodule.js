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
    // using onInput event to trigger onKeyPress behavior
    // since keyPress doesn't work on Mobile Chrome / Android
    this.$element.on('input', this.onKeypress.bind(this))
    this.$element.on('focus', this.onFocus.bind(this))
  }

  Plugin.prototype.onFocus = function (e) {
    this.close()
  }

  Plugin.prototype.onKeydown = function (e) {
    //console.log("onKeydown", this.isActive())
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

        if (e.keyCode == 38 && active.prev().size()) {
          active = active.prev()
        }
        else if (e.keyCode == 40 && active.next().size()) {
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
    if (e.keyCode === 8 && this.buffer) {

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

  Plugin.prototype.onKeypress = function (e) {
    this.log('BUFF', this.buffer, e.keyCode, String.fromCharCode(e.which))

    // gets the character and keycode from event
    // this event does not have keyCode and which value set
    // so we take char and set those values to not break the flow
    // if originalEvent.data is null that means a non char key is pressed like delete, space
    if(e.originalEvent && e.originalEvent.data) {
      var char = e.originalEvent.data;
      var keyCode = char.charCodeAt(0);
      e.keyCode = e.which = keyCode;
    }

    // shift
    if (e.keyCode === 16) return

    // enter
    if (e.keyCode === 13) {
      this.buffer = ''
      return
    }

    // arrow keys
    if (e.keyCode === 37 || e.keyCode === 38 || e.keyCode === 39 || e.keyCode === 40) return

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
    this.$element.after('<div class="shortcut dropdown"><ul class="dropdown-menu text-modules-box"></ul></div>')
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
    else {
      document.execCommand('insertHTML', false, string)
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

    // for chrome, remove also leading space, add it later - otherwice space will be tropped
    if (start) {
      clone.setStart(range.startContainer, start-1)
      clone.setEnd(range.startContainer, start)
      var spacerChar = clone.toString()
      if (spacerChar === ' ') {
        start = start - 1
      }
    }
    //this.log('CUT FOR', string, "-"+clone.toString()+"-", start, range.startOffset)
    clone.setStart(range.startContainer, start)
    clone.setEnd(range.startContainer, range.startOffset)
    clone.deleteContents()

    // for chrome, insert space again
    if (start) {
      if (spacerChar === ' ') {
        this.paste('&nbsp;')
      }
    }
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

  Collection.renderResults = function(textmodule, term) {
    var reg    = new RegExp(term, 'i')
    var result = textmodule.collection.filter(function(item) {
      return (item.name && item.name.match(reg)) || (item.keywords && item.keywords.match(reg))
    })
    result.reverse()

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

    var element = $('<li>').text(App.i18n.translateInline('Please wait...'))
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
            translation.parent().attachments += data.attachments

            App.Utils.htmlImage2DataUrlAsync(body, function(output){
              callback(output, translation.parent().attachments)
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

    if(!term) {
      var element = $('<li>').text(App.i18n.translateInline('Start typing to search in Knowledge Base...'))
      textmodule.appendResults(element)

      return
    }

    var element = $('<li>').text(App.i18n.translateInline('Loading...'))
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

    var element = $('<li>').text(App.i18n.translateInline('Please wait...'))
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

    if(!term) {
      var element = $('<li>').text(App.i18n.translateInline('Start typing to search for users...'))
      textmodule.appendResults(element)

      return
    }

    var element = $('<li>').text(App.i18n.translateInline('Loading...'))
    textmodule.appendResults(element)

    App.Delay.set(function() {
      items = []

      if (textmodule.searchCondition.group_id) {
        App.Mention.searchUser(term, textmodule.searchCondition.group_id, function(data) {
          textmodule.emptyResultsContainer()

          activeSet = false
          $.each(data.user_ids, function(index, user_id) {
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
        items.push($('<li>').text(App.i18n.translateInline('Please select a group first, before you mention a user!')))
        textmodule.appendResults(items)
      }
    }, 200, 'textmoduleMentionDelay', 'textmodule')
  }

  Mention.trigger = '@@'

  Plugin.prototype.helpers = [Collection, KbAnswer, Mention]

}(jQuery, window));
