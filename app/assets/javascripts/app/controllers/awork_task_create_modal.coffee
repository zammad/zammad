class App.AworkTaskCreateModal extends App.ControllerModal
  buttonCancel: true

  constructor: (params) ->
    super

    @ticket = params['ticket']
    @taskLinks = params['taskLinks']

  content: =>
    content = $( App.view('integration/awork/task_create_modal')(
      label: {
        project: __('Project')
      }
    ))

    @ajax(
      id:    'get-projects'
      type:  'GET'
      url:   "#{@apiPath}/integration/awork/projects"
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return

        @projectList = data.response

        @searchableSelectProject = new App.SearchableSelect(
          el: content.find('#awork-task-create-project-select')
          attribute:
            name: 'task::project'
            value: 0
            null: false
            translate: true
            placeholder: __('Enter Project Name')
            options: @projectList.map (project) => {
              name: project.name,
              value: project.id
            }
        )
    )

    @ajax(
      id:    'get-typesofwork'
      type:  'GET'
      url:   "#{@apiPath}/integration/awork/types_of_work"
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return []

        @typeofworkList = data.response

        @formController = new App.ControllerForm(
          el: content.find('.js-form')
          model:
            configure_attributes: [
              {
                name: 'task::name'
                model: 'task'
                display: __('Title')
                tag: 'input'
                type: 'text'
                default: @nameTemplate()
              }
              {
                name: 'task::description'
                model: 'task'
                display: __('Description')
                tag: 'richtext'
                default: @descriptionTemplate()
              }
              {
                name: 'task::type'
                model: 'task'
                display: __('Type')
                tag: 'select'
                null: true
                options: @typeofworkList.map (typeofwork) => {
                  name: typeofwork.name,
                  value: typeofwork.id
                }
              }
            ]
            className: ''
        )
    )

    content

  nameTemplate: =>
    "#{__('Ticket')}: \"#{@ticket.title}\""

  descriptionTemplate: =>
    descriptionTemplate = ''
    @descriptionTicketLink = "<a href=\"#{location.origin}#ticket/zoom/#{@ticket.id}\" target=\"_blank\">#{@ticket.title}</a>"
    if @ticket.article_count > 0
      latestArticleId = @ticket.article_ids.slice(-1)
      latestArticle = App.TicketArticle.find(latestArticleId)
      if latestArticle.body
        descriptionTemplate += "<blockquote>#{latestArticle.body.replace(/\n/g, '<br>')}</blockquote>"

    @prependLink(descriptionTemplate)

  prependLink: (str) =>
    "#{__('Ticket')}: #{@descriptionTicketLink}" + str

  onSubmit: (e) =>
    params = @formParams(e.target)
    validation = @formController.validate(params) || {}

    # add validation for project select
    if params.task.project[0] == '0'
      validation['task::project'] = 'is required'

    # add validation for name input
    if params.task.name[0] == ''
      validation['task::name'] = 'is required'

    App.ControllerForm.validate(
      form: @formController.form
      errors: validation
    )

    if !_.isEmpty(validation)
      return

    @startLoading()

    @ajax(
      id:    'create-task'
      type:  'POST'
      url:   "#{@apiPath}/integration/awork/tasks/create"
      data:  JSON.stringify({
        linked_tasks: @taskLinks,
        ticket_id: @ticket.id,
        create_task: {
          name: params.task.name[0],
          description: if params.task.description.includes(@descriptionTicketLink) then params.task.description else @prependLink(params.task.description)
          typeOfWorkId: params.task.type[0]
          projectId: params.task.project[0]
        }
      })
      success: (data, status, xhr) =>
        if data.result is 'failed'
          @stopLoading()
          @close()

          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return

        App.Event.trigger 'notify', {
          type: 'success'
          msg:  App.i18n.translateContent('Update successful.')
        }

        @callback(@taskLinks)
        @stopLoading()
        @close()
    )
