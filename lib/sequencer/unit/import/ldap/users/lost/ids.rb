# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          module Lost
            class Ids < Sequencer::Unit::Base
              uses :found_ids, :external_sync_source, :model_class
              provides :lost_ids

              def process
                state.provide(:lost_ids, active_ids - found_ids)
              end

              def active_ids
                ::ExternalSync.joins('INNER JOIN users ON (users.id = external_syncs.o_id)')
                              .where(
                                source: external_sync_source,
                                object: model_class.name,
                                users:  {
                                  active: true
                                }
                              )
                              .pluck(:o_id)
              end
            end
          end
        end
      end
    end
  end
end
