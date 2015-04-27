Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # links
  match api_path + '/tags',                   to: 'tags#list',   via: :get
  match api_path + '/tags/add',               to: 'tags#add',    via: :get
  match api_path + '/tags/remove',            to: 'tags#remove', via: :get

end