# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Attributes
            class Static < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_any_action

              def process
                provide_mapped do
                  {
                    # we have to add the active state manually
                    # because otherwise disabled instances won't get
                    # re-activated if they should get synced again
                    active: true,

                    # Set the source to 'Ldap' for the authentication handling.
                    source: 'Ldap',
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end
