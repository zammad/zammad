# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|

  config.around(:each, :required_envs) do |example|
    example.metadata[:required_envs].each do |secret|
      if ENV[secret].blank?
        raise "This test requires the ENV variables [#{required_envs.join(', ')}], but #{secret} was not found."
      end
    end
    example.run
  end
end
