class App.KnowledgeBaseDeleteAction
  constructor: (params) ->
    for key, value of params
      @[key] = value

    if @object instanceof App.KnowledgeBaseCategory and !@object.isEmpty()
      @showCannotDelete(
        'Cannot delete category',
        'Delete all child categories and answers, then try again.'
      )

      return

    @showConfirm()

  showConfirm: ->
    kb_locale   = @parentController.kb_locale()
    translation = @object.guaranteedTranslation(kb_locale.id)

    @dialog = new App.ControllerConfirm(
      head:      'Delete'
      message:   "Are you sure you want to delete \"#{translation?.title}\"?"
      callback:  @doDelete
      container: @parentController.el
      onSubmit: ->
        @formDisable(@el)
        @callback(@)
        @dialog = null
    )

  showCannotDelete: (title, message) ->
    modal = new App.ControllerModal(
      head:          title
      contentInline: message
      container:     @parentController.el
      buttonClose:   true
      buttonSubmit:  'Ok'
      onSubmit: (e) =>
        modal.close()
        @dialog = null
    )

    @dialog = modal

  doDelete: (modal) =>
    App.Ajax.request(
      type: 'DELETE'
      url:  @object.generateURL() + '?full=true'
      success: =>
        @deleteOk(modal)
      error: (xhr) =>
        @deleteFailure(modal, xhr)
    )

  deleteOk: (modal) =>
    futureObject = @object.parent?() || @object.category?() || @object.knowledge_base()

    @parentController.contentController.stopListening()
    @object.removeIncludingTranslations(clear: true)

    modal.close()

    @parentController.navigate futureObject.uiUrl(@parentController.kb_locale(), 'edit')

  deleteFailure: (modal, xhr) ->
    modal.formEnable(modal.el)
    modal.showAlert xhr.responseJSON?.error || 'Unable to delete.'

  # simulate modal's close function
  close: ->
    @dialog?.close()
