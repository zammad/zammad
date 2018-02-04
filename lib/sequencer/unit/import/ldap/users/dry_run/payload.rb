class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          class DryRun
            class Payload < Sequencer::Unit::Import::Common::ImportJob::Payload::ToAttribute
              provides :ldap_config
            end
          end
        end
      end
    end
  end
end
