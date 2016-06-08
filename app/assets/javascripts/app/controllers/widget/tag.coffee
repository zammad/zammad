class App.WidgetTag extends App.Controller
  possibleTags: {}
  shiftHeld: false
  elements:
    '.js-newTagLabel': 'newTagLabel'
    '.js-newTagInput': 'newTagInput'

  events:
    'click .js-newTagLabel': 'showInput'
    'blur .js-newTagInput':  'hideOrAddInput'
    'click .js-newTagInput': 'onAddTag'
    'submit form':           'onAddTag'
    'click .js-delete':      'onRemoveTag'
    'mousedown .js-tag':     'shiftHeldToogle'
    'click .js-tag':         'searchTag'

  constructor: ->
    super

    @key = "tags::#{@object_type}::#{@object.id}"

    if @tags
      @render()
      return

    @fetch()

  fetch: =>
    @ajax(
      id:    @key
      type:  'GET'
      url:   "#{@apiPath}/tags"
      data:
        object: @object_type
        o_id:   @object.id
      processData: true
      success: (data, status, xhr) =>
        @tags = data.tags
        @render()
    )

  reload: (tags) ->
    @tags = tags
    @render()

  render: ->
    return if @lastTags && _.isEqual(@lastTags, @tags)
    @lastTags = @tags
    @html App.view('widget/tag')(
      tags: @tags || [],
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

  showInput: (e) ->
    e.preventDefault()
    @newTagLabel.addClass('hide')
    @newTagInput.removeClass('hide').focus()

  hideOrAddInput: (e) ->
    e.preventDefault()
    @newTagLabel.removeClass('hide')
    @newTagInput.addClass('hide')
    @onAddTag(e)

  onAddTag: (e) =>
    e.preventDefault()
    item = @$('[name="new_tag"]').val().trim()
    return if !item
    @add(item)

  add: (items) =>
    for item in items.split(',')
      item = item.trim()
      @addItem(item)

  addItem: (item) =>
    if _.contains(@tags, item)
      @render()
      return
    return if App.Config.get('tag_new') is false && !@possibleTags[item]
    @tags.push item
    @render()

    @ajax(
      type:  'GET'
      url:   "#{@apiPath}/tags/add"
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true,
      success: (data, status, xhr) =>
        @fetch()
    )

  onRemoveTag: (e) =>
    e.preventDefault()
    item = $(e.target).parents('li').find('.js-tag').text()
    return if !item
    @remove(item)

  remove: (item) =>

    @tags = _.filter(@tags, (tagItem) -> return tagItem if tagItem isnt item)
    @render()

    @ajax(
      type:  'GET'
      url:   "#{@apiPath}/tags/remove"
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true
      success: (data, status, xhr) =>
        @fetch()
    )

  searchTag: (e) =>
    e.preventDefault()
    item = $(e.target).text()
    item = item.replace('"', '')
    if item.match(/\W/)
      item = "\"#{item}\""
    searchAttribute = "tag:#{item}"
    currentValue = $('#global-search').val()
    if @shiftHeld && currentValue
      currentValue += ' AND '
      currentValue += searchAttribute
    else
      currentValue = searchAttribute
    $('#global-search').val(currentValue)
    delay = ->
      $('#global-search').focus()
    @delay(delay, 20)

  shiftHeldToogle: (e) =>
    @shiftHeld = e.shiftKey
