# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          class Mapping < Sequencer::Unit::Import::Common::Mapping::FlatKeys
            uses :ldap_config

            private

            def mapping
              ldap_config[:user_attributes]
            end
          end
        end
      end
    end
  end
end
