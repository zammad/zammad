class App.KnowledgeBaseForm extends App.Controller
  events:
    'submit form': 'submit'
    'hidden.bs.tab': 'didHide'
  additionalButtons: []
  className: 'page-content'
  split: false

  didHide: ->
    @formControllers?.forEach (elem) -> elem.hideAlert()

  constructor: ->
    super
    @render()

  buildFormController: (screen) ->
    isVertical = @split && _.values(App.Model.attributesGet(screen, App.KnowledgeBase.configure_attributes))[0].horizontal

    new App.ControllerForm(
      screen:                          screen
      params:                          @object().attributes()
      model:                           App.KnowledgeBase
      formClass:                       'settings-entry'
      fullForm:                        !isVertical
      fullFormSubmitAdditionalClasses: 'btn--primary'
      fullFormButtonsContainerClass:   'justify-end'
      fullFormAdditionalButtons:       @additionalButtons
      parentController:                @
    )

  wrapFormElement: (formController) ->
    if formController.fullForm
      formController.form
    else
      new App.KnowledgeBaseVerticalForm(
        form: formController
      ).el

  render: ->
    matcher = "admin_#{@screen}"

    screen_keys = if @split
                    all_keys = _.flatten App.KnowledgeBase.configure_attributes.map (elem) -> Object.keys(elem.screen)
                    all_keys.filter (elem) -> elem.match(matcher)
                  else
                    [matcher]

    @formControllers = screen_keys.map (elem) => @buildFormController(elem)
    @html @formControllers.map (elem) => @wrapFormElement(elem)

  object: ->
    App.KnowledgeBase.find(@knowledge_base_id)

  scrollTop: ->
    @el.closest('.main').animate({scrollTop: 0})

  prepareParams: (params, screen) ->
    for key, attribute of App.KnowledgeBase.attributesGet(screen)
      dom = @$(".#{attribute.tag}[data-attribute-name=#{attribute.name}]")
      App.UiElement[attribute.tag].prepareParams?(attribute, dom, params)

  submit: (e) ->
    @preventDefaultAndStopPropagation(e)

    formController = @formControllers.filter((elem) -> (elem.form[0] is e.currentTarget) or (e.currentTarget.contains(elem.form[0])))[0]
    params         = @formParam(formController.form)

    @prepareParams(params, formController.screen)

    deletedLocaleAttrs = (params.kb_locales_attributes || []).filter (attr) -> attr._destroy is '1'

    if deletedLocaleAttrs.length > 0
      @confirmLocaleDeletion(deletedLocaleAttrs, formController, params)
    else if @iconsetChangeAffectsCategories(params)
      @confirmIconsetChange(formController, params)
    else
      @performSubmit(params, formController)

  # Switching the icon set resets the icons of all existing categories server-side, because icons
  # cannot be carried over between sets (see KnowledgeBase#reset_category_icons). Without any
  # categories there is nothing to lose, so the change is applied right away.
  iconsetChangeAffectsCategories: (params) ->
    return false if !params.iconset
    return false if params.iconset is @object().iconset

    @object().category_ids?.length > 0

  confirmIconsetChange: (formController, params) ->
    confirmed = false

    new App.ControllerConfirm(
      head:      __('Change icon set')
      message:   __('Icons cannot be carried over between icon sets. Switching the set will therefore reset all category icons to the default icon of the new set, and your current selections will be lost. Do you want to continue?')
      container: @el.closest('.content')
      callback: =>
        confirmed = true
        @performSubmit(params, formController, ->
          # Make sure the new icon set is reflected in the knowledge base browser, which is not part of this form.
          App.Event.trigger('ui:rerender')
        )
      # Covers every way out of the dialog, including the close icon and the escape key.
      onClosed: =>
        return if confirmed
        @restoreIconsetSelection(formController)
    )

  # A dismissed dialog leaves the picker highlighting a set which was never saved, so the stored one
  # is highlighted again — the same way App.IconsetPicker marks a pick, whose markup this follows.
  # Only the picker is touched, to keep unsaved input in the other forms of the screen.
  restoreIconsetSelection: (formController) ->
    iconset = @object().iconset

    formController.form.find('[name="iconset"]').val(iconset)
    formController.form.find('.js-set').removeClass('is-active')
    formController.form.find(".js-set[data-family=\"#{iconset}\"]").addClass('is-active')

  confirmLocaleDeletion: (deletedLocaleAttrs, formController, params) ->
    safeWord = __('Delete')
    message  = App.i18n.translatePlain('Removing %s language(s) will permanently delete all translation(s) related to them. Enter "%s" to confirm.', deletedLocaleAttrs.length, App.i18n.translatePlain(safeWord).toUpperCase())

    new App.ControllerConfirmDelete(
      head:         __('Remove Language')
      safeWord:     safeWord
      fieldDisplay: message
      callback: (modal) =>
        modal.close()
        @performSubmit(params, formController)
    )

  performSubmit: (params, formController, callback = null) ->
    @formDisable(@el)

    formController.hideAlert()

    @ajax(
      type: 'PATCH'
      data: JSON.stringify(params)
      url: @object().manageUrl() + '?full=true'
      success: (data) =>
        App.Collection.loadAssets(data.assets)

        @formEnable(@el)
        @scrollTop()
        callback() if callback?
      error: (xhr) =>
        @formEnable(@el)
        formController.showAlert(xhr.responseJSON?.error || __('Changes could not be saved.'))
        @scrollTop()
    )

class App.KnowledgeBaseCustomAddressForm extends App.KnowledgeBaseForm
  events:
    'click .js-snippets': 'openSnippetsModal'

  elements:
    '.js-snippets': 'snippetsModalButton'

  additionalButtons: [
    className: 'js-snippets'
    text: __('Web Server Configuration')
  ]

  formEnable: (el) ->
    super
    @updateSnippetsModalButton()

  render: ->
    super
    @updateSnippetsModalButton()

  updateSnippetsModalButton: ->
    snippetAvailable = @object().attributes().custom_address?.length > 0
    @snippetsModalButton.attr('disabled', !snippetAvailable)

  openSnippetsModal: (e) ->
    @preventDefaultAndStopPropagation(e)

    button = e.currentTarget
    button.disabled = true

    @ajax(
      id:          'knowledge_bases_init_admin'
      type:        'GET'
      url:         @object().manageUrl('server_snippets')
      processData: true
      success:     (data, status, xhr) =>
        button.disabled = false

        new App.KnowledgeBaseServerSnippet(
          container:    @el.closest('.content')
          snippets:     data.snippets
          address:      data.address
          address_type: data.address_type
        )
      error:       (xhr) =>
        button.disabled = false

        if xhr.status != 422
          return

        new App.ControllerErrorModal(
          message: xhr.responseJSON.error
          container: @el.closest('.content')
        )
    )
