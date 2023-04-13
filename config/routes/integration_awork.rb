Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/integration/awork/verify',                           to: 'integration/awork#verify',                 via: :post
  match api_path + '/integration/awork/tasks/create',                     to: 'integration/awork#create',                 via: :post
  match api_path + '/integration/awork/tasks/update',                     to: 'integration/awork#update',                 via: :post
  match api_path + '/integration/awork/tasks/:ticket_id',                 to: 'integration/awork#linked_tasks',           via: :get
  match api_path + '/integration/awork/projects',                         to: 'integration/awork#projects',               via: :get
  match api_path + '/integration/awork/projects/:project_id/tasks',       to: 'integration/awork#tasks_by_project',       via: :get

end
