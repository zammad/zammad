# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6384CleanupCtiCallerIdsFromTechnicalColumns < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Cti::CallerId.add used to index the digit runs of every string column of a user,
    #   the UUID of an auto-generated login among them. Adding such a user again drops
    #   the caller IDs the remaining columns do not yield.
    User.where(id: Cti::CallerId.where(object: 'User').select(:o_id)).find_each do |user|
      next if Cti::CallerId::ATTRIBUTES_WITHOUT_NUMBERS.none? { |name| Cti::CallerId.extract_numbers(user[name]).any? }

      Cti::CallerId.add(user)
    end
  end
end
