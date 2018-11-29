require 'delayed_job'
require 'rails'

module Delayed
  class Railtie < Rails::Railtie
    initializer :after_initialize do
      ActiveSupport.on_load(:action_mailer) do
        ActionMailer::Base.extend(Delayed::DelayMail)
      end

      Delayed::Worker.logger ||= if defined?(Rails)
        Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      end
    end

    rake_tasks do
      load 'delayed/tasks.rb'
    end
  end
end
