# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :bootstrap do

    desc 'Resets a Zammad and reinitializes it'
    task reset: %i[
      db:drop
      zammad:db:init
      zammad:setup:auto_wizard
    ]
  end
end
