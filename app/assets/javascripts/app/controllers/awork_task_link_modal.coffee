class App.AworkTaskLinkModal extends App.ControllerModal

  constructor: (params) ->
    super
    @ticket_id = params['ticket_id']
    @taskLinks = params['taskLinks']

  content: ->
    content = $( App.view('integration/awork/task_link_modal')() )

    # Create project select
    @ajax(
      id:    'projects'
      type:  'GET'
      url:   "#{@apiPath}/integration/awork/projects"
      processData: true
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return
        @projectList = data.response

        @searchableSelectProject = new App.SearchableSelect(
          el:         content.find('#awork-task-link-project-select')
          attribute:
            name:         'project'
            value:        0
            null:         false
            translate:    true
            placeholder:  'Select Project...'
            options:      @projectList.map (project) -> {
              name: project.name,
              value: project.id
            }
        )

        currentValue = ''
        $(@searchableSelectProject.element).on 'change .js-shadow', (e) =>
          newValue = @searchableSelectProject.shadowInput.val()
          if newValue.length > 0 && currentValue != newValue
            @ajax(
              id:    'projects'
              type:  'GET'
              url:   "#{@apiPath}/integration/awork/projects/#{newValue}/tasks"
              processData: true
              success: (data, status, xhr) =>
                if data.result is 'failed'
                  new App.ControllerErrorModal(
                    message: data.message
                    container: @el.closest('.content')
                  )
                  return
                @taskList = data.response.map (task) -> {
                  id: task.id
                  status: task.status,
                  title: task.name,
                  assignees: task.assignees.join(', ')
                }

                @taskSelectTable = new App.ControllerTable(
                  tableId:  'awork-task-link-task-select-table'
                  el:       content.find('#awork-task-link-task-select')
                  overview: [ 'status', 'title', 'assignees']
                  attribute_list: [
                    { name: 'status',       display: 'Status',        type: 'text' },
                    { name: 'title',        display: 'Title',         type: 'text' },
                    { name: 'assignees',    display: 'Assignees',     type: 'text' },
                  ]
                  objects: @taskList
                  checkbox: true
                  pagerItemsPerPage: 10
                )
            )
          currentValue = newValue
    )

    content

  onSubmit: (e) ->
    @startLoading()

    if !@taskSelectTable
      @stopLoading()
      @close()
      return

    selectedIds = @taskSelectTable.getBulkSelected()
    @taskLinks.concat(selectedIds)

    @ajax(
      id:    'link-tasks'
      type:  'POST'
      url:   "#{@apiPath}/integration/awork/tasks/update"
      data:  JSON.stringify(
        linked_tasks: @taskLinks
        ticket_id: @ticket_id
      )
      success: (data, status, xhr) =>
        if data.result is 'failed'
          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return

        @callback()
        @stopLoading()
        @close()
    )
