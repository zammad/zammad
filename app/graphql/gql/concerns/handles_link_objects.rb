# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesLinkObjects
  extend ActiveSupport::Concern

  included do
    private

    def fetch_authorized_link_object(object_id)
      object = fetch_link_object(object_id)

      case object
      when ::Ticket
        Pundit.authorize context.current_user, object, :agent_update_access?
      when ::KnowledgeBase::Answer::Translation
        Pundit.authorize context.current_user, object, :show?
      end

      object
    end

    def fetch_visible_link_object(object_id)
      object = fetch_link_object(object_id)

      case object
      when ::Ticket
        Pundit.authorize context.current_user, object, :agent_read_access?
      when ::KnowledgeBase::Answer::Translation
        Pundit.authorize context.current_user, object, :show?
      end

      object
    end

    def fetch_link_object(object_id)
      Gql::ZammadSchema.verified_object_from_id(object_id, type: [::Ticket, ::KnowledgeBase::Answer::Translation])
    end
  end
end
