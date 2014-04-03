class App.WidgetTag extends App.Controller
  constructor: ->
    super
    @load()

    # update box size
    @bind 'ui:rerender:content', =>
      @siteUpdate()
    @bind 'ui:rerender:task', =>
      @siteUpdate()

  load: =>
    @attribute_id = 'tags_' + @object.id + '_' + @object_type
    @ajax(
      id:    @attribute_id
      type:  'GET'
      url:   @apiPath + '/tags'
      data:
        object: @object_type
        o_id:   @object.id
      processData: true
      success: (data, status, xhr) =>
        @render(data.tags)
    )

  render: (tags) =>

    # insert data
    @html App.view('widget/tag')(
      tags: tags || [],
      tag_id: @attribute_id
    )
    @el.find('#' + @attribute_id ).tokenfield().on(
      'tokenfield:createtoken'
      (e) =>
        @onAddTag( e.token.value )
    ).on(
      'tokenfield:removetoken'
      (e) =>
        @onRemoveTag( e.token.value )
    )
    @el.find('#' + @attribute_id ).parent().css('height', 'auto')

  onAddTag: (item) =>
    @ajax(
      type:  'GET',
      url:   @apiPath + '/tags/add',
      data:
        object: @object_type,
        o_id:   @object.id,
        item:   item
      processData: true,
    )

  onRemoveTag: (item) =>
    @ajax(
      type:  'GET'
      url:   @apiPath + '/tags/remove'
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true
    )
