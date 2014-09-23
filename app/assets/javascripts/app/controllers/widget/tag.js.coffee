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

    @cacheKey = "tags::#{@object_type}::#{@object.id}"

    if @tags
      @render(@tags)
      return

    @tagList = App.Store.get( @cacheKey ) || []
    if !_.isEmpty(@tagList)
      @render()
      @delay(
        =>
          @fetch()
        1000
        'fetch'
      )
    else
      @fetch()

  fetch: =>
    @ajax(
      id:    @cacheKey
      type:  'GET'
      url:   @apiPath + '/tags'
      data:
        object: @object_type
        o_id:   @object.id
      processData: true
      success: (data, status, xhr) =>
        @tagList = data.tags
        App.Store.write( @cacheKey, @tagList )
        @render()
    )

  render: ->
    @html App.view('widget/tag')(
      tags: @tagList || [],
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

    if _.contains(@tagList, item)
      @render()
      return

    @tagList.push item
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
    item = $(e.target).parents('li').find('.tag').text()
    return if !item

    @tagList = _.filter(@tagList, (tagItem) -> return tagItem if tagItem isnt item )
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
