class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          class ExternalSyncSource < Sequencer::Unit::Common::Provider::Named

            def external_sync_source
              'Ldap::User'
            end
          end
        end
      end
    end
  end
end
