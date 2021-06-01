# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module RemoteId
            class FromEntry < Sequencer::Unit::Import::Common::Model::Attributes::RemoteId

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
end
