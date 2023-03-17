class App.KnowledgeBaseNewController extends App.Controller
  events:
    'submit form': 'submit'

  constructor: ->
    super

    @render()

  render: ->
    @formController = new App.ControllerForm(
      model:                           App.KnowledgeBase
      screen:                          'admin_create'
      autofocus:                       false
      formClass:                       'settings-entry'
      fullForm:                        true
      fullFormSubmitLabel:             __('Create Knowledge Base')
      fullFormButtonsContainerClass:   'justify-end'
      fullFormSubmitAdditionalClasses: 'btn--success'
    )

    @el.html @formController.form

  prepareParams: (params) ->
    for key, attribute of App.KnowledgeBase.attributesGet(@formController.screen)
      dom = @$(".#{attribute.tag}[data-attribute-name=#{attribute.name}]")
      App.UiElement[attribute.tag].prepareParams?(attribute, dom, params)

  applyDefaults: (params) ->
    params['iconset']           = 'FontAwesome'
    params['color_highlight']   = '#38ae6a'
    params['color_header']      = '#f9fafb'
    params['color_header_link'] = 'hsl(206,8%,50%)'
    params['homepage_layout']   = 'grid'
    params['category_layout']   = 'grid'

  submit: (e) ->
    @preventDefaultAndStopPropagation(e)

    params = @formParam(@el)
    @prepareParams(params)
    @applyDefaults(params)

    @formDisable(@el)

    @ajax(
      type: 'POST'
      data: JSON.stringify(params)
      url:  App.KnowledgeBase.manageUrl

      success: (data) =>
        @parentVC.fetchAndRender()

      error: (xhr) =>
        @formEnable(@el)
        @formController.showAlert(xhr.responseJSON?.error || __('The Knowledge Base could not be created.'))
    )
