class App.KnowledgeBasePublicMenuFormItem extends App.Controller
  events:
    'click .js-add':    'add'
    'click .js-remove': 'remove'
    'input input':      'input'

  elements:
    '.js-alert': 'alert'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('knowledge_base/public_menu_form_item')(
      rows:  @menu_items
      title: @kb_locale.systemLocale().name
    )

    @applySortable()

  applySortable: ->
    dndOptions =
      tolerance: 'pointer'
      distance:  15
      opacity:   0.6
      items:     'tr.sortable'
      start:     (e, ui) ->
        ui.placeholder.height( ui.item.height() )
      helper:    (e, tr) ->
        originals = tr.children()
        helper = tr
        helper.children().each (index, el) ->
          # Set helper cell sizes to match the original sizes
          $(@).width( originals.eq(index).width() )
        return helper
      update:    @dndCallback
      stop:      (e, ui) ->
        ui.item.children().each (index, element) ->
          element.style.width = ''

    @el.find('tbody').sortable(dndOptions)

  toggleUserInteraction: (enabled) ->
    if enabled
      App.ControllerForm.enable(@el)
    else
      App.ControllerForm.disable(@el)

    @$('.js-remove, .js-add').attr('disabled', !enabled)
    @el.find('tbody').sortable(disabled: !enabled)

  buildData: ->
    items = @$('tr.sortable')
            .toArray()
            .map (elem) -> $(elem)
            .map (elem) ->
              {
                id:       elem.data('id')
                title:    elem.find('input[data-name=title]').val()
                url:      elem.find('input[data-name=url]').val()
                new_tab:  elem.find('input[data-name=new_tab]').prop('checked')
                _destroy: elem.hasClass('js-deleted')
              }

     {
       kb_locale_id: @kb_locale.id,
       location:     @location,
       menu_items:   items
     }

  input: ->
    if !@hasError()
      @parent.clearAlerts()

  add: ->
    el = App.view('knowledge_base/public_menu_form_item_row')()
    $(el).insertBefore(@$('tr:has(.js-add)'))

  remove: (e) ->
    row = $(e.currentTarget).closest('tr')

    if row.data('id')
      row.toggleClass('settings-list--deleted js-deleted')
      row.find('.js-remove input').prop('checked', row.hasClass('settings-list--deleted'))
      row.find('.js-new-tab input').attr('disabled', row.hasClass('js-deleted'))
    else
      row.remove()

  findEmptyFields: ->
    @$('tr.sortable:not(.js-deleted)')
      .find('input[data-name]')
      .toArray()
      .filter (elem) -> $(elem).val().length == 0

  hasError: ->
    if @findEmptyFields().length == 0
      return false

    'Please fill in all fields'
