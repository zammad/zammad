class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module RemoteId
            class Unhex < Sequencer::Unit::Base

              uses :remote_id
              provides :remote_id

              def process
                return if remote_id.ascii_only?
                state.provide(:remote_id, unhexed)
              end

              private

              def unhexed
                ::Ldap::Guid.string(remote_id)
              end
            end
          end
        end
      end
    end
  end
end
