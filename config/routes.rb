# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Rails.application.routes.draw do

  # app init
  match '/init', to: 'init#index', via: :get
  match '/app',  to: 'init#index', via: :get

  # just remember to delete public/index.html.
  root to: 'init#index', via: :get
  root to: 'errors#routing', via: %i[post put delete options]

  # load routes from external files
  dir = File.expand_path(__dir__)
  files = Dir.glob( "#{dir}/routes/*.rb" )
  files.each do |file|
    if Rails.configuration.cache_classes
      require_dependency file
    else
      load file
    end
  end

  match '*a', to: 'errors#routing', via: %i[get post put delete options]
end
