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

                # we need to update in slices since some DBs
                # have a limit for IN length
                lost_ids.each_slice(5000) do |slice|

                  # we need to instanciate every entry and set
                  # the active state this way to send notifications
                  # to the client
                  ::User.where(id: slice).each do |user|
                    user.update!(active: false)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
