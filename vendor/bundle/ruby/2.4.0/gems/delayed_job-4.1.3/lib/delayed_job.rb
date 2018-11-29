require 'active_support'
require 'delayed/compatibility'
require 'delayed/exceptions'
require 'delayed/message_sending'
require 'delayed/performable_method'

if defined?(ActionMailer)
  require 'action_mailer/version'
  require 'delayed/performable_mailer'
end

require 'delayed/yaml_ext'
require 'delayed/lifecycle'
require 'delayed/plugin'
require 'delayed/plugins/clear_locks'
require 'delayed/backend/base'
require 'delayed/backend/job_preparer'
require 'delayed/worker'
require 'delayed/deserialization_error'
require 'delayed/railtie' if defined?(Rails::Railtie)

Object.send(:include, Delayed::MessageSending)
Module.send(:include, Delayed::MessageSendingClassMethods)
