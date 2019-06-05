class App.MultiLocalesRow extends App.Controller
  tag: 'tr'

  elements:
    '.js-primary input':     'primaryCheckbox'
    '.js-remove input':      'removeButton'
    '.js-selectorContainer': 'selectorContainer'

  events:
    'change .js-shadow': 'change'

  constructor: ->
    super
    @el.data('kbLocaleId', @kb_locale?.id)
    @render()

  render: ->
    @html App.view('generic/multi_locales_row')(
      attribute: @attribute
      kb_locale: @kb_locale
    )

    value = @kb_locale?.systemLocale()?.id

    @_updateButtons(value, @solo , @kb_locale?.primary)

    @selector = @localesSelectBuild(@attribute.name, value, @selectorContainer)
    @updateOptions(@available_locales)

  localesSelectBuild: (name, value, el) ->
    new App.SearchableSelect(
      el: el
      attribute:
        name:        name
        value:       value
        null:        false
        placeholder: 'Select locale...'
        options:     [] #formattedLocales
        class:       'form-control--small'
    )

  updateOptions: (options) ->
    value = @selector.shadowInput.val() # @selector.attribute.value

    formattedLocales = options
      .map (elem) ->
        {
          name: elem.name
          value: elem.id
          selected: (elem.id + '') == value
        }

    formattedLocales.sort (a, b) -> a.name.localeCompare(b.name)

    @selector.attribute.options = formattedLocales
    @selector.render()

  updateButtons: (is_solo, is_primary = undefined) ->
    if is_primary == undefined
      is_primary = @primaryCheckbox[0].checked

    @_updateButtons(@selector.shadowInput.val(), is_solo, is_primary)

  _updateButtons: (value, is_solo, is_primary) ->
    is_deleted = @el.hasClass('settings-list--deleted')

    @removeButton.attr('disabled',    is_solo || !value || is_primary)
    @primaryCheckbox.attr('disabled', is_solo || !value || is_deleted)
    @primaryCheckbox.prop('checked' , is_primary)

  change: ->
    @primaryCheckbox.attr 'value', @selector.shadowInput.val()

  toggleDelete: ->
    @el.toggleClass('settings-list--deleted')
    @removeButton.prop('checked', @el.hasClass('settings-list--deleted'))
    @selector.el.toggleClass('u-unclickable')
