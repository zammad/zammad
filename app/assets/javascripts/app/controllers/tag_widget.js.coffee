$ = jQuery.sub()

class App.TagWidget extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    @attribute_id = 'tags_' + @object.id + '_' + @object_type
    App.Com.ajax(
      id:    @attribute_id
      type:  'GET'
      url:   'api/tags'
      data:
        object: @object_type
        o_id:   @object.id
      processData: true
      success: (data, status, xhr) =>
        @render(data.tags)
    )

  render: (tags) =>

    # insert data
    @html App.view('tag_widget')(
      tags: tags || [],
      tag_id: @attribute_id
    )
    @el.find('#' + @attribute_id ).tagsInput(
      width:       '150px'
      defaultText: App.i18n.translateContent('add a Tag')
      onAddTag:    @onAddTag
      onRemoveTag: @onRemoveTag
#      height: '65px'
    )
    @delay @siteUpdate, 200

#    @el.find('#tags').elastic()

  onAddTag: (item) =>
    App.Com.ajax(
      type:  'GET',
      url:   'api/tags/add',
      data:
        object: @object_type,
        o_id:   @object.id,
        item:   item
      processData: true,
      success: (data, status, xhr) =>
        @siteUpdate()
    )

  onRemoveTag: (item) =>
    App.Com.ajax(
      type:  'GET'
      url:   'api/tags/remove'
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true
      success: (data, status, xhr) =>
        @siteUpdate(true)
    )

  siteUpdate: (reorder) =>
    container = document.getElementById(@attribute_id + '_tagsinput')
    if reorder
      $('#' + @attribute_id + '_tagsinput').height( 20 )
    height = container.scrollHeight
    $('#' + @attribute_id + '_tagsinput').height( height - 10 )
