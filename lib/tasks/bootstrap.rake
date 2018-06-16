module BootstrapRakeHelper
  APP_CACHE   = Dir.glob(Rails.root.join('tmp', 'cache*'))
  SERVER_LOG  = Rails.root.join('log', "#{Rails.env}.log")
  AUTO_WIZARD = { source: Rails.root.join('contrib', 'auto_wizard_test.json'),
                  dest:   Rails.root.join('auto_wizard.json') }.freeze
  DB_CONFIG   = { source: Rails.root.join('config', 'database', 'database.yml'),
                  dest:   Rails.root.join('config', 'database.yml') }.freeze

  def flush_cache_and_logs
    FileUtils.rm_rf(APP_CACHE)
    File.write(SERVER_LOG, '')
  end

  def run_auto_wizard
    FileUtils.ln(AUTO_WIZARD[:source], AUTO_WIZARD[:dest], force: true)
    AutoWizard.setup

    # set system init to done
    UserInfo.current_user_id = 1
    Setting.set('system_init_done', true)
  end

  def add_database_config
    raise Errno::ENOENT, 'config/database.yml not found' unless File.exist?(DB_CONFIG[:source])

    if File.exist?(DB_CONFIG[:dest])
      return if FileUtils.identical?(DB_CONFIG[:source], DB_CONFIG[:dest])
      printf 'config/database.yml: File exists. Overwrite? [y/N] '
      return if STDIN.gets.chomp.downcase != 'y'
    end

    FileUtils.cp(DB_CONFIG[:source], DB_CONFIG[:dest])
  end
end

namespace :bs do
  desc 'Bootstrap the application'
  task :init => %i[db_config db:create db:migrate db:seed] do
    include BootstrapRakeHelper
    run_auto_wizard
  end

  desc 'Reset the application to its initial state'
  task :reset => %i[db:reset] do
    include BootstrapRakeHelper
    run_auto_wizard
    flush_cache_and_logs
  end

  task :db_config do
    include BootstrapRakeHelper
    add_database_config
  end
end
