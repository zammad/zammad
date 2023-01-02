# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::User::Groups < Sequencer::Unit::Common::Provider::Named

  uses :resource, :group_map, :user_group_map

  private

  def groups
    remote_ids.filter_map { |remote_id| group_map[remote_id] }
              .map { |local_id| ::Group.find(local_id) }
  end

  def remote_ids
    return [] if user_group_map.blank?

    user_group_map.fetch(resource.id, [])
  end
end
