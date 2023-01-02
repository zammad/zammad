# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Import
  class Kayako < Import::Base
    include Import::Mixin::Sequence

    def start
      process
    end

    def sequence_name
      'Import::Kayako::Full'
    end
  end
end
