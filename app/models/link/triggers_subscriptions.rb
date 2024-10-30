# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Link::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions, on: %i[create update destroy]
  end

  private

  def trigger_subscriptions
    # Captain, oh my captain! I hate to do this, but we need to do it.
    list = [
      [ link_object_source_id, link_object_source_value ],
      [ link_object_target_id, link_object_target_value ]
    ]

    list.each do |link_object_id, link_object_value|
      object_class = Link::Object.find(link_object_id).name.constantize
      object = begin
        object_class.find(link_object_value)
      rescue ActiveRecord::RecordNotFound
        # No need to inform a non-existing object about link changes
        next
      end
      target_type = Link::Object.find(link_object_target_id).name

      Gql::Subscriptions::LinkUpdates
        .trigger(
          nil,
          arguments: {
            object_id:   object.to_global_id.to_s,
            target_type: target_type
          }
        )
    end
  end
end
