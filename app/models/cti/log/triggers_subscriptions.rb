# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on caller log changes.
module Cti::Log::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_create_commit  :trigger_create_subscriptions
    after_update_commit  :trigger_update_subscriptions
    # The receiving agents are found through the record's row, which is gone after the destroy.
    before_destroy       :remember_subscribed_agents
    after_destroy_commit :trigger_destroy_subscriptions
  end

  private

  def trigger_create_subscriptions
    subscribed_agents.each do |user|
      Gql::Subscriptions::Cti::LogUpdates.trigger_after_create(self, user)
      Gql::Subscriptions::Cti::SidebarUpdates.trigger_for(user)
    end
  end

  def trigger_update_subscriptions
    subscribed_agents.each do |user|
      Gql::Subscriptions::Cti::LogUpdates.trigger_after_update(self, user)
      Gql::Subscriptions::Cti::SidebarUpdates.trigger_for(user)
    end
  end

  def trigger_destroy_subscriptions
    (@subscribed_agents_before_destroy || []).each do |user|
      Gql::Subscriptions::Cti::LogUpdates.trigger_after_destroy(self, user)
      Gql::Subscriptions::Cti::SidebarUpdates.trigger_for(user)
    end
  end

  def remember_subscribed_agents
    @subscribed_agents_before_destroy = subscribed_agents
  end

  # Unlike push_caller_list_update, every entry counts: the new caller log has no view_limit.
  # The filter Service::Cti::Log::List applies as a scope, checked against the record in memory:
  #   a call saves several times, and each save asks every agent.
  def subscribed_agents
    User.with_permissions('cti.agent').select do |user|
      queues = Service::Cti::Log::QueueFilter.with_current_user(user).execute

      queues.nil? || queues.include?(queue)
    end
  end
end
