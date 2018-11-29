
require File.expand_path('../../rspec/logging_helper', __FILE__)
Spec::LoggingHelper = RSpec::LoggingHelper

if defined?  Spec::Runner::Configuration
  class Spec::Runner::Configuration
    include Spec::LoggingHelper
  end
end

