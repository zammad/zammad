# Abstract base class for Link controllers
class App.WidgetLink extends App.Controller
  @extend App.PopoverProvidable

  @popoversDefaults:
    position: 'left'

  events:
    'click .js-add': 'add'
    'click .js-delete': 'delete'

  constructor: ->
    super

    # if links are given, do not init fetch
    if @links
      @localLinks = _.clone(@links)
      @render()
      return

    @fetch()

  fetch: =>
    # fetch item on demand
    # get data
    @ajax(
      id:   "links_#{@object.id}_#{@object_type}"
      type: 'GET'
      url:  "#{@apiPath}/links"
      data:
        link_object:       @object_type
        link_object_value: @object.id
      processData: true
      success: (data, status, xhr) =>
        @localLinks = data.links
        App.Collection.loadAssets(data.assets)
        @render()
    )

  reload: (links) =>
    @localLinks = _.clone(links)
    @render()

  delete: (e) =>
    e.preventDefault()
    link_type   = $(e.currentTarget).data('link-type')
    link_object_source = $(e.currentTarget).data('object')
    link_object_source_value = $(e.currentTarget).data('object-id')
    link_object_target = @object_type
    link_object_target_value = @object.id

    # get data
    @ajax(
      id:   "links_remove_#{@object.id}_#{@object_type}"
      type: 'DELETE'
      url:  "#{@apiPath}/links/remove"
      data: JSON.stringify
        link_type:                link_type
        link_object_source:       link_object_source
        link_object_source_value: link_object_source_value
        link_object_target:       link_object_target
        link_object_target_value: link_object_target_value
      processData: true
      success: (data, status, xhr) =>
        @fetch()
      error: (xhr, statusText, error) =>
        @notify(
          type:      'error'
          msg:       App.i18n.translateContent(xhr.responseJSON?.error || "Couldn't save changes")
          removeAll: true
        )
    )
