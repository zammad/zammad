# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

#= require_self
#= require_tree ./lib/app_init
#= require_tree ./lib/mixins
#= require ./config.coffee
#= require_tree ./models
#= require_tree ./controllers/_application_controller
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./lib/app_post

class App extends Spine.Controller
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

    @viewPrintItem(value, attributeConfig, valueRef, table, object)

  # define print name helper
  @viewPrintItem: (item, attributeConfig = {}, valueRef, table, object) ->
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
        resultLocal  = App.i18n.translateContent(resultLocal)

      # transform date
      if attributeConfig.tag is 'date'
        isHtmlEscape = true
        resultLocal = App.i18n.translateDate(resultLocal)

      linktemplate = @_placeholderReplacement(object, attributeConfig, resultLocal, isHtmlEscape)
      if linktemplate
        resultLocal = linktemplate
        isHtmlEscape = true

      # transform input tel|url to make it clickable
      if attributeConfig.tag is 'input' && !linktemplate
        if attributeConfig.type is 'tel'
          resultLocal = "<a href=\"#{App.Utils.phoneify(resultLocal)}\">#{App.Utils.htmlEscape(resultLocal)}</a>"
        else if attributeConfig.type is 'url' && !linktemplate
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
        resultLocal = "<time class=\"humanTimeFromNow #{cssClass}\" datetime=\"#{resultLocal}\" title=\"#{timestamp}\">#{humanTime}</time>"

      if !isHtmlEscape && typeof resultLocal is 'string'
        resultLocal = App.Utils.htmlEscape(resultLocal)

      if !_.isEmpty(result)
        result += ', '
      result += resultLocal

    result

  @_placeholderReplacement: (object, attributeConfig, resultLocal, isHtmlEscape) ->
    return if !object
    return if !attributeConfig
    return if _.isEmpty(attributeConfig.linktemplate)
    return if !object.constructor
    return if !object.constructor.className
    return if _.isEmpty(object[attributeConfig.name])
    placeholderObjects = { attribute: attributeConfig, session: App.Session.get(), config: App.Config.all() }
    placeholderObjects[object.constructor.className.toLowerCase()] = object

    value = resultLocal
    if !isHtmlEscape
      value = App.Utils.htmlEscape(value)

    "<a href=\"#{App.Utils.replaceTags(attributeConfig.linktemplate, placeholderObjects, true)}\" target=\"blank\">#{value}</a>"

  @view: (name) ->
    template = (params = {}) ->
      JST["app/views/#{name}"](_.extend(params, App.ViewHelpers))
    template

class App.UiElement

window.App = App
