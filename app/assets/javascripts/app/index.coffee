# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

#= require_self
#= require_tree ./lib/app_init
#= require ./config.coffee
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./lib/app_post

class App extends Spine.Controller
  @viewPrint: (object, attribute_name, attributes) ->
    if !attributes
      attributes = {}
      if object.constructor.attributesGet
        attributes = object.constructor.attributesGet()
    attribute_config = attributes[attribute_name]
    value            = object[attribute_name]
    valueRef         = undefined

    # check if relation is requested
    if !attribute_config
      attribute_name_new = "#{attribute_name}_id"
      attribute_config   = attributes[attribute_name_new]
      if attribute_config
        attribute_name = attribute_name_new
        if object[attribute_name]
          valueRef = value
          value    = object[attribute_name]

    # in case of :: key, get the sub value
    if !value
      parts = attribute_name.split('::')
      if parts[0] && parts[1] && object[ parts[0] ]
        value = object[ parts[0] ][ parts[1] ]

    # if we have no config, get output this way
    if !attribute_config
      return @viewPrintItem(value)

    # check if valueRef already exists, no lookup needed later
    if !valueRef
      attribute_name_without_ref = attribute_name.substr(attribute_name.length-3, attribute_name.length)
      if attribute_name_without_ref is '_id'
        attribute_name_without_ref = attribute_name.substr(0, attribute_name.length-3)
        if object[attribute_name_without_ref]
          valueRef = object[attribute_name_without_ref]

    @viewPrintItem(value, attribute_config, valueRef)

  # define print name helper
  @viewPrintItem: (item, attribute_config = {}, valueRef) ->
    return '-' if item is undefined
    return '-' if item is ''
    return item if !item
    result = item

    # lookup relation
    if attribute_config.relation || valueRef
      if valueRef
        item = valueRef
      else
        item = App[attribute_config.relation].find(item)

    # if date is a object, get name of the object
    isObject = false
    if typeof item is 'object'
      isObject = true
      if item.displayNameLong
        result = item.displayNameLong()
      else if item.displayName
        result = item.displayName()
      else
        result = item.name

    # execute callback on content
    if attribute_config.callback
      result = attribute_config.callback(result, attribute_config)

    # text2html in textarea view
    isHtmlEscape = false
    if attribute_config.tag is 'textarea'
      isHtmlEscape = true
      result       = App.Utils.text2html(result)

    # remember, html snippets are already escaped
    else if attribute_config.tag is 'richtext'
      isHtmlEscape = true

    # fillup options
    if !_.isEmpty(attribute_config.options)
      if attribute_config.options[result]
        result = attribute_config.options[result]

    # translate content
    if attribute_config.translate || (isObject && item.translate && item.translate())
      isHtmlEscape = true
      result       = App.i18n.translateContent(result)

    # transform date
    if attribute_config.tag is 'date'
      isHtmlEscape = true
      result       = App.i18n.translateDate(result)

    # transform input tel|url to make it clickable
    if attribute_config.tag is 'input'
      isHtmlEscape = true
      result       = App.Utils.htmlEscape(result)
      if attribute_config.type is 'tel'
        result = "<a href=\"tel://#{result}\">#{result}</a>"
      if attribute_config.type is 'url'
        result = App.Utils.linkify(result)

    # use pretty time for datetime
    else if attribute_config.tag is 'datetime'
      isHtmlEscape = true
      timestamp = App.i18n.translateTimestamp(result)
      escalation = false
      cssClass = attribute_config.class || ''
      if cssClass.match 'escalation'
        escalation = true
      humanTime = App.PrettyDate.humanTime(result, escalation)
      result    = "<time class=\"humanTimeFromNow #{cssClass}\" data-time=\"#{result}\" title=\"#{timestamp}\">#{humanTime}</time>"

    if !isHtmlEscape && typeof result is 'string'
      result = App.Utils.htmlEscape(result)

    result

  @view: (name) ->
    template = (params = {}) ->

      # define print name helper
      params.P = (object, attribute_name, attributes) ->
        App.viewPrint(object, attribute_name, attributes)

      # define date format helper
      params.date = (time) ->
        return '' if !time

        timeObject = new Date(time)
        d = App.Utils.formatTime(timeObject.getDate(), 2)
        m = App.Utils.formatTime(timeObject.getMonth() + 1, 2)
        y = timeObject.getFullYear()
        "#{y}-#{m}-#{d}"

      # define datetime format helper
      params.datetime = (time) ->
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
      params.decimal = (data, positions = 2) ->
        App.Utils.decimal(data, positions)

      # define translation helper
      params.T = (item, args...) ->
        App.i18n.translateContent(item, args...)

      # define translation inline helper
      params.Ti = (item, args...) ->
        App.i18n.translateInline(item, args...)

      # define translation for date helper
      params.Tdate = (item, args...) ->
        App.i18n.translateDate(item, args...)

      # define translation for timestamp helper
      params.Ttimestamp = (item, args...) ->
        App.i18n.translateTimestamp(item, args...)

      # define linkify helper
      params.L = (item) ->
        if item && typeof item is 'string'
          return App.Utils.linkify(item)
        item

      # define config helper
      params.C = (key) ->
        App.Config.get(key)

      # define session helper
      params.S = (key) ->
        App.Session.get(key)

      # define address line helper
      params.AddressLine = (line) ->
        return '' if !line
        items = emailAddresses.parseAddressList(line)

        # line was not parsable
        if !items
          return line

        # set markup
        result = ''
        for item in items
          if result
            result = result + ', '
          if item.name
            result = result + App.Utils.htmlEscape(item.name) + ' '
          if item.address
            result = result + " <span class=\"text-muted\">&lt;#{App.Utils.htmlEscape(item.address)}&gt</span>"
        result

      # define file size helper
      params.humanFileSize = (size) ->
        App.Utils.humanFileSize(size)

      # define pretty/human time helper
      params.humanTime = (time, escalation = false, cssClass = '') ->
        timestamp = App.i18n.translateTimestamp(time)
        if escalation
          cssClass += ' escalation'
        humanTime = App.PrettyDate.humanTime(time, escalation)
        "<time class=\"humanTimeFromNow #{cssClass}\" data-time=\"#{time}\" title=\"#{timestamp}\">#{humanTime}</time>"

      # define icon helper
      params.Icon = (name, className = '') ->
        App.Utils.icon(name, className)

      # define richtext helper
      params.RichText = (string) ->
        return string if !string
        if string.match(/@T\('/)
          string = string.replace(/@T\('(.+?)'\)/g, (match, capture) ->
            App.i18n.translateContent(capture)
          )
          return marked(string)
        App.i18n.translateContent(string)

      # define template
      JST["app/views/#{name}"](params)
    template

class App.UiElement

window.App = App
