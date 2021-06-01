# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UpdateCtiLogsByCallerJob < ApplicationJob
  def perform(phone, limit: 60, offset: 0)
    preferences = Cti::CallerId.get_comment_preferences(phone, 'from')&.last

    Cti::Log.where(from: phone, direction: 'in')
            .order(created_at: :desc)
            .limit(limit)
            .offset(offset)
            .each do |log|
      log.update(preferences: preferences)
    end
  end
end
