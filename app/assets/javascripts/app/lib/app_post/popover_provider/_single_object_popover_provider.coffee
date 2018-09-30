class App.SingleObjectPopoverProvider extends App.PopoverProvider
  @klass = null # needs to be overrided
  @ignoredAttributes = []
  @includeData = true
  @templateName = 'single_object_generic'

  fullCssSelector: ->
    "div.#{@cssClass()}, span.#{@cssClass()}"

  bind: ->
    @params.parentController.$(@fullCssSelector()).bind('click', (e) =>
      id = @objectIdFor(e.target)
      return if !id
      object = @constructor.klass.find(id)
      @params.parentController.navigate object.uiUrl()
    )

  objectIdFor: (elem) ->
    $(elem).data('id')

  buildTitleFor: (elem) ->
    object = @constructor.klass.find(@objectIdFor(elem))
    App.Utils.htmlEscape(@displayTitleUsing(object))

  buildContentFor: (elem) ->
    id = @objectIdFor(elem)
    object = @constructor.klass.fullLocal(id)

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
        object[name] && attr.shown && !_.include(@constructor.ignoredAttributes, name)

    @buildHtmlContent(
      object: object
      attributes: data
    )
