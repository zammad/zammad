# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
