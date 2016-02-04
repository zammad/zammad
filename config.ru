# This file is used by Rack-based servers to start the application.

# set config to do no self notification
Rails.configuration.webserver_is_active = true

require ::File.expand_path('../config/environment',  __FILE__)
run Zammad::Application
