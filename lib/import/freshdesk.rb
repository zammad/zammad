# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  class Freshdesk < Import::Base
    include Import::Mixin::Sequence

    def start
      process
    end

    def sequence_name
      'Import::Freshdesk::Full'
    end
  end
end
