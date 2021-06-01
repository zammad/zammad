# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/first_steps',              to: 'first_steps#index',       via: :get
  match api_path + '/first_steps/test_ticket',  to: 'first_steps#test_ticket', via: :post

end
