# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/


#= require_self
#= require_tree ./lib/app_init
#= require ./config.js.coffee
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./lib/app_post

class App extends Spine.Controller
  @viewPrint: (object, attribute_name) ->
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

    #console.log('Pa', attribute_name, object, attribute_config, object[attribute_name], valueRef, value)

    # if we have no config, get output this way
    if !attribute_config
      return @viewPrintItem( value )

    # check if valueRef already exists, no lookup needed later
    if !valueRef
      attribute_name_without_ref = attribute_name.substr(attribute_name.length-3, attribute_name.length)
      if attribute_name_without_ref is '_id'
        attribute_name_without_ref = attribute_name.substr(0, attribute_name.length-3)
        if object[attribute_name_without_ref]
          valueRef = object[attribute_name_without_ref]

    return @viewPrintItem( value, attribute_config, valueRef )

  # define print name helper
  @viewPrintItem: ( item, attribute_config = {}, valueRef ) ->
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
      result = attribute_config.callback( result, attribute_config )

    # text2html in textarea view
    isHtmlEscape = false
    if attribute_config.tag is 'textarea'
      isHtmlEscape = true
      result       = App.Utils.text2html( result )

    # remember, html snippets are already escaped
    else if attribute_config.tag is 'richtext'
      isHtmlEscape = true

    # fillup options
    if !_.isEmpty(attribute_config.options)
      if attribute_config.options[result]
        result = attribute_config.options[result]

    # translate content
    if attribute_config.translate || ( isObject && item.translate && item.translate() )
      isHtmlEscape = true
      result       = App.i18n.translateContent( result )

    # transform date
    if attribute_config.tag is 'date'
      isHtmlEscape = true
      result       = App.i18n.translateDate(result)

    # use pretty time for datetime
    else if attribute_config.tag is 'datetime'
      isHtmlEscape = true
      timestamp = App.i18n.translateTimestamp(result)
      escalation = undefined
      if attribute_config.class is 'escalation'
        escalation
      humanTime = App.PrettyDate.humanTime(result, escalation)
      result       = "<span class=\"humanTimeFromNow #{attribute_config.class}\" data-time=\"#{result}\" data-tooltip=\"#{timestamp}\">#{humanTime}</span>"
      #result      = App.i18n.translateTimestamp(result)

    if !isHtmlEscape && typeof result is 'string'
      result = App.Utils.htmlEscape(result)

    result

  @view: (name) ->
    template = ( params = {} ) =>

      # define print name helper
      params.P = ( object, attribute_name ) ->
        App.viewPrint( object, attribute_name )

      # define date format helper
      params.date = ( time ) ->
        return '' if !time
        s = ( num, digits ) ->
          while num.toString().length < digits
            num = "0" + num
          num

        timeObject = new Date(time)
        d = s( timeObject.getDate(), 2 )
        m = s( timeObject.getMonth() + 1, 2 )
        y = timeObject.getFullYear()
        "#{y}-#{m}-#{d}"

      # define datetime format helper
      params.datetime = ( time ) ->
        return '' if !time
        s = ( num, digits ) ->
          while num.toString().length < digits
            num = "0" + num
          num

        timeObject = new Date(time)
        d = s( timeObject.getDate(), 2 )
        m = s( timeObject.getMonth() + 1, 2 )
        y = timeObject.getFullYear()
        S = s( timeObject.getSeconds(), 2 )
        M = s( timeObject.getMinutes(), 2 )
        H = s( timeObject.getHours(), 2 )
        "#{y}-#{m}-#{d} #{H}:#{M}:#{S}"

      # define decimal format helper
      params.decimal = ( data, positions = 2 ) ->
        return '' if !data
        s = ( num, digits ) ->
          while num.toString().length < digits
            num = num + "0"
          num
        result = data.toString().match(/^(.+?)\.(.+?)$/)
        if !result || !result[2]
          return "#{data}." + s( 0, positions ).toString()
        length = result[2].toString().length
        diff = positions - length
        if diff > 0
          return "#{result[1]}." + s( result[2], positions ).toString()
        "#{result[1]}.#{result[2].substr(0,positions)}"

      # define translation helper
      params.T = ( item, args... ) ->
        App.i18n.translateContent( item, args... )

      # define translation inline helper
      params.Ti = ( item, args... ) ->
        App.i18n.translateInline( item, args... )

      # define linkify helper
      params.L = ( item ) ->
        if item && typeof item is 'string'
          return App.Utils.linkify( item )
        item

      # define config helper
      params.C = ( key ) ->
        App.Config.get( key )

      # define session helper
      params.S = ( key ) ->
        App.Session.get( key )

      # define address line helper
      params.AddressLine = ( line ) ->
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
      params.humanFileSize = ( size ) ->
        App.Utils.humanFileSize(size)

      # define pretty/human time helper
      params.humanTime = ( time, escalation ) ->
        App.PrettyDate.humanTime(time, escalation)

      # define pretty/human time helper
      params.timestamp = ( time ) ->
        App.i18n.translateTimestamp(time)

      # define template
      JST["app/views/#{name}"](params)
    template

window.App = App
