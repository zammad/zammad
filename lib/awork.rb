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
        client.perform('get', "tasks/#{ id }")
      )
    end
  end

  def projects
    result = client.perform('get', 'projects')
    result.map { |entity| Awork::Project.new(client, entity) }
  end

  def tasks_by_project(id)
    result = client.perform('get', "projects/#{id}/projecttasks")
    result.map { |entity| Awork::Task.new(client, entity) }
  end

  def create(task)
    result = client.perform('post', '/tasks', {
      'name': task['name'],
      'description': task['description'],
      'baseType': 'projecttask',
      'parentId': task['project_id']
    })

    Awork::Task.new(client, result)
  end
end