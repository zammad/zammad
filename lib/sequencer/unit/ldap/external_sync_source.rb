# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Ldap
      class ExternalSyncSource < Sequencer::Unit::Common::Provider::Named

        def external_sync_source
          'Ldap::User'
        end
      end
    end
  end
end
