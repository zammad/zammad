class Translation extends App.ControllerSubContent
  @requiredPermission: 'admin.translation'
  header: __('Translations')

  events:
    'click .js-description': 'showDescriptionModal'
    'click .js-new-translation': 'showNewTranslationModal'

  constructor: ->
    super

    @load()
    @controllerBind('i18n:translation_update_todo', @load)
    @controllerBind('i18n:translation_update_list', @load)
    @controllerBind('i18n:translation_update', @load)
    @controllerBind('toggle-shortcut-enable', => @rerender(true))
    @controllerBind('toggle-shortcut-layout', => @rerender(true))

  load: =>
    @startLoading()

    @ajax(
      id: 'translation_index'
      type: 'GET'
      url: "#{@apiPath}/translations/customized"
      processData: true
      success: (data) =>
        @stopLoading()
        @render(data)
    )

  getLocaleString: (value) ->
    App.Locale.findByAttribute('locale', value)?.name or value

  removeTranslation: (id) =>
    new App.ControllerConfirm(
      message: __('Are you sure?')
      buttonClass: 'btn--danger'
      callback: =>
        @startLoading(@$('.js-table-translations-container'))
        @ajax(
          id: 'translation_remove'
          type: 'DELETE'
          url: "#{@apiPath}/translations/#{id}"
          success: =>
            @stopLoading()
            @hasModifiedTranslations = true
            @load()
        )
      container: @el.closest('.content')
    )

  resetTranslation: (id) =>
    new App.ControllerConfirm(
      message: __('Are you sure?')
      buttonClass: 'btn--danger'
      callback: =>
        @startLoading(@$('.js-table-translations-container'))
        @ajax(
          id: 'translation_reset'
          type: 'PUT'
          url: "#{@apiPath}/translations/reset/#{id}"
          success: =>
            @stopLoading()
            @hasModifiedTranslations = true
            @load()
        )
      container: @el.closest('.content')
    )

  editTranslation: (data, id) =>
    translationData = _.find(data, (translationData) -> translationData.id is id)
    @showEditTranslationModal(translationData)

  renderTable: (customTranslationData, el) =>
    new App.ControllerTable(
      el: el
      overviewAttributes: ['source', 'target_initial', 'target', 'locale']
      attribute_list: [
        { name: 'source', display: __('Translation Source'), unsortable: true },
        { name: 'target_initial', display: __('Original Translation'), unsortable: true },
        { name: 'target', display: __('Custom Translation'), unsortable: true },
        { name: 'locale', display: __('Target Language'), unsortable: true },
      ]
      objects: customTranslationData
      bindRow:
        events:
          'click': (id) => @editTranslation(customTranslationData, id)
      customActions: [
        {
          name: 'edit',
          display: __('Edit')
          icon: 'pen'
          class: 'js-edit'
          callback: (id) => @editTranslation(customTranslationData, id)
        },
        {
          name: 'reset',
          display: __('Reset')
          icon: 'reload'
          class: 'btn--danger js-reset'
          callback: @resetTranslation
          available: (translationData) ->
            translationData.is_synchronized_from_codebase
        },
        {
          name: 'remove',
          display: __('Remove')
          icon: 'trash'
          class: 'btn--danger js-remove'
          callback: @removeTranslation
          available: (translationData) ->
            not translationData.is_synchronized_from_codebase
        },
      ]
      callbackAttributes:
        locale: [@getLocaleString]
    )

  render: (customTranslationData) =>
    content = $(App.view('translation/index')(
      hasDescriptionButton: customTranslationData.length > 0,
    ))

    if customTranslationData.length > 0
      @renderTable(customTranslationData, content.find('.js-content-container'))
    else
      content.find('.js-content-container').html(@description())

    @html content

  hide: =>
    @rerender()

  release: =>
    @rerender()

  rerender: (force) =>
    return if not @hasModifiedTranslations and not force

    App.Delay.set(->
      App.Event.trigger('ui:rerender')
    , 400)

  inlineTranslationKey: ->
    key = ''

    # In case of old shortcut layout, require hotkeys in the combination.
    key += "#{App.Browser.hotkeysDisplay().join('+')}+" if App.KeyboardShortcutPlugin.useOldShortcutLayout()
    key += 't'

    key

  description: ->
    $(App.view('translation/description')(
      inlineTranslationKey: @inlineTranslationKey()
      keyboardShortcutsEnabled: App.KeyboardShortcutPlugin.isEnabled()
    ))

  showDescriptionModal: =>
    new TranslationDescriptionModal
      contentInline: @description()
      container: @el.closest('.content')

  showNewTranslationModal: =>
    new TranslationModal
      headPrefix: __('New')
      container: @el.closest('.content')
      successCallback: =>
        @hasModifiedTranslations = true
        @load()

  showEditTranslationModal: (translationData) =>
    new TranslationModal
      headPrefix: __('Edit')
      data: translationData
      container: @el.closest('.content')
      successCallback: =>
        @hasModifiedTranslations = true
        @load()

class TranslationDescriptionModal extends App.ControllerModal
  head: __('Description')
  buttonSubmit: __('Close')
  shown: true

  onSubmit: =>
    @close()

class TranslationModal extends App.ControllerModal
  head: __('Translation')
  shown: true
  buttonSubmit: true
  buttonCancel: true
  large: true

  content: ->
    false

  render: =>
    super

    # If data is present, it means we are editing an existing translation.
    isEditingTranslation = Boolean(@data)

    content = $(App.view('translation/form')(isEditingTranslation: isEditingTranslation))

    # Always default to current user's language.
    locale = App.Locale.findByAttribute('locale', App.i18n.get())

    defaults =
      locale: locale.locale

    # Prepare locale options for the target language field.
    locale_options = _.reduce(App.Locale.all(), (acc, locale) ->
      acc[locale.locale] = locale.name
      acc
    , {})

    @form = new App.ControllerForm(
      el: content.find('.js-form')
      model:
        name: 'translation'
        configure_attributes: [
          { name: 'source', display: __('Translation Source'), tag: 'textarea', rows: 3, null: false, disabled: isEditingTranslation, item_class: 'formGroup--halfSize' },
          { name: 'target', display: __('Custom Translation'), tag: 'textarea', rows: 3, null: false, item_class: 'formGroup--halfSize' },
          { name: 'locale', display: __('Target Language'),    tag: 'searchable_select', options: locale_options, null: true, disabled: isEditingTranslation },
        ]
      params: @data || defaults
    )

    callback = (data) =>
      @objects = data.items
      table = @suggestionsTable()
      @el.find('.js-suggestionsTable').html(table.el)
      return if data.items.length >= data.total_count
      translatedMessageText = App.i18n.translateContent('The limit of displayable suggestions was reached, please narrow down your search.')
      $('<div />')
        .addClass('centered text-small text-muted')
        .text(translatedMessageText)
        .appendTo(@el.find('.js-suggestionsTable'))

    # Set up change handler on the locale selection and trigger refresh of suggestions.
    content.find('[name="locale"]')
      .off('change.loadSuggestions')
      .on('change.loadSuggestions', (e) =>
        @loadSuggestions($(e.target).val(), $('.js-suggestionsSearchInput').val(), callback)
      )

    debouncedLoadSuggestions = _.debounce(@loadSuggestions, 300)

    # Set up input handler on the search input and trigger refresh of suggestions.
    content.find('.js-suggestionsSearchInput')
      .off('input.loadSuggestions')
      .on('input.loadSuggestions', (e) -> debouncedLoadSuggestions($('[name="locale"]').val(), $(e.target).val(), callback))

    @el.find('.modal-body').html(content)

    if isEditingTranslation is false
      @loadSuggestions(locale.locale, '', callback)

  loadSuggestions: (locale, query, callback) =>
    @el.find('.js-suggestionsLoader').removeClass('hide')

    @ajax(
      id: 'translation_suggestions'
      type: 'GET'
      url: "#{@apiPath}/translations/search/#{locale}?query=#{encodeURIComponent(query)}"
      processData: true
      success: (data) =>
        @el.find('.js-suggestionsCounter').text(data.total_count)
        @el.find('.js-suggestionsCounterContainer').removeClass('hide')
        @el.find('.js-suggestionsLoader').addClass('hide')
        callback(data)
    )

  suggestionsTable: =>
    typeCallback = (value, object, attribute, attributes) ->
      return App.i18n.translateContent('system') if object.is_synchronized_from_codebase
      App.i18n.translateContent('custom')

    new App.ControllerTable(
      class: 'table-hover-in-modal'
      overviewAttributes: ['source', 'target_initial', 'type']
      attribute_list: [
        { name: 'source', display: __('Translation Source') },
        { name: 'target_initial', display: __('Original Translation') },
        { name: 'type', display: __('Type'), width: '50px' },
      ]
      objects: @objects
      radio: true
      bindRow:
        events:
          'click': @suggestionRowClick
      callbackAttributes:
        type: [typeCallback]
    )

  suggestionRowClick: (id, e) =>
    $(e.target).parents('tr').find('input[name="radio"]').prop('checked', true)
    object = _.find(@objects, (object) -> object.id is id)
    @acceptSuggestion(object)

  acceptSuggestion: (object) =>
    $('[name="source"]').val(object.source)
    $('[name="target"]').prop('placeholder', object.target_initial).val('').focus()

    @handleContributionAlert(object.is_synchronized_from_codebase)

  handleContributionAlert: (display = false) =>
    alert = @el.find('.js-contribution-alert')

    if not display
      alert.remove()
      return

    return if alert.length

    $('<div />')
      .attr('role', 'alert')
      .addClass('alert')
      .addClass('alert--warning')
      .addClass('js-contribution-alert')
      .html(App.i18n.translateContent('Did you know that system translations can be contributed and shared with the community on our public platform %l? It sports a very convenient user interface based on Weblate, give it a try!', 'https://translations.zammad.org'))
      .appendTo(@el.find('.modal-alerts-container'))

  onSubmit: (e) =>
    params = @formParam(e.target)
    error = @form.validate(params)

    if error
      @formValidate(form: e.target, errors: error)
      return false

    @formDisable(e)

    @ajax({
      id: 'translation_upsert',
      type: 'POST',
      url: "#{@apiPath}/translations/upsert",
      data: JSON.stringify(params),
      processData: true,
      success: (data) =>
        @close()
        @successCallback()

        # Later we should add real subscription handling for this situation in the new tech stack.
        currentLocale = App.i18n.get()
        if params.locale == currentLocale
          App.i18n.setMap(data.source, data.target)

    })

App.Config.set('Translation', {
  prio: 1800,
  parent: '#system',
  name: __('Translations'),
  target: '#system/translation',
  controller: Translation,
  permission: ['admin.translation']
}, 'NavBarAdmin')
