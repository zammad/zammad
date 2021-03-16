class App.KeyboardShortcutModal extends App.ControllerModal
  authenticateRequired: true
  large: true
  head: 'Keyboard Shortcuts'
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  constructor: ->
    super
    @controllerBind('keyboard_shortcuts_close', @close)

  content: ->
    App.view('keyboard_shortcuts')(
      areas: App.Config.get('keyboard_shortcuts')
      magicKey: App.Browser.magicKey()
      hotkeys: App.Browser.hotkeys().split('+').reverse()
    )

  exists: =>
    return true if @el.parents('html').length > 0
    false

  onClosed: ->
    return if window.location.hash isnt '#keyboard_shortcuts'
    window.history.back()

class App.KeyboardShortcutWidget extends App.Controller
  @include App.LogInclude

  constructor: ->
    super
    @observerKeys()
    @lastKey = undefined

    $(document).keyup((e) =>
      return if e.keyCode isnt 27
      @lastKey = undefined
    )

  observerKeys: =>
    $(document).unbind('keydown.shortcuts')
    navigationHotkeys = App.Browser.hotkeys()

    areas = App.Config.get('keyboard_shortcuts')
    for area in areas
      for item in area.content
        for shortcut in item.shortcuts
          do (shortcut) =>
            modifier = ''
            if shortcut.hotkeys
              modifier += navigationHotkeys
            if shortcut.key
              if modifier isnt ''
                modifier += '+'
              modifier += shortcut.key
              if shortcut.callback
                @log 'debug', 'bind for', modifier
                $(document).bind('keydown.shortcuts', modifier, (e) =>
                  e.preventDefault()
                  if @lastKey && @lastKey.modifier is modifier && @lastKey.time + 5500  > new Date().getTime()
                    @lastKey.count += 1
                    @lastKey.time = new Date().getTime()
                  else
                    @lastKey =
                      modifier: modifier
                      count: 1
                      time: new Date().getTime()
                  shortcut.callback(shortcut, @lastKey, modifier)
                )

    @controllerBind('global-shortcut', (e) ->
      for area in areas
        for item in area.content
          for shortcut in item.shortcuts
            if shortcut.globalEvent is e
              shortcut.callback(shortcut)
    )

App.Config.set('keyboard_shortcuts', App.KeyboardShortcutWidget, 'Plugins')
App.Config.set(
  'keyboard_shortcuts',
  [
    {
      headline: 'Navigation'
      location: 'left'
      content: [
        {
          where: 'Used anywhere'
          shortcuts: [
            {
              key: 'd'
              hotkeys: true
              description: 'Dashboard'
              globalEvent: 'dashboard'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#dashboard'
            }
            {
              key: 'o'
              hotkeys: true
              description: 'Overviews'
              globalEvent: 'overview'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#ticket/view'
            }
            {
              key: 's'
              hotkeys: true
              description: 'Search'
              globalEvent: 'search'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('#global-search').focus()
            }
            {
              key: 'a'
              hotkeys: true
              description: 'Notifications'
              globalEvent: 'notification'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                $('#navigation .js-toggleNotifications').click()
            }
            {
              key: 'n'
              hotkeys: true
              description: 'New Ticket'
              globalEvent: 'new-ticket'
              callback: ->
                $('#global-search').blur()
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#ticket/create'
            }
            {
              key: 'e'
              hotkeys: true
              description: 'Logout'
              globalEvent: 'logout'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#logout'
            }
            {
              key: 'h'
              hotkeys: true
              description: 'List of shortcuts'
              globalEvent: 'list-of-shortcuts'
              callback: =>
                if window.location.hash is '#keyboard_shortcuts'
                  App.Event.trigger('keyboard_shortcuts_close')
                  return
                if @dialog && @dialog.exists()
                  @dialog.close()
                  @dialog = false
                  return
                @dialog = new App.KeyboardShortcutModal()
            }
            {
              key: 'w'
              hotkeys: true
              description: 'Close current tab'
              globalEvent: 'close-current-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('#navigation .tasks .is-active .js-close').click()
            }
            {
              key: 'tab'
              hotkeys: true
              description: 'Next in tab'
              globalEvent: 'next-in-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                scollIfNeeded = (element) ->
                  return if !element
                  return if !element.get(0)
                  element.get(0).scrollIntoView(false)
                current = $('#navigation .tasks .is-active')
                if current.get(0)
                  next = current.next()
                  if next.get(0)
                    next.find('div').first().click()
                    scollIfNeeded(next)
                    return
                prev = $('#navigation .tasks .task').first()
                if prev.get(0)
                  prev.find('div').first().click()
                  scollIfNeeded(prev)
            }
            {
              key: 'shift+tab'
              hotkeys: true
              description: 'Previous tab'
              globalEvent: 'previous-in-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                scollIfNeeded = (element) ->
                  return if !element
                  return if !element.get(0)
                  element.get(0).scrollIntoView(true)
                current = $('#navigation .tasks .is-active')
                if current.get(0)
                  prev = current.prev()
                  if prev.get(0)
                    prev.find('div').first().click()
                    scollIfNeeded(prev)
                    return
                last = $('#navigation .tasks .task').last()
                if last.get(0)
                  last.find('div').first().click()
                  scollIfNeeded(last)
            }
            {
              key: 'return'
              hotkeys: true
              description: 'Confirm/submit dialog'
              globalEvent: 'submit'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')

                # check of primary modal exists
                dialog = $('body > div.modal')
                if dialog.get(0)
                  dialog.find('.js-submit').click()
                  return

                # check of local modal exists
                dialog = $('.active.content > div.modal')
                if dialog.get(0)
                  dialog.find('.js-submit').click()
                  return

                # check ticket edit
                dialog = $('.active.content .js-attributeBar .js-submit')
                if dialog.get(0)
                  dialog.first().click()
                  return

                dialog = $('.active.content .js-submit')
                if dialog.get(0)
                  dialog.first().click()
                  return
            }
          ]
        }
        {
          where: 'Used in lists (views and results)'
          shortcuts: [
            {
              key: ['▲', '▼']
              description: 'Move up and down'
            }
            {
              key: ['◀', '▶']
              description: 'Move left and right'
            }
            {
              key: 'enter'
              description: 'Select item',
            }
          ]
        }
        {
          where: 'Used in object views'
          shortcuts: [
            {
              key: '.'
              hotkeys: true
              description: 'Copy current object number (e. g. Ticket#) to clipboard'
              callback: (shortcut, lastKey, modifier) ->
                App.Event.trigger('keyboard_shortcuts_close')
                text = $('.active.content .js-objectNumber').first().data('number') || ''
                if lastKey && lastKey.count is 1
                  clipboard.copy(text)
                  return

                title = $('.active.content .js-objectTitle').first().text()
                if lastKey && lastKey.count is 2
                  if title
                    text += ": #{title}"
                  clipboard.copy(text)
                  return

                url = window.location.toString()
                if lastKey && lastKey.count is 3
                  clipboard.copy(
                    'text/plain': "#{text}: #{title}\n#{url}",
                    'text/html': "<a href=\"#{url}\">#{text}</a>: #{title}"
                  )
            }
            {
              keyPrefix: '2x'
              key: '.'
              hotkeys: true
              description: '...add object title'
            }
            {
              keyPrefix: '3x'
              key: '.'
              hotkeys: true
              description: '...add object link URL'
            }
          ]
        }
      ]
    }
    {
      headline: 'Translations'
      location: 'left'
      content: [
        {
          where: 'Used anywhere (admin only)'
          shortcuts: [
            {
              admin: true
              key: 't'
              hotkeys: true
              description: 'Enable/disable inline translations'
              globalEvent: 'translation-mode'
            }
          ]
        }
      ]
    }
    {
      headline: 'Tickets'
      location: 'right'
      content: [
        {
          where: 'Used when viewing a Ticket'
          shortcuts: [
            {
              key: 'm'
              hotkeys: true
              description: 'Open note box'
              globalEvent: 'article-note-open'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('.active.content .editControls .js-articleTypes [data-value="note"]').click()
                $('.active.content .article-new .articleNewEdit-body').first().focus()
            }
            {
              key: 'g'
              hotkeys: true
              description: 'Reply to last article'
              globalEvent: 'article-reply'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                lastArticleWithReply = $('.active.content .ticket-article .icon-reply').last()
                lastArticleWithReplyAll = lastArticleWithReply.parent().find('.icon-reply-all')
                if lastArticleWithReplyAll.get(0)
                  lastArticleWithReplyAll.click()
                  return
                lastArticleWithReply.click()
            }
            {
              key: 'j'
              hotkeys: true
              description: 'Set article to internal/public'
              globalEvent: 'article-internal-public'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('.active.content .editControls .js-selectInternalPublic').click()
            }
            #{
            #  key: 'm'
            #  hotkeys: true
            #  description: 'Open macro selection'
            #  globalEvent: 'macro-open'
            #  callback: ->
            #    window.location.hash = '#ticket/create'
            #}
            {
              key: 'c'
              hotkeys: true
              description: 'Update as closed'
              globalEvent: 'task-update-close'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                return if !$('.active.content .edit').get(0)
                $('.active.content .edit [name="state_id"]').val(4)
                $('.active.content .js-attributeBar .js-submit').first().click()
            }
            {
              key: ['◀', '▶']
              hotkeys: true
              description: 'Navigate through article'
            }
          ]
        },
        {
          where: 'Used when composing a Ticket article'
          shortcuts: [
            {
              key: '::'
              hotkeys: false
              description: 'Inserts Text module'
              globalEvent: 'richtext-insert-text-module'
            }
            {
              key: '??'
              hotkeys: false
              description: 'Inserts Knowledge Base answer'
              globalEvent: 'richtext-insert-kb-answer'
            }
            {
              key: '@@'
              hotkeys: false
              description: 'Inserts a mention for a user'
              globalEvent: 'richtext-insert-mention-user'
            }
          ]
        }

      ]
    }
    {
      headline: 'Text editing'
      location: 'right'
      content: [
        {
          where: 'Used when composing a text'
          shortcuts: [
            {
              key: 'u'
              magicKey: true
              description: 'Format as _underlined_'
              globalEvent: 'richtext-underline'
            }
            {
              key: 'b'
              magicKey: true
              description: 'Format as |bold|'
              globalEvent: 'richtext-bold'
            }
            {
              key: 'i'
              magicKey: true
              description: 'Format as ||italic||'
              globalEvent: 'richtext-italic'
            }
            {
              key: 's'
              magicKey: true
              description: 'Format as //strikethrough//'
              globalEvent: 'richtext-strikethrough'
            }
            {
              key: 'v'
              magicKey: true
              description: 'Paste from clipboard'
              globalEvent: 'clipboard-paste'
            }
            {
              key: 'v'
              magicKey: true
              shiftKey: true
              description: 'Paste from clipboard (plain text)'
              globalEvent: 'clipboard-paste-plain-text'
            }
            {
              key: 'f'
              hotkeys: true
              description: 'Removes the formatting'
              globalEvent: 'richtext-remove-formating'
            }
            {
              key: 'y'
              hotkeys: true
              description: '...of whole textarea'
              globalEvent: 'richtext-remove-formating-textarea'
            }
            {
              key: 'z'
              hotkeys: true,
              description: 'Inserts a horizontal rule'
              globalEvent: 'richtext-hr'
            }
            {
              key: 'l'
              hotkeys: true,
              description: 'Format as unordered list'
              globalEvent: 'richtext-ul'
            }
            {
              key: 'k'
              hotkeys: true,
              description: 'Format as ordered list'
              globalEvent: 'richtext-ol'
            }
            {
              key: '1'
              hotkeys: true,
              description: 'Format as h1 heading'
              globalEvent: 'richtext-h1'
            }
            {
              key: '2'
              hotkeys: true,
              description: 'Format as h2 heading'
              globalEvent: 'richtext-h2'
            }
            {
              key: '3'
              hotkeys: true,
              description: 'Format as h3 heading'
              globalEvent: 'richtext-h3'
            }
            {
              key: 'x'
              hotkeys: true,
              description: 'Removes any hyperlink'
              globalEvent: 'richtext-remove-hyperlink'
            }
          ]
        }
      ]
    }
  ]
)
