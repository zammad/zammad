class App.WidgetTag extends App.Controller
  editMode: false
  pendingRefresh: false
  possibleTags: {}
  elements:
    '.js-newTagLabel': 'newTagLabel'
    '.js-newTagInput': 'newTagInput'

  events:
    'click .js-newTagLabel': 'showInput'
    'blur .js-newTagInput':  'hideOrAddInput'
    'click .js-newTagInput': 'onAddTag'
    'submit form':           'onAddTag'
    'click .js-delete':      'onRemoveTag'
    'click .js-tag':         'searchTag'

  constructor: ->
    super

    @key = "tags::#{@object_type}::#{@object.id}"

    if @tags
      @localTags = _.clone(@tags)
      @render()
      return

    @fetch()

  fetch: =>
    @pendingRefresh = false
    @ajax(
      id:    @key
      type:  'GET'
      url:   "#{@apiPath}/tags"
      data:
        object: @object_type
        o_id:   @object.id
      processData: true
      success: (data, status, xhr) =>
        @localTags = data.tags
        @render()
    )

  reload: (tags) =>
    if @editMode
      @pendingRefresh = true
      return
    @localTags = _.clone(tags)
    @render()

  render: =>
    return if @lastLocalTags && _.isEqual(@lastLocalTags, @localTags)
    @lastLocalTags = _.clone(@localTags)
    @html App.view('widget/tag')(
      tags: @localTags || [],
    )

    source = "#{App.Config.get('api_path')}/tag_search"
    @el.find('.js-newTagInput').autocomplete(
      source: source
      minLength: 2
      response: (e, ui) =>
        return if !ui
        return if !ui.content
        for item in ui.content
          @possibleTags[item.value] = true
    )

  showInput: (e) =>
    e.preventDefault()
    @newTagLabel.addClass('hide')
    @newTagInput.removeClass('hide').focus()
    @editMode = true

  hideOrAddInput: (e) =>
    e.preventDefault()
    @newTagLabel.removeClass('hide')
    @newTagInput.addClass('hide')
    @onAddTag(e)
    @editMode = false

  onAddTag: (e) =>
    e.preventDefault()
    item = @$('[name="new_tag"]').val().trim()
    if !item
      if @pendingRefresh
        @fetch()
      return
    @add(item)

  add: (items) =>
    for item in items.split(',')
      item = item.trim()
      @addItem(item)

  addItem: (item) =>
    if _.contains(@localTags, item)
      @render()
      return
    return if App.Config.get('tag_new') is false && !@possibleTags[item]
    @localTags.push item
    @render()

    @ajax(
      type:  'GET'
      url:   "#{@apiPath}/tags/add"
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true,
    )

  onRemoveTag: (e) =>
    e.preventDefault()
    item = $(e.target).parents('li').find('.js-tag').text()
    return if !item
    @remove(item)

  remove: (item) =>

    @localTags = _.filter(@localTags, (tagItem) -> return tagItem if tagItem isnt item)
    @render()

    @ajax(
      type:  'GET'
      url:   "#{@apiPath}/tags/remove"
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true
    )

  searchTag: (e) ->
    e.preventDefault()
    item = $(e.target).text()
    App.GlobalSearchWidget.search(item, 'tag')
