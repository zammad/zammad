class App.SingleObjectPopoverProvider extends App.PopoverProvider
  @klass = null # needs to be overrided
  @ignoredAttributes = []
  @includeData = true
  @templateName = 'single_object_generic'
  @titleTemplateName = 'title_generic'
  @additionalHeadlineTemplateName = null

  fullCssSelector: ->
    "div.#{@cssClass()}, span.#{@cssClass()}"

  bind: ->
    @params.parentController.$(@fullCssSelector()).on('click', (e) =>
      object = @getObject(e.target)
      return if !object

      @params.parentController.navigate object.uiUrl()
    )

  getObject: (elem, full = false) ->
    id = @objectIdFor(elem)
    return if !id

    return @constructor.klass.fullLocal(id) if full

    @constructor.klass.find(id)

  objectIdFor: (elem) ->
    $(elem).data('id')

  showAvatar: (elem, object) ->
    $(elem).data('popover-show-avatar') && object && typeof object.avatar is 'function'

  buildTitleFor: (elem) ->
    object = @getObject(elem)

    data = {
      object: object
      displayTitle: @displayTitleUsing(object)
      showAvatar: @showAvatar(elem, object)
    }

    if @constructor.additionalHeadlineTemplateName
      data.additionalHeadlineTemplateName = "popover/#{@constructor.additionalHeadlineTemplateName}"

    @buildHtmlTitle(data)

  buildContentFor: (elem) ->
    object = @getObject(elem, true)

    ignoredAttributes = @constructor.ignoredAttributes

    # get display data
    data = _.values(@constructor.klass.attributesGet('view'))
      .filter (attr) ->
        # check if value for _id exists
        name    = attr.name
        nameNew = name.substr(0, name.length - 3)
        if nameNew of object
          name = nameNew

        # add to show if value exists
        # do not show ignroed attributes
        object[name] && attr.shown && !_.include(ignoredAttributes, name)

    @buildHtmlContent(
      object: object
      attributes: data
    )
