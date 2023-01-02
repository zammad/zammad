# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::Sources::Lost::StatisticsDiff < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff

  uses :lost_ids

  def process
    # deactivated count is tracked as a separate number
    # since they don't have to be in the sum (e.g. deleted in LDAP)
    state.provide(:statistics_diff) do
      diff.merge(
        role_ids:    role_ids,
        deactivated: lost_ids.size
      )
    end
  end

  def role_ids
    lost_ids.each_with_object({}) do |user_id, result|

      role_ids = ::User.joins(:roles)
                       .where(id: user_id)
                       .pluck(:'roles_users.role_id')

      role_ids.each do |role_id|
        result[role_id]               ||= diff
        result[role_id][:deactivated]  += 1
      end
    end
  end
end
