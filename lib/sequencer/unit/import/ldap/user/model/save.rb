require_dependency 'sequencer/unit/import/common/model/mixin/without_callback'

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Model
            class Save < Import::Common::Model::Save
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::WithoutCallback

              without_callback :create, :after, :avatar_for_email_check
              without_callback :update, :after, :avatar_for_email_check
            end
          end
        end
      end
    end
  end
end
