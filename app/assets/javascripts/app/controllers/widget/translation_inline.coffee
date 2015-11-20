class Widget extends App.Controller
  constructor: ->
    super

    # only admins can do this
    return if !@isRole('Admin')

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
      .on 'blur.translation', '.translation', (e) =>
        console.log('blur')
        element = $(e.target)
        source = element.attr('title')

        # get new translation
        translation_new = element.text()

        # update translation
        return if element.data('before') is translation_new
        App.Log.debug 'translation_inline', 'translate update', translation_new, 'before', element.data
        element.data 'before', translation_new

        # update runtime translation mapString
        App.i18n.setMap(source, translation_new)

        # replace rest in page
        $(".translation[title='#{source}']").text(translation_new)

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
            initial_target: ''
          )
          translation.save()

        element

  disable: ->
    $('body').off('focus.translation blur.translation')

    # disable translation inline
    App.Config.set('translation_inline', false)

    # rerender controllers
    App.Event.trigger('ui:rerender')

App.Config.set( 'translation_inline', Widget, 'Widgets' )