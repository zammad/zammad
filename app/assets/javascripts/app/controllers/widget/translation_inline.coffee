class Widget extends App.Controller
  constructor: ->
    super
    @rebind()
    App.Event.bind('auth', => @rebind())
    App.Event.bind('i18n:inline_translation', => @toogle())

  rebind: =>
    $(document).off('keydown.translation')

    # only admins can do this
    return if !@permissionCheck('admin.translation')

    # bind on key down
    # if hotkeys+t is pressed, enable translation_inline and fire ui:rerender
    browserHotkeys = App.Browser.hotkeys()
    $(document).on('keydown.translation', (e) =>
      hotkeys = false
      if browserHotkeys is 'ctrl+shift'
        if !e.altKey && e.ctrlKey && !e.metaKey && e.shiftKey
          hotkeys = true
      else
        if e.altKey && e.ctrlKey && !e.metaKey
          hotkeys = true
      if hotkeys && e.keyCode is 84
        e.preventDefault()
        @toogle()
    )

  toogle: =>
    if @active
      $('.translation:focus').trigger('blur')
      @disable()
      @active = false
      return

    @enable()
    @active = true

  enable: ->
    # load in collection if needed
    meta = App.i18n.meta()
    if !@mapLoaded && meta && meta.mapToLoad
      @mapLoaded = true
      App.Translation.refresh(meta.mapToLoad, {clear: true} )

    # enable translation inline
    App.Config.set('translation_inline', true)

    # rerender controllers
    App.Event.trigger('ui:rerender')

    # observe if text has been translated
    $('body')
      .on 'focus.translation', '.translation', (e) ->
        element = $(e.target)
        element.data 'before', element.text()
        element
      .on 'blur.translation', '.translation', (e) ->
        element = $(e.target)
        source = element.attr('title')
        return if !source

        # get new translation
        translation_new = element.text()

        # update translation
        return if element.data('before') is translation_new
        App.Log.debug 'translation_inline', 'translate update', translation_new, 'before', element.data
        element.data 'before', translation_new

        # update runtime translation mapString
        App.i18n.setMap(source, translation_new)

        # replace rest in page
        sourceQuoted = source.replace('\'', '\\\'')
        $(".translation[title='#{sourceQuoted}']").text(translation_new)

        # update permanent translation mapString
        translation = App.Translation.findByAttribute('source', source)
        if translation
          translation.updateAttribute('target', translation_new)
        else
          translation = new App.Translation
          translation.load(
            locale:         App.i18n.get()
            source:         source
            target:         translation_new
            target_initial: ''
          )
          translation.save()

        element

  disable: ->
    $('body').off('focus.translation blur.translation')

    # disable translation inline
    App.Config.set('translation_inline', false)

    # rerender controllers
    App.Event.trigger('ui:rerender')

App.Config.set('translation_inline', Widget, 'Widgets')
