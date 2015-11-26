class App.WidgetTag extends App.Controller
  elements:
    '.js-newTagLabel': 'newTagLabel'
    '.js-newTagInput': 'newTagInput'

  events:
    'click .js-newTagLabel': 'showInput'
    'blur .js-newTagInput':  'hideInput'
    'click .js-newTagInput': 'onAddTag'
    'submit form':           'onAddTag'
    'click .js-delete':      'onRemoveTag'

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
      url:   @apiPath + '/tags'
      data:
        object: @object_type
        o_id:   @object.id
      processData: true
      success: (data, status, xhr) =>
        @tags = data.tags
        @render()
    )

  render: ->
    @html App.view('widget/tag')(
      tags: @tags || [],
    )

  showInput: (e) ->
    e.preventDefault()
    @newTagLabel.addClass('hide')
    @newTagInput.removeClass('hide').focus()

  hideInput: (e) ->
    e.preventDefault()
    @newTagLabel.removeClass('hide')
    @newTagInput.addClass('hide')

  onAddTag: (e) =>
    e.preventDefault()
    item = @$('[name="new_tag"]').val()
    return if !item
    @add(item)

  add: (item) =>
    if _.contains(@tags, item)
      @render()
      return

    @tags.push item
    @render()

    @ajax(
      type:  'GET',
      url:   @apiPath + '/tags/add',
      data:
        object: @object_type,
        o_id:   @object.id,
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

    @tags = _.filter(@tags, (tagItem) -> return tagItem if tagItem isnt item )
    @render()

    @ajax(
      type:  'GET'
      url:   @apiPath + '/tags/remove'
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true
      success: (data, status, xhr) =>
        @fetch()
    )
