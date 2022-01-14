# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Import
  class Ldap < Import::IntegrationBase
    include Import::Mixin::Sequence

    private

    def sequence_name
      'Import::Ldap::Users'
    end
  end
end
