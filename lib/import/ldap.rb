# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'ldap'
require_dependency 'ldap/group'

module Import
  class Ldap < Import::IntegrationBase
    include Import::Mixin::Sequence

    private

    def sequence_name
      'Import::Ldap::Users'
    end
  end
end
