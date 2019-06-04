class App.KnowledgeBaseDelete extends App.KnowledgeBaseForm
  isTitleMatching: ->
    title = @object().guaranteedTitle()
    confirmedTitle = @formParam(@el).title
    confirmedTitle == title

  submit: (e) ->
    @preventDefaultAndStopPropagation(e)

    formController = @formControllers[0]

    if !@isTitleMatching()
      formController.showAlert(App.i18n.translateInline('Please enter title to confirm'))
      return

    formController.hideAlert()

    loader = new App.ControllerModalLoading(
      container: @parentVC.el
    )

    @ajax(
      id:          'knowledge_bases'
      type:        'DELETE'
      url:         @object().manageUrl()
      processData: true
      success:     (data, status, xhr) =>
        loader.hide()
        @parentVC.clear()
      error:       (xhr) =>
        formController.showAlert(xhr.responseJSON?.error || @T('Unable to proccess request'))
        loader.hide()
    )

  buildFormController: ->
    new App.ControllerForm(
      fullForm:                        true
      formClass:                       'settings-entry'
      fullFormButtonsContainerClass:   'justify-end'
      fullFormSubmitLabel:             'Delete Knowledge Base'
      fullFormSubmitAdditionalClasses: 'btn--danger'
      model:
        configure_attributes: [
          {
            name:    'title'
            model:   'translation'
            style:   'block'
            null:    true
            display: 'Delete this Knowledge Base'
            help:    "This action cannot be undone. This will permanently delete \"#{@object().guaranteedTitle()}\". Please type in the name \"#{@object().guaranteedTitle()}\" of the Knowledge Base to confirm."
            tag:     'input'
          }
        ]
    )
