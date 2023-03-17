class App.MultiLocales extends App.Controller
  events:
    'click .js-remove': 'remove'
    'click .js-primary': 'primary'
    'change .js-shadow': 'changeOnRow'

  constructor: ->
    super

    @multiple_rows_supported = App.Config.get('kb_multi_lingual_support')
    @rows = []
    @render()

    if @object
      @listenTo @object, 'refresh', @parentObjectUpdated

  parentObjectUpdated: =>
    App.Delay.set =>
      @attribute.value = @object.attributes()[@attribute.name]
      @render()

  render: ->
    @html App.view('generic/multi_locales')(attribute: @attribute, vc: @)

    if Array.isArray(@attribute.value)
      for locale in @attribute.value
        @appendRow @renderRow(locale, @attribute.value.length == 1)

    if @multiple_rows_supported || !Array.isArray(@attribute.value) || @attribute.value.length == 0
      @appendRow @renderRow()

  renderRow: (kb_locale_attributes, solo = false) ->
    kb_locale = App.KnowledgeBaseLocale.find kb_locale_attributes?.id

    new App.MultiLocalesRow(
      attribute:         @attribute
      kb_locale:         kb_locale
      available_locales: @selectableLocales(kb_locale?.systemLocale()?.id)
      solo:              solo
    )

  selectableLocales: (self_value) ->
    takenCodes = @$('.js-shadow')
      .toArray()
      .map (elem) -> $(elem).val()
      .filter (elem) -> elem && elem != self_value

    App.Locale.all().filter (elem) ->
      !_.includes(takenCodes, String(elem.id))

  remove: (e) ->
    domRow = $(e.currentTarget).closest('tr')[0]
    row = _.find @rows, (elem) -> elem.el[0] == domRow

    if row?.primaryCheckbox.prop('checked')
      return
    else if row?.kb_locale?.id
      row.toggleDelete()
    else
      row.el.remove()
      @rows.splice @rows.indexOf(row), 1

    @changeOnRow()

  primary: (e) ->
    input = $(e.currentTarget).find('input')

    if input.attr('disabled')
      return

    input.prop('checked', true)

    @changeOnRow()

  changeOnRow: (e) ->
    if !@hasEmptyRow() && @multiple_rows_supported
      @appendRow @renderRow()

    nonempty_rows = @rows.filter (row) -> row.selector.shadowInput.val()

    if nonempty_rows.length == 1
      nonempty_rows[0].updateButtons(true, true)
    else
      for row in nonempty_rows
        row.updateButtons(false)

    for row in @rows
      row.updateOptions( @selectableLocales(row.selector.shadowInput.val()) )

  hasEmptyRow: ->
    @$('.js-shadow').is (i, elem) -> !$(elem).val()

  appendRow: (row) ->
    @rows.push row
    @$('tbody').append row.el
