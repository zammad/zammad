# Load the rails application
require File.expand_path('../application', __FILE__)

# load module used to get current user for active recorde observer
require 'user_info'

# Initialize the rails application
Zammad::Application.initialize!
