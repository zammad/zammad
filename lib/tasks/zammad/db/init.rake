namespace :zammad do

  namespace :db do

    desc 'Initializes (creates, migrates and seeds) the DB'
    task init: %i[zammad:db:unseeded db:seed]
  end
end
