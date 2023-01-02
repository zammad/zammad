# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :bootstrap do

    desc 'Initializes a Zammad for the first time'
    task init: %i[
      zammad:setup:db_config
      zammad:db:init
      zammad:setup:auto_wizard
    ]
  end
end
