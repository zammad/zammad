class App.AworkTaskLinkModal extends App.ControllerModal

  content: ->
    content = $( App.view('integration/awork/task_link_modal')() )

    # Create project select
    @ajax(
      id:    'projects'
      type:  'GET'
      url:   "#{@apiPath}/integration/awork/projects"
      processData: true
      success: (data, status, xhr) =>
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
                @taskList = data.response.map (task) -> {
                  status: 'test',
                  title: task.name,
                  assignees: 'assignees'
                }

                @searchableSelectTask = new App.ControllerTable(
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
                  pagerItemsPerPage: 30
                )
            )
          currentValue = newValue
    )

    content