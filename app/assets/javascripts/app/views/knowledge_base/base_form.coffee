class App.KnowledgeBaseForm extends App.Controller
  events:
    'submit form': 'submit'
    'hidden.bs.tab': 'didHide'

  additionalButtons: []

  didHide: ->
    @formControllers?.forEach (elem) -> elem.hideAlert()

  constructor: ->
    super
    @render()

  className: 'page-content'

  split: false

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

    #debuggerj
    formController = @formControllers.filter((elem) -> (elem.form[0] is e.currentTarget) or (e.currentTarget.contains(elem.form[0])))[0]
    params         = @formParam(formController.form)

    @prepareParams(params, formController.screen)
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
      error: (xhr) =>
        @formEnable(@el)
        formController.showAlert(xhr.responseJSON?.error || 'Unable to  save changes')
        @scrollTop()
    )

class App.KnowledgeBaseCustomAddressForm extends App.KnowledgeBaseForm
  events:
    'click .js-snippets': 'openSnippetsModal'

  elements:
    '.js-snippets': 'snippetsModalButton'

  additionalButtons: [
    className: 'js-snippets'
    text: 'Web Server Configuration'
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
          container:    @el.closest('.main')
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
          container: @el.closest('.main')
        )
    )
