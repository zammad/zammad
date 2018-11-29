require File.expand_path('../boot', __FILE__)

require 'action_controller/railtie'
require 'sprockets/railtie'

if defined?(Bundler)
  Bundler.require(*Rails.groups(assets: %w(development test)))
end

module App
  class Application < Rails::Application
    config.assets.enabled = true
  end
end
