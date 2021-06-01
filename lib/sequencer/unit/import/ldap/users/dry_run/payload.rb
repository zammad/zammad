# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
