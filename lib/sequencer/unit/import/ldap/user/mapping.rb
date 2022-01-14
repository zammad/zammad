# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
