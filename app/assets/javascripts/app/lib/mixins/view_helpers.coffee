# Top-level shortcuts for various view template helper methods,
# to be included in view templates via
#
#     JST["path/to/template"](_.extend(App.ViewHelpers))

App.ViewHelpers =
  # define print name helper
  P: (object, attributeName, attributes, table = false) ->
    App.viewPrint(object, attributeName, attributes, table)

  # define date format helper
  date: (time) ->
    return '' if !time

    timeObject = new Date(time)
    d = App.Utils.formatTime(timeObject.getDate(), 2)
    m = App.Utils.formatTime(timeObject.getMonth() + 1, 2)
    y = timeObject.getFullYear()
    "#{y}-#{m}-#{d}"

  # define datetime format helper
  datetime: (time) ->
    return '' if !time

    timeObject = new Date(time)
    d = App.Utils.formatTime(timeObject.getDate(), 2)
    m = App.Utils.formatTime(timeObject.getMonth() + 1, 2)
    y = timeObject.getFullYear()
    S = App.Utils.formatTime(timeObject.getSeconds(), 2)
    M = App.Utils.formatTime(timeObject.getMinutes(), 2)
    H = App.Utils.formatTime(timeObject.getHours(), 2)
    "#{y}-#{m}-#{d} #{H}:#{M}:#{S}"

  # define decimal format helper
  decimal: (data, positions = 2) ->
    App.Utils.decimal(data, positions)

  # define time_duration / mm:ss / hh:mm:ss format helper
  time_duration: (time) ->
    return '' if !time
    return '' if isNaN(parseInt(time))

    # Hours, minutes and seconds
    hrs = ~~parseInt((time / 3600))
    mins = ~~parseInt(((time % 3600) / 60))
    secs = parseInt(time % 60)

    # Output like "1:01" or "4:03:59" or "123:03:59"
    mins = "0#{mins}" if mins < 10
    secs = "0#{secs}" if secs < 10
    if hrs > 0
      return "#{hrs}:#{mins}:#{secs}"
    "#{mins}:#{secs}"

  # define mask helper
  # mask an value like 'a***********yz'
  M: (item, start = 1, end = 2) ->
    return '' if !item
    string = ''
    end = item.length - end - 1
    for n in [0..item.length-1]
      if start <= n && end >= n
        string += '*'
      else
        string += item[n]
    string

  # define translation helper
  T: (item, args...) ->
    App.i18n.translateContent(item, args...)

  # define translation inline helper
  Ti: (item, args...) ->
    App.i18n.translateInline(item, args...)

  # define translation for date helper
  Tdate: (item, args...) ->
    App.i18n.translateDate(item, args...)

  # define translation for timestamp helper
  Ttimestamp: (item, args...) ->
    App.i18n.translateTimestamp(item, args...)

  # define linkify helper
  L: (item) ->
    if item && typeof item is 'string'
      return App.Utils.linkify(item)
    item

  # define config helper
  C: (key) ->
    App.Config.get(key)

  # define session helper
  S: (key) ->
    App.Session.get(key)

  # define view helper for rendering partial views
  V: (name, params) ->
    App.view(name)(params)

  # define address line helper
  AddressLine: (line) ->
    return '' if !line
    items = emailAddresses.parseAddressList(line)

    # line was not parsable
    return App.Utils.htmlEscape(line) if !items

    # set markup
    result = ''
    for item in items
      if result
        result = result + ', '
      if item.name
        item.name = item.name
          .replace(',', '')
          .replace(';', '')
          .replace('"', '')
          .replace('\'', '')
        if item.name.match(/\@|,|;|\^|\+|#|§|\$|%|&|\/|\(|\)|=|\?|\*/)
          item.name = "\"#{item.name}\""
        result = "#{result}#{App.Utils.htmlEscape(item.name)} "
      if item.address
        result = result + " <span class=\"text-muted\">&lt;#{App.Utils.htmlEscape(item.address)}&gt</span>"
    result

  # define file size helper
  humanFileSize: (size) ->
    App.Utils.humanFileSize(size)

  # define pretty/human time helper
  humanTime: (time, escalation = false, cssClass = '') ->
    timestamp = App.i18n.translateTimestamp(time)
    if escalation
      cssClass += ' escalation'
    humanTime = App.PrettyDate.humanTime(time, escalation)
    "<time class=\"humanTimeFromNow #{cssClass}\" datetime=\"#{time}\" title=\"#{timestamp}\">#{humanTime}</time>"

  # Why not just use `Icon: App.Utils.icon`?
  # Because App.Utils isn't loaded until after this file.
  Icon: (name, className = '') ->
    App.Utils.icon(name, className)

  fontIcon: (name, font, className = '') ->
    App.Utils.fontIcon(name, font, className)

  # define richtext helper
  RichText: (string) ->
    return string if !string
    if string.match(/@T\('/)
      string = string.replace(/@T\('(.+?)'\)/g, (match, capture) ->
        App.i18n.translateContent(capture)
      )
      return marked(string)
    App.i18n.translateContent(string)

  ContentOrMimeType: (attachment) ->
    types = ['Content-Type', 'content_type', 'Mime-Type', 'mime_type']
    _.values(_.pick(attachment?.preferences, types))[0]

  ContentTypeIcon: (contentType) ->
    contentType = App.Utils.contentTypeCleanup(contentType)
    icons =
      # image
      'image/jpeg': 'file-image'
      'image/jpg': 'file-image'
      'image/png': 'file-image'
      'image/svg': 'file-image'
      'image/gif': 'file-image'
      # documents
      'application/pdf': 'file-pdf'
      'application/msword': 'file-word' # .doc, .dot
      'application/vnd.ms-word': 'file-word'
      'application/vnd.oasis.opendocument.text': 'file-word'
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'file-word' # .docx
      'application/vnd.openxmlformats-officedocument.wordprocessingml.template': 'file-word' # .dotx
      'application/vnd.ms-excel': 'file-excel' # .xls
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'file-excel' # .xlsx
      'application/vnd.oasis.opendocument.spreadsheet': 'file-excel'
      'application/vnd.ms-powerpoint': 'file-powerpoint' # .ppt
      'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'file-powerpoint' # .pptx
      'application/vnd.oasis.opendocument.presentation': 'file-powerpoint'
      'text/plain': 'file-text'
      'text/html': 'file-code'
      'application/json': 'file-code'
      'message/rfc822': 'file-email'
      # code
      'application/json': 'file-code'
      # text
      'text/plain': 'file-text'
      'text/rtf': 'file-text'
      # archives
      'application/gzip': 'file-archive'
      'application/zip': 'file-archive'
    return icons[contentType]

  canDownload: (contentType) ->
    contentType = App.Utils.contentTypeCleanup(contentType)
    return false if contentType is 'application/pdf'
    contentType != 'text/html'

  canPreview: (contentType) ->
    return false if _.isEmpty(contentType)
    return true if contentType.match(/image\/(png|jpg|jpeg|gif)/i)
    false

  unique_avatar: (seed, text, size = 40) ->
    baseSize = 40
    width  = 300 * size/baseSize
    height = 226 * size/baseSize

    rng = new Math.seedrandom(seed)
    x   = rng() * (width - size)
    y   = rng() * (height - size)

    return App.view('avatar_unique')
      x: x
      y: y
      initials: text

  # icon with modifier based on visibility state
  # params: className, iconset, addStateClass
  iconWithModifier: (item, params) ->
    if !params.className
      params.className = ''

    if params.addStateClass
      params.className += " state-#{item.state}"

    App.view('knowledge_base/_icon_with_modifier')(
      item:      item
      className: params.className
      iconset:   params.iconset
    )

  replacePlaceholder: (template, items, encodeLink = false) ->
    App.Utils.replaceTags(template, items, encodeLink)

  # prints value depending on direction of active locale
  dir: (ltr, rtl) ->
    if App.i18n.dir() == 'ltr'
      ltr
    else
      rtl
