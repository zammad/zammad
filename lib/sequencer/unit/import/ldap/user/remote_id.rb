class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          class RemoteId < Sequencer::Unit::Import::Common::Model::Attributes::RemoteId
            uses :ldap_config

            private

            def attribute
              ldap_config[:user_uid].to_sym
            end
          end
        end
      end
    end
  end
end
