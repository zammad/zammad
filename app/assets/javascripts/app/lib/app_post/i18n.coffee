# coffeelint: disable=camel_case_classes
class App.i18n
  _instance = undefined

  @init: (args) ->
    _instance ?= new _i18nSingleton(args)

  @translateContent: (string, args...) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.translateContent(string, args)

  @translatePlain: (string, args...) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.translatePlain(string, args)

  @translateInline: (string, args...) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.translateInline(string, args)

  @translateTimestamp: (args, offset = 0) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.timestamp(args, offset)

  @translateDate: (args, offset = 0) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.date(args, offset)

  @get: ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.get()

  @set: (args) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.set(args)

  @setMap: (source, target, format) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.setMap(source, target, format)

  @meta: (source, target, format) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.meta()

  @notTranslatedFeatureEnabled: (locale) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.notTranslatedFeatureEnabled(locale)

  @getNotTranslated: (locale) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.getNotTranslated(locale)

  @removeNotTranslated: (locale, key) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.removeNotTranslated(locale, key)

  @setNotTranslated: (locale, key) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.setNotTranslated(locale, key)

  @timeFormat: (locale, key) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.mapTime

class _i18nSingleton extends Spine.Module
  @include App.LogInclude

  constructor: (locale) ->
    @mapTime           = {}
    @mapString         = {}
    @mapMeta           =
      total: 0
      translated: 0
    @_notTranslatedLog = false
    @_notTranslated    = {}
    @dateFormat        = 'yyyy-mm-dd'
    @timestampFormat   = 'yyyy-mm-dd HH:MM'

  get: ->
    @locale

  set: (localeToSet) ->

    # prepare locale
    localeToSet = localeToSet.toLowerCase()

    # check if locale exists
    localeFound = false
    locales     = App.Locale.all()
    for locale in locales
      if locale.locale is localeToSet
        localeFound = true

    # try aliases
    if !localeFound
      for locale in locales
        if locale.alias is localeToSet
          localeToSet = locale.locale

    # if no locale and no alias was found, try to find correct one
    if !localeFound

      # try to find by alias
      localeToSet = localeToSet.substr(0, 2)
      for locale in locales
        if locale.alias is localeToSet
          localeToSet = locale.locale
          localeFound = true

      # try to find by locale
      if !localeFound
        for locale in locales
          if locale.locale is localeToSet
            localeToSet = locale.locale
            localeFound = true

    # check if locale need to be changed
    return if localeToSet is @locale

    # set locale
    @locale = localeToSet

    # set if not translated should be logged
    @_notTranslatedLog = @notTranslatedFeatureEnabled(@locale)

    # set lang attribute of html tag
    $('html').prop('lang', @locale.substr(0, 2) )

    @mapString = {}
    App.Ajax.request(
      id:    'i18n-set-' + @locale,
      type:   'GET',
      url:    App.Config.get('api_path') + '/translations/lang/' + @locale,
      async:  false,
      success: (data, status, xhr) =>

        # total count of translations as ref.
        @mapMeta.total = data.total

        # load translation collection
        mapToLoad = []
        for object in data.list

          # set date/timestamp format
          if object[3] is 'time'
            @mapTime[ object[1] ] = object[2]

          else

            # set runtime lookup table
            @mapString[ object[1] ] = object[2]

            item = { id: object[0], source: object[1], target: object[2], locale: @locale }
            mapToLoad.push item

        @mapMeta.translated = mapToLoad.length
        @mapMeta.mapToLoad  = mapToLoad

        App.Event.trigger('i18n:language:change')
    )

  translateInline: (string, args) =>
    return string if !string
    App.Utils.htmlEscape(@translate(string, args))

  translateContent: (string, args) =>
    return string if !string

    if App.Config.get('translation_inline')
      return '<span class="translation" onclick="arguments[0].stopPropagation(); return false" contenteditable="true" title="' + App.Utils.htmlEscape(string) + '">' + App.Utils.htmlEscape(@translate(string)) + '</span>'

    translated = App.Utils.htmlEscape(@translate(string, args))

    # apply inline markup
    translated
      .replace(/\*(.+?)\*/gm, '<b>$1</b>')
      .replace(/_(.+?)_/gm, '<u>$1</u>')
      .replace(/§(.+?)§/gm, '<kbd>$1</kbd>')

  translatePlain: (string, args) =>
    @translate(string, args)

  translate: (string, args) =>

    # type convertation
    if typeof string isnt 'string'
      if string && string.toString
        string = string.toString()

    # return '' on undefined
    return '' if string is undefined
    return '' if string is ''

    # return translation
    if @mapString[string] isnt undefined
      @_translated = true
      translated   = @mapString[string]
    else
      @_translated = false
      translated   = string

      # log not translated strings in developer mode
      if @_notTranslatedLog && App.Config.get('developer_mode') is true
        if !@_notTranslated[@locale]
          @_notTranslated[@locale] = {}
        if !@_notTranslated[@locale][string]
          @log 'notice', "translation for '#{string}' in '#{@locale}' is missing"
        @_notTranslated[@locale][string] = true

    # search %s
    if args
      for arg in args
        translated = translated.replace(/%s/, arg)

    @log 'debug', 'translate', string, args, translated

    # return translated string
    translated

  meta: =>
    @mapMeta

  setMap: (source, target, format = 'string') =>
    if format is 'time'
      if target is ''
        delete @mapTime[source]
      else
        @mapTime[source] = target
    else
      if target is ''
        delete @mapString[source]
      else
        @mapString[source] = target

  notTranslatedFeatureEnabled: (locale) ->
    if locale.substr(0,2) is 'en'
      return false
    true

  getNotTranslated: (locale) =>
    @_notTranslated[locale || @locale]

  removeNotTranslated: (locale, key) =>
    delete @_notTranslated[locale][key]

  setNotTranslated: (locale, key) =>
    @_notTranslated[locale][key] = true

  date: (time, offset) =>
    @convert(time, offset, @mapTime['date'] || @dateFormat)

  timestamp: (time, offset) =>
    @convert(time, offset, @mapTime['timestamp'] || @timestampFormat)

  convert: (time, offset, format) ->
    s = (num, digits) ->
      while num.toString().length < digits
        num = '0' + num
      num

    timeObject = new Date(time)

    # add timezone diff, needed for unit tests
    if offset
      timeObject = new Date(timeObject.getTime() + (timeObject.getTimezoneOffset() * 60000))

    d = timeObject.getDate()
    m = timeObject.getMonth() + 1
    y = timeObject.getFullYear()
    S = timeObject.getSeconds()
    M = timeObject.getMinutes()
    H = timeObject.getHours()
    format = format.replace /dd/, s(d, 2)
    format = format.replace /d/, d
    format = format.replace /mm/, s(m, 2)
    format = format.replace /m/, m
    format = format.replace /yyyy/, y
    format = format.replace /SS/, s(S, 2)
    format = format.replace /MM/, s(M, 2)
    format = format.replace /HH/, s(H, 2)
    format
