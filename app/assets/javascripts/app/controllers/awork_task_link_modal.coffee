class App.AworkTaskLinkModal extends App.ControllerModal

  fetchProjects: ->
    @ajax(
      id:    'projects'
      type:  'GET'
      url:   "#{@apiPath}/integration/awork/projects"
      processData: true
      success: (data, status, xhr) =>
        @projectList = data.response.map (project) -> project.result
    )

  fetchTasksByProject: (projectId) ->
    @ajax(
      id:    'projects'
      type:  'GET'
      url:   "#{@apiPath}/integration/awork/projects/#{projectId}/tasks"
      processData: true
      success: (data, status, xhr) =>
        @taskList = data
    )

  content: ->
    content = $( App.view('integration/awork/task_link_modal')() )

    @fetchProjects()

    @searchableSelectProject = new App.SearchableSelect(
      el:         content.find('#awork-task-link-project-select')
      attribute:
        name:         'project'
        value:        0
        null:         false
        translate:    true
        placeholder:  App.i18n.translatePlain('Select locale…')
        options:      @projectList
    )

    content