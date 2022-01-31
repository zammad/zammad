# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

if ENV['REDIS_URL'].present?
  Rails.application.config.action_cable.cable = {
    'adapter'        => 'redis',
    'url'            => ENV['REDIS_URL'],
    'channel_prefix' => "zammad_#{Rails.env}"
  }
  Rails.logger.info 'Using the "Redis" adapter for ActionCable.'
else
  if ActiveRecord::Base.connection_config[:adapter] == 'mysql'
    raise 'Please provide a working redis instance via REDIS_URL - this is required on MySQL databases.'
  end

  # The 'postgresql' adapter does not work correctly in Capybara currently, so use
  #   'test' instead.
  if Rails.env.test?
    Rails.application.config.action_cable.cable = {
      'adapter' => 'test',
    }
    Rails.logger.info 'Using the "test" adapter for ActionCable.'
  else
    Rails.application.config.action_cable.cable = {
      'adapter' => 'postgresql',
    }
    Rails.logger.info 'Using the "PostgreSQL" adapter for ActionCable.'
  end
end
