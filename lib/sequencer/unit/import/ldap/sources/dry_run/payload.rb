# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module Sources
          module DryRun
            class Payload < Sequencer::Unit::Import::Common::ImportJob::Payload::ToAttribute
              provides :ldap_config
            end
          end
        end
      end
    end
  end
end
