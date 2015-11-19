class Widget
  constructor: ->

    # bind on key down
    # if ctrl+alt+t is pressed, enable translation_inline and fire ui:rerender
    $(document).on('keydown', (e) =>
      if e.altKey && e.ctrlKey && e.keyCode is 84
        if @active
          @disable()
          @active = false
        else
          @enable()
          @active = true
    )

  enable: ->
    App.Config.set( 'translation_inline', true )
    App.Event.trigger('ui:rerender')

  disable: ->
    App.Config.set( 'translation_inline', false )
    App.Event.trigger('ui:rerender')

App.Config.set( 'translation_inline', Widget, 'Widgets' )