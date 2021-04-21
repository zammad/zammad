# coffeelint: disable=camel_case_classes
class App.i18n
  _instance = undefined

  @init: (args) ->
    _instance ?= new _i18nSingleton(args)

  @translateDeep: (input, args...) ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.translateDeep(input, args)

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

  @dir: ->
    if _instance == undefined
      _instance ?= new _i18nSingleton()
    _instance.dir()

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

  @detectBrowserLocale: ->
    if window.navigator.languages
      for browserLocale in window.navigator.languages
        if local = @findLocalLocale(browserLocale)
          return local

    if window.navigator.language
      if local = @findLocalLocale(window.navigator.language)
        return local

    if window.navigator.userLanguage
      if local = @findLocalLocale(window.navigator.userLanguage)
        return local

    return 'en-us'

  @findLocalLocale: (given) ->
    givenLower = given.toLowerCase()

    for local in App.Locale.all()
      if givenLower == local.locale.toLowerCase()
        return local.locale.toLowerCase()

    givenAlias = given.substr(0, 2).toLowerCase()

    for local in App.Locale.all()
      if givenAlias == local.alias.toLowerCase()
        return local.locale.toLowerCase()

  @detectBrowserTimezone: ->
    return if !window.Intl
    return if !window.Intl.DateTimeFormat
    DateTimeFormat = Intl.DateTimeFormat()
    return if !DateTimeFormat
    return if !DateTimeFormat.resolvedOptions
    resolvedOptions = DateTimeFormat.resolvedOptions()
    return if !resolvedOptions
    return if !resolvedOptions.timeZone
    resolvedOptions.timeZone

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
    @dirToSet          = 'ltr'

  dir: ->
    @dirToSet

  get: ->
    @locale

  set: (localeToSet) ->

    # prepare locale
    localeToSet = localeToSet.toLowerCase()
    @dirToSet = 'ltr'

    # check if locale exists
    localeFound = false
    locales     = App.Locale.all()
    for locale in locales
      if locale.locale is localeToSet
        localeToSet = locale.locale
        @dirToSet = locale.dir
        localeFound = true

    # try aliases
    if !localeFound
      for locale in locales
        if locale.alias is localeToSet
          localeToSet = locale.locale
          @dirToSet = locale.dir
          localeFound = true

    # if no locale and no alias was found, try to find correct one
    if !localeFound

      # try to find by alias
      localeToSet = localeToSet.substr(0, 2)
      for locale in locales
        if locale.alias is localeToSet
          localeToSet = locale.locale
          @dirToSet = locale.dir
          localeFound = true

    # check if locale need to be changed
    return if localeToSet is @locale

    # set locale
    @locale = localeToSet

    # set if not translated should be logged
    @_notTranslatedLog = @notTranslatedFeatureEnabled(@locale)

    # set lang and dir attribute of html tag
    $('html').prop('lang', localeToSet.substr(0, 2))
    $('html').prop('dir', @dirToSet)

    @mapString = {}
    App.Ajax.request(
      id:    "i18n-set-#{@locale}"
      type:   'GET'
      url:    "#{App.Config.get('api_path')}/translations/lang/#{@locale}"
      async:  false
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
    @translate(string, args, true)

  translateDeep: (input, args) =>
    if _.isArray(input)
      _.map input, (item) =>
        @translateDeep(item, args)
    else if _.isObject(input)
      _.reduce _.keys(input), (memo, item) =>
        memo[item] = @translateDeep(input[item])
        memo
      , {}
    else
      @translateInline(input, args)


  translateContent: (string, args) =>
    return string if !string

    if App.Config.get('translation_inline')
      return '<span class="translation" contenteditable="true" title="' + App.Utils.htmlEscape(string) + '">' + App.Utils.htmlEscape(@translate(string)) + '</span>'

    translated = @translate(string, args, true, true)

  translatePlain: (string, args) =>
    @translate(string, args)

  translate: (string, args, quote, markup) =>

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

    # apply html quote
    if quote
      translated = App.Utils.htmlEscape(translated)

    # apply inline markup pre
    if markup
      translated = translated
        .replace(/\|\|(.+?)\|\|/gm, '<i>$1</i>')
        .replace(/\|(.+?)\|/gm, '<b>$1</b>')
        .replace(/_(.+?)_/gm, '<u>$1</u>')
        .replace(/\/\/(.+?)\/\//gm, '<del>$1</del>')
        .replace(/§(.+?)§/gm, '<kbd>$1</kbd>')

    # search %s|%l
    if args
      for arg in args
        translated = translated.replace(/%(s|l)/, (match) ->
          if match is '%s'
            if quote
              argNew = App.Utils.htmlEscape(arg)
            else
              argNew = arg
            argNew
          else
            "<a href=\"#{arg}\">🔗</a>"
        )

    # apply inline markup post
    if markup
      translated = translated
        .replace(/\[(.+?)\]\((.+?)\)/gm, '<a href="$2" target="_blank">$1</a>')

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
    notTranslated = @_notTranslated[locale || @locale]
    return notTranslated if locale && locale isnt @locale

    # remove already translated entries
    for local_locale, translation_list of notTranslated
      if @mapString[local_locale] && @mapString[local_locale] isnt ''
        delete notTranslated[local_locale]
    notTranslated

  removeNotTranslated: (locale, key) =>
    return if !@_notTranslated[locale]
    delete @_notTranslated[locale][key]

  setNotTranslated: (locale, key) =>
    if !@_notTranslated[locale]
      @_notTranslated[locale] = {}
    @_notTranslated[locale][key] = true

  date: (time, offset) =>
    return time if !time
    @convert(time, offset, @mapTime['date'] || @dateFormat)

  timestamp: (time, offset) =>
    return time if !time
    @convert(time, offset, @mapTime['timestamp'] || @timestampFormat)

  convertUTC: (time) ->
    timeArray = time.match(/\d+/g)
    [y, m, d, H, M] = timeArray
    new Date(Date.UTC(y, m - 1, d, H, M))

  formatNumber: (num, digits) ->
    while num.toString().length < digits
      num = '0' + num
    num

  convert: (time, offset, format) ->

    timeObject = new Date(time)

    # On firefox the Date constructor does not recongise date format that
    # ends with UTC, instead it returns a NaN (Invalid Date Format) this
    # block serves as polyfill to support time format that ends UTC in firefox
    if isNaN(timeObject)
       # works for only time string with this format: 2021-02-08 09:13:20 UTC
      timeObject = @convertUTC(time) if time.match(/ UTC/)

    # add timezone diff, needed for unit tests
    if offset
      timeObject = new Date(timeObject.getTime() + (timeObject.getTimezoneOffset() * 60000))

    d      = timeObject.getDate()
    m      = timeObject.getMonth() + 1
    yfull  = timeObject.getFullYear()
    yshort = timeObject.getYear()-100
    S      = timeObject.getSeconds()
    M      = timeObject.getMinutes()
    H      = timeObject.getHours()
    format = format
      .replace(/dd/, @formatNumber(d, 2))
      .replace(/d/, d)
      .replace(/mm/, @formatNumber(m, 2))
      .replace(/m/, m)
      .replace(/yyyy/, yfull)
      .replace(/yy/, yshort)
      .replace(/SS/, @formatNumber(S, 2))
      .replace(/MM/, @formatNumber(M, 2))
      .replace(/HH/, @formatNumber(H, 2))
    format
