# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Updater::Ticket::Concerns::HasOwnerId
  extend ActiveSupport::Concern

  def resolve
    resolved_result = super

    # When owner_id is set to 1 (system user), we need to reset it to nil.
    if resolved_result.dig(:fields, 'owner_id').present? && resolved_result[:fields]['owner_id'][:value] == 1
      resolved_result[:fields]['owner_id'][:value] = nil
    end

    resolved_result
  end
end
