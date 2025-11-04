class App.KeyboardShortcutPlugin extends App.Controller
  @include App.LogInclude
  @hasSelectionWhenShiftWasPressed: undefined

  constructor: ->
    super
    @observerKeys()
    @lastKey = undefined

    $(document).on('keydown', (e) ->
      return if e.keyCode isnt 16
      return if !App.KeyboardShortcutPlugin.hasSelection()

      App.KeyboardShortcutPlugin.hasSelectionWhenShiftWasPressed = true
    )

    $(document).on('keyup', (e) =>
      if e.keyCode is 16
        App.KeyboardShortcutPlugin.hasSelectionWhenShiftWasPressed = false

      return if e.keyCode isnt 27
      @lastKey = undefined
    )

    @controllerBind('toggle-shortcut-layout', @observerKeys)

  @isEnabled: ->
    value = App.LocalStorage.get('keyboardShortcuts')
    return false if value is false
    true

  @isDisabled: ->
    !@isEnabled()

  @toggleShortcutEnable: =>
    if @isDisabled()
      App.LocalStorage.delete('keyboardShortcuts')
    else
      App.LocalStorage.set('keyboardShortcuts', false)

    App.Event.trigger('toggle-shortcut-enable')

  @isInput: ->
    return true if (_.contains(['INPUT', 'TEXTAREA', 'SELECT'], document.activeElement.nodeName) || document.activeElement.getAttribute('contenteditable') == 'true')
    false

  @hasSelection: ->
    return true if App.KeyboardShortcutPlugin.hasSelectionWhenShiftWasPressed
    return window.getSelection().type is 'Range' if window.getSelection
    return document.getSelection().type is 'Range' if document.getSelection
    return document.selection.type is 'Range' if document.selection
    false

  @useOldShortcutLayout: ->
    App.LocalStorage.get('useOldShortcutLayout') is true

  # Awaits the old value in key_array[0] and the new one in key_array[1]; or both in key_array[0]
  @getKeyForLayout: (key_array) ->
    # supports key_array not being an array and instead directly the final value
    return key_array if !Array.isArray(key_array) or key_array.length is 0

    # returns first array value if old shortcut layout was selected or theres only one value in the array
    return key_array[0] if App.KeyboardShortcutPlugin.useOldShortcutLayout() or key_array.length is 1

    # returns second array value for default (new) shortcut layout
    key_array[1]

  @toggleShortcutLayout: =>
    if @useOldShortcutLayout()
      App.LocalStorage.delete('useOldShortcutLayout')
    else
      App.LocalStorage.set('useOldShortcutLayout', true)

    App.Event.trigger('toggle-shortcut-layout')

  observerKeys: =>
    $(document).off('keydown.shortcuts')
    navigationHotkeys = App.Browser.hotkeys()

    areas = App.Config.get('keyboard_shortcuts')
    for area in areas
      for item in area.content
        for shortcut in item.shortcuts
          do (shortcut) =>
            modifier = ''
            if App.KeyboardShortcutPlugin.getKeyForLayout(shortcut.hotkeys)
              modifier += navigationHotkeys
            if shortcut.key
              if modifier isnt ''
                modifier += '+'
              modifier += App.KeyboardShortcutPlugin.getKeyForLayout(shortcut.key)
              if shortcut.callback
                @log 'debug', 'bind for', modifier

                # only ? will not work via {keys: modifier}
                if modifier == '?'
                  $(document).on('keydown.shortcuts', (e) ->
                    return if App.KeyboardShortcutPlugin.isDisabled()
                    return if e.key != '?'
                    return if shortcut.onlyOutsideInputs && App.KeyboardShortcutPlugin.isInput()
                    return if shortcut.onlyWithoutSelection && App.KeyboardShortcutPlugin.hasSelection()
                    e.preventDefault()

                    shortcut.callback(shortcut)
                  )
                  return

                $(document).on('keydown.shortcuts', {keys: modifier}, (e) =>
                  return if App.KeyboardShortcutPlugin.isDisabled()
                  return if shortcut.onlyOutsideInputs && App.KeyboardShortcutPlugin.isInput()
                  return if shortcut.onlyWithoutSelection && App.KeyboardShortcutPlugin.hasSelection()
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

App.Config.set('keyboard_shortcuts', App.KeyboardShortcutPlugin, 'Plugins')
App.Config.set(
  'keyboard_shortcuts',
  [
    {
      headline: __('Navigation')
      location: 'left'
      content: [
        {
          where: __('Used anywhere')
          shortcuts: [
            {
              key: ['d', 'h']
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Dashboard')
              globalEvent: 'dashboard'
              callback: ->
                $('#global-search').trigger('blur')
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#dashboard'
            }
            {
              key: 'o'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Overviews')
              globalEvent: 'overview'
              callback: ->
                $('#global-search').trigger('blur')
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#ticket/view'
            }
            {
              key: 's'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Search')
              globalEvent: 'search'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('#global-search').trigger('focus')
            }
            {
              key: 'a'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Notifications')
              globalEvent: 'notification'
              callback: ->
                $('#global-search').trigger('blur')
                App.Event.trigger('keyboard_shortcuts_close')
                $('#navigation .js-toggleNotifications').trigger('click')
            }
            {
              key: 'n'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('New Ticket')
              globalEvent: 'new-ticket'
              callback: ->
                $('#global-search').trigger('blur')
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#ticket/create'
            }
            {
              key: 'u'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('User menu')
              globalEvent: 'user-menu'
              callback: ->
                $('#global-search').trigger('blur')
                App.Event.trigger('keyboard_shortcuts_close')
                $('#navigation .user .js-action').trigger('click')
            }
            {
              key: ['h', '?']
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('List of shortcuts')
              globalEvent: 'list-of-shortcuts'
              callback: =>
                if window.location.hash is '#keyboard_shortcuts'
                  App.Event.trigger('keyboard_shortcuts_close')
                  return
                if @dialog && @dialog.exists()
                  @dialog.close()
                  @dialog = false
                  return
                @dialog = new App.KeyboardShortcuts()
            }
            {
              key: ['e', 'shift+l']
              keyDisplay: ['e', ['shift', 'l']]
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Logout')
              globalEvent: 'logout'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                window.location.hash = '#logout'
            }
            {
              key: ['w', 'shift+w']
              keyDisplay: ['w', ['shift', 'w']]
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Close current tab')
              globalEvent: 'close-current-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('#navigation .tasks .is-active .js-close').trigger('click')
            }
            {
              key: ['tab', 'shift+right']
              keyDisplay: ['tab', ['shift', '▶']]
              hotkeys: [true, false]
              onlyOutsideInputs: true
              onlyWithoutSelection: true
              description: __('Show next tab')
              globalEvent: 'next-in-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                scrollIfNeeded = (element) ->
                  return if !element
                  return if !element.get(0)
                  element.get(0).scrollIntoView(false)
                current = $('#navigation .tasks .is-active')
                if current.get(0)
                  next = current.next()
                  if next.get(0)
                    next.find('div').first().trigger('click')
                    scrollIfNeeded(next)
                    return
                prev = $('#navigation .tasks .task').first()
                if prev.get(0)
                  prev.find('div').first().trigger('click')
                  scrollIfNeeded(prev)
            }
            {
              key: ['shift+tab', 'shift+left']
              keyDisplay: [['shift', 'tab'], ['shift', '◀']]
              hotkeys: [true, false]
              onlyOutsideInputs: true
              onlyWithoutSelection: true
              description: __('Show previous tab')
              globalEvent: 'previous-in-tab'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                scrollIfNeeded = (element) ->
                  return if !element
                  return if !element.get(0)
                  element.get(0).scrollIntoView(true)
                current = $('#navigation .tasks .is-active')
                if current.get(0)
                  prev = current.prev()
                  if prev.get(0)
                    prev.find('div').first().trigger('click')
                    scrollIfNeeded(prev)
                    return
                last = $('#navigation .tasks .task').last()
                if last.get(0)
                  last.find('div').first().trigger('click')
                  scrollIfNeeded(last)
            }
            {
              key: ['return', 'ctrl+return']
              keyDisplay: ['enter', ['ctrl', 'enter']]
              hotkeys: [true, false]
              description: __('Confirm/submit dialog')
              globalEvent: 'submit'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')

                # check of primary modal exists
                dialog = $('body > div.modal')
                if dialog.get(0)
                  dialog.find('.js-submit').trigger('click')
                  return

                # check of local modal exists
                dialog = $('.active.content > div.modal')
                if dialog.get(0)
                  dialog.find('.js-submit').trigger('click')
                  return

                # check ticket edit
                dialog = $('.active.content .js-attributeBar .js-submit')
                if dialog.get(0)
                  dialog.first().trigger('click')
                  return

                dialog = $('.active.content .js-submit')
                if dialog.get(0)
                  dialog.first().trigger('click')
                  return
            }
          ]
        }
        {
          where: __('Used in lists (views and results)')
          shortcuts: [
            {
              key: [['▲', '▼']]
              description: __('Move up and down')
            }
            {
              key: [['◀', '▶']]
              description: __('Move left and right')
            }
            {
              key: 'enter'
              description: __('Select item'),
            }
          ]
        }
        {
          where: __('Used in object views')
          shortcuts: [
            {
              key: '.'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Copy current object number (e. g. Ticket#) to clipboard')
              callback: (shortcut, lastKey, modifier) ->
                App.Event.trigger('keyboard_shortcuts_close')
                number = $('.active.content .js-objectNumber').first().data('number') || ''
                text = number
                if lastKey && lastKey.count is 1
                  clipboard.writeText(number)
                  return

                title = $('.active.content .js-objectTitle').first().text()
                if lastKey && lastKey.count is 2
                  if title
                    text = "#{number}: #{title}"
                  clipboard.writeText(text)
                  return

                url = window.location.toString()
                if lastKey && lastKey.count is 3

                  # in firefox `new window.ClipboardItem` may not work
                  # https://github.com/zammad/zammad/issues/4492
                  try
                    item = new window.ClipboardItem(
                      {
                        'text/plain': new Blob(
                          ["#{number}: #{title}\n#{url}"],
                          { type: 'text/plain' }
                        ),
                        'text/html': new Blob(
                          ["<a href=\"#{url}\">#{number}</a>: #{title}"],
                          { type: 'text/html' }
                        ),
                      }
                    )
                    clipboard.write([item])
                  catch e
                    text = "#{number}: #{title}\n#{url}"
                    clipboard.writeText(text)
            }
            {
              keyPrefix: '2x'
              key: '.'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('…add object title')
            }
            {
              keyPrefix: '3x'
              key: '.'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('…add object link URL')
            }
          ]
        }
      ]
    }
    {
      headline: __('Translations')
      location: 'left'
      content: [
        {
          where: __('Used anywhere (admin only)')
          shortcuts: [
            {
              admin: true
              key: 't'
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Enable/disable inline translations')
              globalEvent: 'translation-mode'
            }
          ]
        }
      ]
    }
    {
      headline: __('Appearance')
      location: 'left'
      content: [
        {
          where: __('Used anywhere')
          shortcuts: [
            {
              key: 'd'
              hotkeys: false
              onlyOutsideInputs: true
              description: __('Toggle dark mode')
              callback: ->
                return if !App.Session.get()?.permission('user_preferences.appearance')
                App.Event.trigger('ui:theme:toggle-dark-mode')
            }
          ]
        }
      ]
    }
    {
      headline: __('Tickets')
      location: 'right'
      content: [
        {
          where: __('Used when viewing a Ticket')
          shortcuts: [
            {
              key: ['m', 'x']
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Open note box')
              globalEvent: 'article-note-open'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')

                # only trigger note change if note is not already selected (to prevent loss of internal/public state)
                currentType = $('.active.content .article-new [name="type"]').val()
                if currentType != 'note'
                  $('.active.content .editControls .js-articleTypes [data-value="note"]').trigger('click')
                $('.active.content .article-new .articleNewEdit-body').first().trigger('focus')
            }
            {
              key: ['g', 'r']
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Reply to last article')
              globalEvent: 'article-reply'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                lastArticleWithReply = $('.active.content .ticket-article .icon-reply').last()
                lastArticleWithReplyAll = lastArticleWithReply.parent().find('.icon-reply-all')
                if lastArticleWithReplyAll.get(0)
                  lastArticleWithReplyAll.trigger('click')
                  return
                lastArticleWithReply.trigger('click')
            }
            {
              key: ['j', 'i']
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Set article to internal/public')
              globalEvent: 'article-internal-public'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                $('.active.content .editControls .js-selectInternalPublic').trigger('click')
            }
            #{
            #  key: 'm'
            #  hotkeys: [true, false]
            #  onlyOutsideInputs: true
            #  description: __('Open macro selection')
            #  globalEvent: 'macro-open'
            #  callback: ->
            #    window.location.hash = '#ticket/create'
            #}
            {
              key: ['c', 'shift+c']
              keyDisplay: ['c', ['shift', 'c']]
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Update as closed')
              globalEvent: 'task-update-close'
              callback: ->
                App.Event.trigger('keyboard_shortcuts_close')
                return if !$('.active.content .edit').get(0)

                $('.active.content .edit [name="state_id"]').val(4).trigger('change')

                # Waiting for the core workflow to be executed (for example, the pending time field is no longer visible).
                interval = setInterval ->
                  if Object.keys(App.FormHandlerCoreWorkflow.getRequests()).length == 0
                    clearInterval(interval)
                    setTimeout ->
                      $('.active.content .js-attributeBar .js-submit').first().trigger('click')
                    , 100
                , 30
            }
            {
              key: [['◀', '▶']]
              hotkeys: [true, false]
              onlyOutsideInputs: true
              description: __('Navigate through article')
            }
          ]
        },
        {
          where: __('Used when composing a Ticket article')
          shortcuts: [
            {
              key: '::'
              hotkeys: false
              description: __('Inserts text module')
              globalEvent: 'richtext-insert-text-module'
            }
            {
              key: '??'
              hotkeys: false
              description: __('Inserts knowledge base answer')
              globalEvent: 'richtext-insert-kb-answer'
            }
            {
              key: '@@'
              hotkeys: false
              description: __('Inserts a mention for a user')
              globalEvent: 'richtext-insert-mention-user'
            }
          ]
        }

      ]
    }
    {
      headline: __('Text editing')
      location: 'right'
      content: [
        {
          where: __('Used when composing a text')
          shortcuts: [
            {
              key: 'u'
              magicKey: true
              description: __('Format as _underlined_')
              globalEvent: 'richtext-underline'
            }
            {
              key: 'b'
              magicKey: true
              description: __('Format as |bold|')
              globalEvent: 'richtext-bold'
            }
            {
              key: 'i'
              magicKey: true
              description: __('Format as ||italic||')
              globalEvent: 'richtext-italic'
            }
            {
              key: 's'
              magicKey: true
              description: __('Format as //strikethrough//')
              globalEvent: 'richtext-strikethrough'
            }
            {
              key: 'v'
              magicKey: true
              description: __('Paste from clipboard')
              globalEvent: 'clipboard-paste'
            }
            {
              key: 'v'
              magicKey: true
              shiftKey: true
              description: __('Paste from clipboard (plain text)')
              globalEvent: 'clipboard-paste-plain-text'
            }
            {
              key: 'f'
              hotkeys: true
              description: __('Removes the formatting')
              globalEvent: 'richtext-remove-formating'
            }
            {
              key: 'y'
              hotkeys: true
              description: __('…of whole text area')
              globalEvent: 'richtext-remove-formating-textarea'
            }
            {
              key: 'z'
              hotkeys: true,
              description: __('Inserts a horizontal rule')
              globalEvent: 'richtext-hr'
            }
            {
              key: 'l'
              hotkeys: true,
              description: __('Format as unordered list')
              globalEvent: 'richtext-ul'
            }
            {
              key: 'k'
              hotkeys: true,
              description: __('Format as ordered list')
              globalEvent: 'richtext-ol'
            }
            {
              key: '1'
              hotkeys: true,
              description: __('Format as h1 heading')
              globalEvent: 'richtext-h1'
            }
            {
              key: '2'
              hotkeys: true,
              description: __('Format as h2 heading')
              globalEvent: 'richtext-h2'
            }
            {
              key: '3'
              hotkeys: true,
              description: __('Format as h3 heading')
              globalEvent: 'richtext-h3'
            }
            {
              key: 'x'
              hotkeys: true,
              description: __('Removes any hyperlink')
              globalEvent: 'richtext-remove-hyperlink'
            }
          ]
        }
      ]
    }
  ]
)
