# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        class UserGroupMap < Sequencer::Unit::Base

          uses :client
          provides :user_group_map

          def process
            state.provide(:user_group_map, mapping)
          end

          private

          def mapping
            result = {}
            client.group_memberships.all! do |group_membership|
              result[ group_membership.user_id ] ||= []
              result[ group_membership.user_id ].push( group_membership.group_id )
            end
            result
          end
        end
      end
    end
  end
end
