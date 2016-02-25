class App.KeyboardShortcutWidget extends Spine.Module
  @include App.LogInclude

  constructor: ->
    @observerKeys()

  observerKeys: =>
    #jQuery.hotkeys.options.filterInputAcceptingElements = false
    navigationHotkeys = 'alt+ctrl'
    areas = App.Config.get('keyboard_shortcuts')
    for area in areas
      for item in area.content
        for shortcut in item.shortcuts
          modifier = ''
          if shortcut.hotkeys
            modifier += navigationHotkeys
          if shortcut.key
            if modifier isnt ''
              modifier += '+'
            modifier += shortcut.key
            if shortcut.callback
              @log 'debug', 'bind for', modifier
              $(document).bind('keydown', modifier, shortcut.callback)

App.Config.set('keyboard_shortcuts', App.KeyboardShortcutWidget, 'Widgets')
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
              callback: ->
                window.location.hash = '#dashboard'
            }
            {
              key: 'o'
              hotkeys: true
              description: 'Overviews'
              callback: ->
                window.location.hash = '#ticket/view'
            }
            {
              key: 's'
              hotkeys: true
              description: 'Search'
              callback: ->
                $('#global-search').focus()
            }
            {
              key: 'n'
              hotkeys: true
              description: 'New Ticket'
              callback: ->
                window.location.hash = '#ticket/create'
            }
            {
              key: 'e'
              hotkeys: true
              description: 'Logout'
              callback: ->
                window.location.hash = '#logout'
            }
            {
              key: 'h'
              hotkeys: true
              description: 'List of shortcuts'
              callback: ->
                if window.location.hash is '#keyboard_shortcuts'
                  App.Event.trigger('keyboard_shortcuts_close')
                  return
                window.location.hash = '#keyboard_shortcuts'
            }
            {
              key: 'x'
              hotkeys: true
              description: 'Close current tab'
              callback: ->
                $('#navigation .tasks .is-active .js-close').click()
            }
            {
              key: 'tab'
              hotkeys: true
              description: 'Next in tab'
              callback: ->
                if $('#navigation .tasks .is-active').get(0)
                  if $('#navigation .tasks .is-active').next().get(0)
                    $('#navigation .tasks .is-active').next().find('div').first().click()
                    return
                $('#navigation .tasks .task').first().find('div').first().click()
            }
            {
              key: 'shift+tab'
              hotkeys: true
              description: 'Previous tab'
              callback: ->
                if $('#navigation .tasks .is-active').get(0)
                  if $('#navigation .tasks .is-active').prev().get(0)
                    $('#navigation .tasks .is-active').prev().find('div').first().click()
                    return
                $('#navigation .tasks .task').last().find('div').first().click()
            }
            {
              key: 'return'
              hotkeys: true
              description: 'Confirm/submit dialog'
              callback: ->

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
              callback: ->
                $('.active.content .article-new .articleNewEdit-body').first().focus()
            }
            {
              key: 'r'
              hotkeys: true
              description: 'Reply to last article'
              callback: ->
                lastArticleWithReply = $('.active.content .ticket-article .icon-reply').last()
                lastArticleWithReplyAll = lastArticleWithReply.parent().find('.icon-reply-all')
                if lastArticleWithReplyAll.get(0)
                  lastArticleWithReplyAll.click()
                  return
                lastArticleWithReply.click()
            }
            #{
            #  key: 'm'
            #  hotkeys: true
            #  description: 'Open macro selection'
            #  callback: ->
            #    window.location.hash = '#ticket/create'
            #}
            {
              key: 'c'
              hotkeys: true
              description: 'Update as closed'
              callback: ->
                return if !$('.active.content .edit').get(0)
                $('.active.content .edit [name="state_id"]').val(4)
                $('.active.content .js-attributeBar .js-submit').first().click()
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
              hotkeys: true
              description: 'Format as _underlined_'
            }
            {
              key: 'b'
              hotkeys: true
              description: 'Format as |bold|'
            }
            {
              key: 'i'
              hotkeys: true
              description: 'Format as ||italic||'
            }
            {
              key: 't'
              hotkeys: true
              description: 'Format as //strikethrough//'
            }
            {
              key: 'f'
              hotkeys: true
              description: 'Removes the formatting'
            }
            {
              key: 'z'
              hotkeys: true,
              description: 'Inserts a horizontal rule'
            }
            {
              key: 'l'
              hotkeys: true,
              description: 'Format as unordered list'
            }
            {
              key: 'k'
              hotkeys: true,
              description: 'Format as ordered list'
            }
            {
              key: '1'
              hotkeys: true,
              description: 'Format as h1 heading'
            }
            {
              key: '2'
              hotkeys: true,
              description: 'Format as h2 heading'
            }
            {
              key: '3'
              hotkeys: true,
              description: 'Format as h3 heading'
            }
            {
              key: 'w'
              hotkeys: true,
              description: 'Removes any hyperlink'
            }
          ]
        }
      ]
    }
  ]
)
