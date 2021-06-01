# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :livereload, port: '35738' do
  watch(%r{app/views/.+\.(erb|haml|slim)$})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|js|coffee|html|png|jpg))).*}) { |m| "/assets/#{m[3]}" }
  watch(%r{(app|vendor)(/assets/\w+/(.+)\.(scss))}) { |m| "/assets/#{m[3]}.css" }
  watch(%r{(app|vendor)(/assets/\w+/(.+)\.(svg))}) { |m| "/assets/#{m[3]}.svg" }
end
