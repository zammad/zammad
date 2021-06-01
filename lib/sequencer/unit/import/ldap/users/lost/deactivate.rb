# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          module Lost
            class Deactivate < Sequencer::Unit::Base
              uses :dry_run, :lost_ids

              def process
                return if dry_run

                # Why not use `#update_all`?
                # It bypasses validations/callbacks
                # (which are used to send notifications to the client)
                ::User.where(id: lost_ids).find_each do |user|
                  user.update!(active: false, updated_by_id: 1)
                end
              end
            end
          end
        end
      end
    end
  end
end
