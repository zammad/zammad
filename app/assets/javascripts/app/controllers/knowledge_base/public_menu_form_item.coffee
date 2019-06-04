class App.KnowledgeBasePublicMenuFormItem extends App.Controller
  events:
    'click .js-add':    'add'
    'click .js-remove': 'remove'
    'input input':      'input'
    'submit form':      'submit'

  elements:
    '.js-alert': 'alert'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('knowledge_base/public_menu_form_item')(
      kb_locale_id: @kb_locale.id
      rows:         @menu_items
      title:        @kb_locale.systemLocale().name
    )

    @applySortable()

  applySortable: ->
    dndOptions =
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      items:                'tr.sortable'
      start: (e, ui) ->
        ui.placeholder.height( ui.item.height() )
      helper: (e, tr) ->
        originals = tr.children()
        helper = tr
        helper.children().each (index, el) ->
          # Set helper cell sizes to match the original sizes
          $(@).width( originals.eq(index).width() )
        return helper
      update: @dndCallback
      stop: (e, ui) ->
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
       kb_locale_id: @$('form').data('kb-locale-id'),
       menu_items: items
     }

  input: ->
    if @validateForm(false)
      @hideAlert()

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

  showAlert: (message) ->
    translated = App.i18n.translatePlain(message)

    @alert
      .text(translated)
      .removeClass('hidden')

  hideAlert: ->
    @alert.addClass('hidden')

  emptyFields: ->
    @$('tr.sortable:not(.js-deleted)')
      .find('input[data-name]')
      .toArray()
      .filter (elem) -> $(elem).val().length == 0

  validateForm: (showAlert = true) ->
    if @emptyFields().length == 0
      return true

    if showAlert
      @showAlert('Please fill in all fields')

    false

  submit: (e) ->
    @preventDefaultAndStopPropagation(e)

    if !@validateForm()
      return

    @hideAlert()
    @toggleUserInteraction(false)

    kb = App.KnowledgeBase.find(@knowledge_base_id)

    @ajax(
      id:   'update_menu_items'
      type: 'PATCH'
      url:  kb.manageUrl('update_menu_items')
      data: JSON.stringify(@buildData())
      processData: true
      success: (data, status, xhr) =>
        for menu_item in App.KnowledgeBaseMenuItem.using_kb_locale(@kb_locale)
          menu_item.remove(clear: true)

        App.Collection.loadAssets(data.assets)

        @menu_items = App.KnowledgeBaseMenuItem.using_kb_locale(@kb_locale)
        @render()
      error: (xhr) =>
        @showAlert(xhr.responseJSON?.error_human || 'Couldn\'t save changes')
        @toggleUserInteraction(true)
    )
