namespace :bs do
  desc 'Bootstrap the application'
  task :init => %i[db:create db:migrate db:seed] do
    run_auto_wizard
  end

  desc 'Reset the application to its initial state'
  task :reset => %i[db:reset] do
    run_auto_wizard
    flush_cache_and_logs
  end
end

APP_CACHE   = Dir.glob(Rails.root.join('tmp', 'cache*'))
SERVER_LOG  = Rails.root.join('log', "#{Rails.env}.log")
AUTO_WIZARD = { source:      Rails.root.join('contrib', 'auto_wizard_test.json'),
                destination: Rails.root.join('auto_wizard.json') }.freeze

def flush_cache_and_logs
  FileUtils.rm_rf(APP_CACHE)
  File.write(SERVER_LOG, '')
end

def run_auto_wizard
  FileUtils.ln(AUTO_WIZARD[:source], AUTO_WIZARD[:destination], force: true)
  system('rails runner "AutoWizard.setup"')
end
