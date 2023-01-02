# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Rails.application.routes.draw do

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # app init
  match '/init', to: 'init#index', via: :get
  match '/app',  to: 'init#index', via: :get

  # just remember to delete public/index.html.
  root to: 'init#index', via: :get
  root to: 'errors#routing', via: %i[post put delete options], as: nil

  # load routes from external files
  dir = File.expand_path(__dir__)
  files = Dir.glob("#{dir}/routes/*.rb")
  files.each do |file|
    if Rails.configuration.cache_classes
      require_dependency file
    else
      load file
    end
  end

  match '*a', to: 'errors#routing', via: %i[get post put delete options]
end
