class Awork
  attr_reader :client

  def initialize(endpoint, api_token)
    @client = Awork::HttpClient.new(endpoint, api_token)
  end

  def verify
    Awork::Credentials.new(client).verify
  end

  def linked_tasks(ids)

  end

  def projects

  end

  def tasks_by_project(id)

  end

  def create(task)

  end
end