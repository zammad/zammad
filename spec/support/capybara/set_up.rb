# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.before(:each, type: :system) do |example|
    # check if system should get set up
    next if !example.metadata.fetch(:set_up, true)

    # check if system is already set up and perform setup via auto_wizard if needed
    Rake::Task['zammad:setup:auto_wizard'].execute if !Setting.get('system_init_done')

    # skip intro/clues for created agents/admins
    %w[admin@example.com agent1@example.com].each do |login|
      user = User.find_by(login: login)
      user.preferences[:intro] = true
      user.save!
    end
  end
end
