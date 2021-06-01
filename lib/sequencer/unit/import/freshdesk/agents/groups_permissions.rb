# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Agents < Sequencer::Unit::Import::Freshdesk::SubSequence::Object
          class GroupsPermissions < Sequencer::Unit::Base

            def process
              ::Role.find_by(name: 'Agent').users.each do |user|
                user.group_ids_access_map = group_ids_access_map
                user.save!
              end
            end

            private

            def group_ids_access_map
              @group_ids_access_map ||= begin
                ::Group.all.pluck(:id).each_with_object({}) do |group_id, result|
                  result[group_id] = 'full'.freeze
                end
              end
            end
          end
        end
      end
    end
  end
end
