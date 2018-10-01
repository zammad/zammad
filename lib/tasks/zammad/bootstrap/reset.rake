namespace :zammad do

  namespace :bootstrap do

    desc 'Resets a Zammad and reinitializes it'
    task reset: %i[
      db:drop
      zammad:db:init
      zammad:setup:auto_wizard
      zammad:flush
    ]
  end
end
