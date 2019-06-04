class App.KnowledgeBaseContentCanBePublishedDialog extends App.ControllerModal
  events:
    'click .scheduled-widget-delete': 'clickedCancelTimer'
    'submit form':              'submitTiming'

  head: 'Visibility'
  includeForm: false
  buttonSubmit: false

  constructor: (params) ->
    super

  content: =>
    @formController = new App.KnowledgeBaseContentCanBePublishedForm(
      object: @object
    )

    @formController.form

  saveUpdate: (params, successCallback = null) =>
    @clearAlerts()
    @formController.toggleDisabled(true)

    @ajax(
      id:          'knowledge_base_can_be_published'
      type:        'POST'
      data:        JSON.stringify(params)
      url:         @object.generateURL('has_publishing_update')
      processData: true
      success:     (data, status, xhr) =>
        App.Collection.load(type: 'KnowledgeBaseAnswer', data: [data])
        successCallback?()
        @formController.toggleDisabled(false)
      error:       (xhr) =>
        @formController.toggleDisabled(false)
        @showAlert(xhr.responseJSON?.error || 'Unable to save changes')
    )

  clickedCancelTimer: (e) ->
    widget = $(e.currentTarget).closest('.scheduled-widget')
    state  = widget.data('state')
    params = { "#{state}_at": null }

    @saveUpdate params, ->
      widget.remove()

  submitTiming: (e) =>
    @preventDefaultAndStopPropagation(e)

    data = @formParams()

    params =
      "#{data.visibility}_at": if data.timing is 'scheduled' then data.scheduled else '--now--'

    newVisibilityIndex = @formController.states.indexOf(data.visibility)
    oldVisibilityIndex = @formController.states.indexOf(@formController.params.visibility)

    if newVisibilityIndex < oldVisibilityIndex
      for index in [(newVisibilityIndex+1)..oldVisibilityIndex]
        params["#{@formController.states[index]}_at"] = null

    @saveUpdate params, =>
      if data.timing is 'now'
        @close()
        return

      @update()
      @initalFormParams = @formParams()
