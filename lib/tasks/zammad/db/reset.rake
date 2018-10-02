namespace :zammad do

  namespace :db do

    desc 'Truncates and reseeds the database, clears the Cache and reloads the Settings'
    task reset: :environment do
      DatabaseCleaner.clean_with(:truncation)
      Rails.application.load_seed
      Cache.clear
      Setting.reload
    end
  end
end
