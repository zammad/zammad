class App.KnowledgeBaseNewModal extends App.ControllerModal
  head:   'Create Knowledge Base'
  screen: 'admin_create'

  buttonClose:   false
  buttonCancel:  false
  backdrop:      'static'
  keyboard:      false

  constructor: ->
    @formController = new App.ControllerForm(
      model:     App.KnowledgeBase
      params:    @item
      screen:    @screen
      autofocus: false
    )

    super

  content: ->
    @formController.form

  prepareParams: (params) ->
    for key, attribute of App.KnowledgeBase.attributesGet(@screen)
      dom = @$(".#{attribute.tag}[data-attribute-name=#{attribute.name}]")
      App.UiElement[attribute.tag].prepareParams?(attribute, dom, params)

  applyDefaults: (params) ->
    params['iconset']         = 'FontAwesome'
    params['color_highlight'] = '#38ae6a'
    params['color_header']    = '#f9fafb'
    params['homepage_layout'] = 'grid'
    params['category_layout'] = 'grid'

  onSubmit: (e) ->
    params = @formParams(@el)
    @prepareParams(params)
    @applyDefaults(params)

    @formDisable(@el)

    @ajax(
      type: 'POST'
      data: JSON.stringify(params)
      url:  App.KnowledgeBase.manageUrl

      success: (data) =>
        @parentVC.fetchAndRender()
        @parentVC.modal = undefined
        @close()

      error: (xhr) =>
        @formEnable(@el)
        @formController.showAlert(xhr.responseJSON?.error || "Couldn't create Knowledge Base")
    )
