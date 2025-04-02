class App.WidgetTextModule extends App.Controller
  searchCondition: {}
  constructor: ->
    super

    @searchCondition = @data.ticket || {}

    # remember instances
    @bindElements = []
    if @selector
      @bindElements = @$(@selector).textmodule()
    else
      if @el.attr('contenteditable')
        @bindElements = @el.textmodule()
      else
        @bindElements = @$('[contenteditable]').textmodule()
    @update()

    @subscribeId = App.TextModule.subscribe(@update, initFetch: true)

    @controllerBind('TextModulePreconditionUpdate', (data) =>
      return if data.taskKey isnt @taskKey
      @searchCondition = data.params
      @update()
    )

  release: =>
    App.TextModule.unsubscribe(@subscribeId)

  reload: (data) =>
    return if !data
    @data            = data
    @searchCondition = @data.ticket
    @update()

  currentCollection: =>
    @all

  update: =>
    allRaw = App.TextModule.all()
    @all = []

    # Get group IDs that match ticket create form.
    # This will be used to handle empty group_id cases.
    userGroupIds = _.map @data.user.allGroupIds('create'), (elem) -> parseInt(elem)

    for item in allRaw
      continue if item.active isnt true

      if !_.isEmpty(item.group_ids)
        if @searchCondition.group_id
          continue if !_.includes(item.group_ids, parseInt(@searchCondition.group_id))
        else
          # Show text modules that are available in one of the user's groups
          continue if _.intersection(item.group_ids, userGroupIds).length == 0

      attributes = item.attributes()
      attributes.content = App.Utils.replaceTags(attributes.content, @data)
      @all.push attributes

    # set new data
    if @bindElements[0]
      for element in @bindElements
        continue if !$(element).data().plugin_textmodule

        $(element).data().plugin_textmodule.searchCondition = @searchCondition
        $(element).data().plugin_textmodule.collection      = @all
