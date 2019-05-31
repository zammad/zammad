RSpec.configure do |config|
  config.before(:each, type: :system) do |example|

    # check if system is already set up
    next if Setting.get('system_init_done')

    # check if system should get set up
    next if !example.metadata.fetch(:set_up, true)

    # perform setup via auto_wizard
    Rake::Task['zammad:setup:auto_wizard'].execute

    # skip intro/clues for created agents/admins
    %w[master@example.com agent1@example.com].each do |login|
      user = User.find_by(login: login)
      user.preferences[:intro] = true
      user.save!
    end
  end
end
