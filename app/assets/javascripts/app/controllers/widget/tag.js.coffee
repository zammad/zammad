class App.WidgetTag extends App.Controller
  constructor: ->
    super

    @attribute_id = 'tags_' + @object.id + '_' + @object_type
    tags = App.Store.get( "tags::#{@attribute_id}" )
    if tags
      @render( tags )
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
      id:    @attribute_id
      type:  'GET'
      url:   @apiPath + '/tags'
      data:
        object: @object_type
        o_id:   @object.id
      processData: true
      success: (data, status, xhr) =>
        App.Store.write( "tags::#{@attribute_id}", data.tags )
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
      success: (data, status, xhr) =>
        tags = @el.find('#' + @attribute_id ).val()
        if tags
          tags = tags.split(',')
        App.Store.write( "tags::#{@attribute_id}",  tags )
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
      success: (data, status, xhr) =>
        tags = @el.find('#' + @attribute_id ).val()
        if tags
          tags = tags.split(',')
        App.Store.write( "tags::#{@attribute_id}",  tags )
    )
