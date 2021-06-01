# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  class Exchange < Import::IntegrationBase
    include Import::Mixin::Sequence

    private

    def sequence_name
      'Import::Exchange::FolderContacts'
    end
  end
end
