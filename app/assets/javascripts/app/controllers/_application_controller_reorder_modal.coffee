class App.ControllerReorderModal extends App.ControllerModal
  head: 'Drag to reorder'
  content: ->
    view = $(App.view('reorder_modal')())

    table = new App.ControllerTable(
      baseColWidth: null
      dndCallback: ->
        true
      overview: ['title']
      attribute_list: [
        { name: 'title', display: 'Name' }
      ]
      objects: @items
    )

    view.find('.js-table-container').html(table.el)

    view

  onShown: ->
    super
    @$('.js-submit').focus()

  save: ->
    ids = @$('tr.item').toArray().map (el) -> parseInt(el.dataset.id)

    @$('.alert').addClass('hidden')

    @formDisable(@el)

    @ajax(
      id: 'reorder_save'
      type: 'PATCH'
      data: JSON.stringify({ordered_ids: ids})
      url: @url
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data)
        App.Event.trigger 'knowledge_base::sidebar::rerender'
        @close()
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @$('.alert--danger').removeClass('hidden').text(data.error)
        @formEnable(@el)
    )

  onSubmit: ->
    super
    @save()

