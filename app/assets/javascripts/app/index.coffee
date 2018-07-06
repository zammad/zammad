# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

#= require_self
#= require_tree ./lib/app_init
#= require_tree ./lib/mixins
#= require ./config.coffee
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./lib/app_post

class App extends Spine.Controller
  helper =

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

    # define mask helper
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
      "<time class=\"humanTimeFromNow #{cssClass}\" data-time=\"#{time}\" title=\"#{timestamp}\">#{humanTime}</time>"

    # define icon helper
    Icon: (name, className = '') ->
      App.Utils.icon(name, className)

    # define richtext helper
    RichText: (string) ->
      return string if !string
      if string.match(/@T\('/)
        string = string.replace(/@T\('(.+?)'\)/g, (match, capture) ->
          App.i18n.translateContent(capture)
        )
        return marked(string)
      App.i18n.translateContent(string)

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
      contentType != 'text/html'

    canPreview: (contentType) ->
      return false if _.isEmpty(contentType)
      return true if contentType.match(/image\/(png|jpg|jpeg|gif)/i)
      false

  @viewPrint: (object, attributeName, attributes, table) ->
    if !attributes
      attributes = {}
      if object.constructor.attributesGet
        attributes = object.constructor.attributesGet()
    attributeConfig = attributes[attributeName]
    value           = object[attributeName]
    valueRef        = undefined

    # check if relation is requested
    if !attributeConfig
      attributeNameNew = "#{attributeName}_id"
      attributeConfig   = attributes[attributeNameNew]
      if attributeConfig
        attributeName = attributeNameNew
        if object[attributeName]
          valueRef = value
          value    = object[attributeName]

    # in case of :: key, get the sub value
    if !value
      parts = attributeName.split('::')
      if parts[0] && parts[1] && object[ parts[0] ]
        value = object[ parts[0] ][ parts[1] ]

    # if we have no config, get output this way
    if !attributeConfig
      return @viewPrintItem(value)

    # check if valueRef already exists, no lookup needed later
    if !valueRef
      if attributeName.substr(attributeName.length-3, attributeName.length) is '_id'
        attributeNameWithoutRef = attributeName.substr(0, attributeName.length-3)
        if object[attributeNameWithoutRef]
          valueRef = object[attributeNameWithoutRef]

    @viewPrintItem(value, attributeConfig, valueRef, table)

  # define print name helper
  @viewPrintItem: (item, attributeConfig = {}, valueRef, table) ->
    return '-' if item is undefined
    return '-' if item is ''
    return item if item is null
    result = ''
    items = [item]
    if _.isArray(item)
      items = item

    # lookup relation
    for item in items
      resultLocal = item
      if attributeConfig.relation || valueRef
        if valueRef
          item = valueRef
        else
          item = App[attributeConfig.relation].find(item)

      # if date is a object, get name of the object
      isObject = false
      if item && typeof item is 'object'
        isObject = true
        if item.displayNameLong
          resultLocal = item.displayNameLong()
        else if item.displayName
          resultLocal = item.displayName()
        else
          resultLocal = item.name

      # execute callback on content
      if attributeConfig.callback
        resultLocal = attributeConfig.callback(resultLocal, attributeConfig)

      # text2html in textarea view
      isHtmlEscape = false
      if attributeConfig.tag is 'textarea'
        isHtmlEscape = true
        resultLocal       = App.Utils.text2html(resultLocal)

      # remember, html snippets are already escaped
      else if attributeConfig.tag is 'richtext'
        isHtmlEscape = true

      # fillup options
      if !_.isEmpty(attributeConfig.options)
        if attributeConfig.options[resultLocal]
          resultLocal = attributeConfig.options[resultLocal]

      # transform boolean
      if attributeConfig.tag is 'boolean'
        if resultLocal is true
          resultLocal = 'yes'
        else if resultLocal is false
          resultLocal = 'no'

      # translate content
      if attributeConfig.translate || (isObject && item.translate && item.translate())
        isHtmlEscape = true
        resultLocal       = App.i18n.translateContent(resultLocal)

      # transform date
      if attributeConfig.tag is 'date'
        isHtmlEscape = true
        resultLocal = App.i18n.translateDate(resultLocal)

      # transform input tel|url to make it clickable
      if attributeConfig.tag is 'input'
        if attributeConfig.type is 'tel'
          resultLocal = "<a href=\"#{App.Utils.phoneify(resultLocal)}\">#{App.Utils.htmlEscape(resultLocal)}</a>"
        else if attributeConfig.type is 'url'
          resultLocal = App.Utils.linkify(resultLocal)
        else
          resultLocal = App.Utils.htmlEscape(resultLocal)
        isHtmlEscape = true

      # use pretty time for datetime
      else if attributeConfig.tag is 'datetime'
        isHtmlEscape = true
        timestamp = App.i18n.translateTimestamp(resultLocal)
        escalation = false
        cssClass = attributeConfig.class || ''
        if cssClass.match 'escalation'
          escalation = true
        humanTime = ''
        if !table
          humanTime = App.PrettyDate.humanTime(resultLocal, escalation)
        resultLocal = "<time class=\"humanTimeFromNow #{cssClass}\" data-time=\"#{resultLocal}\" title=\"#{timestamp}\">#{humanTime}</time>"

      if !isHtmlEscape && typeof resultLocal is 'string'
        resultLocal = App.Utils.htmlEscape(resultLocal)

      if !_.isEmpty(result)
        result += ', '
      result += resultLocal

    result

  @view: (name) ->
    template = (params = {}) ->
      JST["app/views/#{name}"](_.extend(params, helper))
    template

class App.UiElement

window.App = App
