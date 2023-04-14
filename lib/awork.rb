class Awork
  attr_reader :client

  def initialize(endpoint, api_token)
    @client = Awork::HttpClient.new(endpoint, api_token)
  end

  def verify
    Awork::Credentials.new(client).verify
  end

  def linked_tasks(ids)
    tasks = []
    for id in ids
      task = client.perform('get', "tasks/#{id}")

      next if !task

      tasks.append(Awork::Task.new(
        client,
        task
      ).to_h)
    end
    tasks
  end

  def projects
    result = client.perform('get', 'projects')
    result.map { |project| Awork::Project.new(client, project).to_h }
  end

  def types_of_work
    result = client.perform('get', 'typeofwork')
    result.map { |type| Awork::TypeOfWork.new(client, type).to_h }
  end

  def tasks_by_project(id)
    return if !id
    result = client.perform('get', "projects/#{id}/projecttasks")
    return if !result
    result.map { |task| Awork::Task.new(client, task).to_h }
  end

  def create(task)
    status_id = get_todo_status_for_project(task['projectId'])

    result = client.perform('post', 'tasks', {
      'name': task['name'],
      'description': task['description'],
      'typeOfWorkId': task['typeOfWorkId'],
      'taskStatusId': status_id,
      'entityId': task['projectId'],
      'baseType': 'projecttask',
    })

    return if !result

    Awork::Task.new(client, result).to_h
  end

  private

  def get_todo_status_for_project(project_id)
    status_list = client.perform('get', "projects/#{project_id}/taskstatuses")
    return if !status_list
    filtered = status_list.select { |status| status['type'] == 'todo' }

    filtered[0]['id']
  end
end