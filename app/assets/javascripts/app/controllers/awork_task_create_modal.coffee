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

    @searchableSelectProject = new App.SearchableSelect(
      el: content.find('#awork-task-create-project-select')
      attribute:
        name: 'task::project'
        value: 0
        null: false
        translate: true
        placeholder: __('Select Project...')
        options: [{
          name: 'Test Projektname',
          value: 'asfshjktzk5465jz567jjs5j'
        }]
    )

    @formController = new App.ControllerForm(
      el: content.find('.js-form')
      params:
        task:
          name: @nameTemplate()
          description:
            body:
              text: @descriptionTemplate()
      model:
        configure_attributes: [
          {
            name: 'task::name'
            model: 'task'
            display: __('Title')
            tag: 'input'
          }
          {
            name: 'task::description::body'
            model: 'task'
            display: __('Description')
            tag: 'richtext'
          }
          {
            name: 'task::status'
            model: 'task'
            display: __('State')
            tag: 'select'
            null: true
            options: [
              {
                value: 1
                name: 'Metal'
              }
              {
                value: 2
                name: 'Alkali metal'
              }
            ]
            grid_width: '1/2'
          }
          {
            name: 'task::type'
            model: 'task'
            display: __('Type')
            tag: 'select'
            null: true
            options: [
              {
                value: 1
                name: 'Metal'
              }
              {
                value: 2
                name: 'Alkali metal'
              }
            ]
            grid_width: '1/2'
          }
        ]
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
    console.log(params)

    @ajax(
      id:    'create-task'
      type:  'POST'
      url:   "#{@apiPath}/integration/awork/tasks/create"
      data:  JSON.stringify({
        linked_tasks: @taskLinks,
        ticket_id: @ticket.id,
        create_task: {
          name: params.task.name[0],
          description: if params.task.description.body.includes(@descriptionTicketLink) then params.task.description.body else @prependLink(params.task.description.body)
          taskStatusId: params.task.status[0]
          typeOfWorkId: params.task.type[0]
          entityId: params.task.project[0]
          baseType: 'projecttask' # always stays the same
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
