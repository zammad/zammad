class App.i18n
  _instance = undefined

  @init: ( args ) ->
    _instance ?= new _i18nSingleton( args )

  @translateContent: ( string, args... ) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton
    _instance.translateContent( string, args )

  @translatePlain: ( string, args... ) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton
    _instance.translatePlain( string, args )

  @translateInline: ( string, args... ) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton
    _instance.translateInline( string, args )

  @translateTimestamp: ( args, offset = 0 ) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton
    _instance.timestamp( args, offset )

  @translateDate: ( args, offset = 0 ) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton
    _instance.date( args, offset )

  @get: ->
    if _instance == undefined
      _instance ?= new _i18nSingleton
    _instance.get()

  @set: ( args ) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton( args )
    _instance.set( args )

  @escape: ( args ) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton( args )
    _instance.escape( args )

class _i18nSingleton extends Spine.Module
  @include App.LogInclude

  constructor: ( locale ) ->
    @map = {}
    @dateFormat      = 'yyyy-mm-dd'
    @timestampFormat = 'yyyy-mm-dd HH:MM'

    # observe if text has been translated
    $('body')
      .delegate '.translation', 'focus', (e) =>
        $this = $(e.target)
        $this.data 'before', $this.html()
        return $this
#      .delegate '.translation', 'blur keyup paste', (e) =>
      .delegate '.translation', 'blur', (e) =>
        $this = $(e.target)
        source = $this.attr('data-text')

        # get new translation
        translation_new = $this.html()
        translation_new = ('' + translation_new)
          .replace(/<.+?>/g, '')

        # set new translation
        $this.html(translation_new)

        # update translation
        return if $this.data('before') is translation_new
        @log 'debug', 'translate Update', translation_new, $this.data, 'before'
        $this.data 'before', translation_new

        # update runtime translation map
        @map[ source ] = translation_new

        # replace rest in page
        $(".translation[data-text='#{source}']").html( translation_new )

        # update permanent translation map
        translation = App.Translation.findByAttribute( 'source', source )
        if translation
          translation.updateAttribute( 'target', translation_new )
        else
          translation = new App.Translation
          translation.load(
            locale: @locale,
            source: source,
            target: translation_new,
          )
          translation.save()

        return $this

  get: ->
    @locale

  set: ( locale ) ->
    if locale is 'en-US'
      locale = 'en'
    @locale = locale

    # set lang attribute of html tag
    $('html').prop( 'lang', locale.substr(0, 2) )

    @map = {}
    App.Ajax.request(
      id:    'i18n-set-' + locale,
      type:   'GET',
      url:    App.Config.get('api_path') + '/translations/lang/' + locale,
      async:  false,
      success: (data, status, xhr) =>

        # set timestamp format
        if data.timestampFormat
          @timestampFormat = data.timestampFormat

        # set date format
        if data.dateFormat
          @dateFormat = data.dateFormat

        # load translation collection
        for object in data.list

          # set runtime lookup table
          @map[ object[1] ] = object[2]

          # load in collection if needed
          App.Translation.refresh( { id: object[0], source: object[1], target: object[2], locale: @locale } )
    )

  translateInline: ( string, args... ) =>
    @escape( @translate( string, args... ) )

  translateContent: ( string, args... ) =>
    translated = @escape( @translate( string, args... ) )
#    replace = '<span class="translation" contenteditable="true" data-text="' + @escape(string) + '">' + translated + '<span class="icon-edit"></span>'
    if App.Config.get( 'Translation' )
      replace = '<span class="translation" contenteditable="true" data-text="' + @escape(string) + '">' + translated + ''
  #    if !@_translated
  #       replace += '<span class="missing">XX</span>'
      replace += '</span>'
    else
      translated

  translatePlain: ( string, args... ) =>
    @translate( string, args... )

  translate: ( string, args... ) =>

    # type convertation
    if typeof string isnt 'string'
      if string && string.toString
        string = string.toString()

    # return '' on undefined
    return '' if string is undefined
    return '' if string is ''

    # return translation
    if @map[string] isnt undefined
      @_translated = true
      translated   = @map[string]
    else
      @_translated = false
      translated   = string

    # search %s
    for arg in args
      translated = translated.replace(/%s/, arg)

    @log 'debug', 'translate', string, args, translated

    # return translated string
    return translated

  escape: ( string ) ->
    string = ( '' + string )
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\x22/g, '&quot;')

  date: ( time, offset ) =>
    @convert(time, offset, @dateFormat)

  timestamp: ( time, offset ) =>
    @convert(time, offset, @timestampFormat)

  convert: ( time, offset, format ) =>
    s = ( num, digits ) ->
      while num.toString().length < digits
        num = "0" + num
      num

    timeObject = new Date(time)

    # add timezone diff, needed for unit tests
    if offset
      timeObject = new Date( timeObject.getTime() + (timeObject.getTimezoneOffset() * 60000) )

    d = timeObject.getDate()
    m = timeObject.getMonth() + 1
    y = timeObject.getFullYear()
    S = timeObject.getSeconds()
    M = timeObject.getMinutes()
    H = timeObject.getHours()
    format = format.replace /dd/, s( d, 2 )
    format = format.replace /d/, d
    format = format.replace /mm/, s( m, 2 )
    format = format.replace /m/, m
    format = format.replace /yyyy/, y
    format = format.replace /SS/, s( S, 2 )
    format = format.replace /MM/, s( M, 2 )
    format = format.replace /HH/, s( H, 2 )
    return format
