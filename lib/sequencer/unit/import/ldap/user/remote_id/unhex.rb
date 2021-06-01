# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module RemoteId
            class Unhex < Sequencer::Unit::Base
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_action :skipped, :failed

              uses :remote_id
              provides :remote_id

              def process
                # check if a remote_id is given and
                # prefer .nil? over .blank? etc. because
                # the HEX values cause errors otherwise
                return if remote_id.nil?
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
