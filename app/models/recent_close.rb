# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RecentClose < ApplicationModel
  belongs_to :user, optional: false
  belongs_to :recently_closed_object, polymorphic: true, optional: false

  validates :user, uniqueness: { scope: %i[recently_closed_object_type recently_closed_object_id] }

  after_commit :trigger_subscriptions

  def self.upsert_closing_time!(user, object)
    transaction do
      recent_close = find_or_initialize_by(user:, recently_closed_object: object)
      recent_close.updated_at = Time.current
      recent_close.save!

      recent_close
    end
  end

  def self.cleanup(diff = 3.months)
    where(updated_at: ...diff.ago)
      .delete_all

    true
  end

  def self.destroy_logs(object)
    where(recently_closed_object: object).each(&:destroy)
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::User::Current::RecentClose::Updates
      .trigger({}, scope: user_id)
  end
end
