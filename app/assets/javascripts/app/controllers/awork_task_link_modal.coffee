class App.AworkTaskLinkModal extends App.ControllerModal

  fetchTasksByProject: (projectId) ->
    @ajax(
      id:    'projects'
      type:  'GET'
      url:   "#{@apiPath}/integration/awork/projects/#{projectId}/tasks"
      processData: true
      success: (data, status, xhr) =>
        @taskList = data.response
    )

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
    )



    content