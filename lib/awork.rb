class Awork
  attr_reader :client

  def initialize(endpoint, api_token)
    @client = Awork::HttpClient.new(endpoint, api_token)
  end

  def verify
    Awork::Credentials.new(client).verify
  end

  def linked_tasks(ids)
    ids.map do |id|
      Awork::Task.new(
        client,
        client.perform('get', "tasks/#{id}")
      ).to_h
    end
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
    result.map { |task| Awork::Task.new(client, task).to_h }
  end

  def create(task)
    result = client.perform('post', 'tasks', {
      'name': task['name'],
      'description': task['description'],
      'typeOfWorkId': task['typeOfWorkId'],
      'entityId': task['projectId'],
      'baseType': 'projecttask',
    })

    Awork::Task.new(client, result).to_h
  end
end