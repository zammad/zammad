# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|

  config.around(:each, :required_envs) do |example|
    example.metadata[:required_envs].each do |secret|
      if ENV[secret].blank?
        raise "This test requires the ENV variables [#{example.metadata[:required_envs].join(', ')}], but #{secret} was not found."
      end
    end

    VCR.configure do |c|
      example.metadata[:required_envs].each do |env_key|
        c.filter_sensitive_data("<#{env_key}>") { ENV[env_key] }
      end
    end

    example.run
  end
end
