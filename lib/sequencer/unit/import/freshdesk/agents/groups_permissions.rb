# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Agents < Sequencer::Unit::Import::Freshdesk::SubSequence::Object
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
        ::Group.all.pluck(:id).index_with do
          'full'.freeze
        end
      end
    end
  end
end
