$ = jQuery.sub()

class App.TagWidget extends App.Controller
  constructor: ->
    super
    @load()

  load: =>
    App.Com.ajax(
      id:    'tags_' + @object.id + '_' + @object_type
      type:  'GET'
      url:   '/api/tags'
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
    )
    @el.find('#tags').tagsInput(
      width:       '150px'
      defaultText: App.i18n.translateContent('add a Tag')
      onAddTag:    @onAddTag
      onRemoveTag: @onRemoveTag
#      height: '65px'
    )
    @delay @siteUpdate, 100

#    @el.find('#tags').elastic()

  onAddTag: (item) =>
    App.Com.ajax(
      type:  'GET',
      url:   '/api/tags/add',
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
      url:   '/api/tags/remove'
      data:
        object: @object_type
        o_id:   @object.id
        item:   item
      processData: true
      success: (data, status, xhr) =>
        @siteUpdate(true)
    )

  siteUpdate: (reorder) =>
    container = document.getElementById("tags_tagsinput")
    if reorder
      $('#tags_tagsinput').height( 20 )
    height = container.scrollHeight
    $('#tags_tagsinput').height( height - 10 )
