class App.WidgetTag extends App.Controller
  editMode: false
  pendingRefresh: false
  possibleTags: {}
  elements:
    '.js-newTagLabel': 'newTagLabel'
    '.js-newTagInput': 'newTagInput'

  events:
    'click .js-newTagLabel': 'showInput'
    'blur .js-newTagInput':  'hideAndAddInput'
    'keyup .js-newTagInput': 'addInput'
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

  addInput: (e) =>
    return if e.keyCode isnt 9 # tab
    @hideAndAddInput()

  fetch: =>
    @pendingRefresh = false
    App[@object_type].tagGet(
      @object.id,
      @key,
      (data) =>
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
    @$('.js-newTagInput').autocomplete(
      source: source
      minLength: 0
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
    @newTagInput.trigger(jQuery.Event('keydown'))
    @editMode = true

  hideAndAddInput: =>
    @newTagLabel.removeClass('hide')
    @newTagInput.addClass('hide')
    @onAddTag()
    @editMode = false

  onAddTag: (e) =>
    if e
      e.preventDefault()
    item = @$('[name="new_tag"]').val().trim()
    if !item
      if @pendingRefresh
        @fetch()
      return
    @add(item)

  add: (items, source = '') =>
    for item in items.split(',')
      item = item.trim()
      @addItem(item, source)

  addItem: (item, source = '') =>
    if _.contains(@localTags, item)
      @render()
      return
    return if source != 'macro' && App.Config.get('tag_new') is false && !@possibleTags[item]
    @localTags.push item
    @render()
    App[@object_type].tagAdd(@object.id, item)

  onRemoveTag: (e) =>
    e.preventDefault()
    item = $(e.target).parents('li').find('.js-tag').text()
    return if !item
    @remove(item)

  remove: (item) =>
    @localTags = _.filter(@localTags, (tagItem) -> return tagItem if tagItem isnt item)
    @render()
    App[@object_type].tagRemove(@object.id, item)

  searchTag: (e) ->
    e.preventDefault()
    item = $(e.target).text()
    App.GlobalSearchWidget.search(item, 'tags')
