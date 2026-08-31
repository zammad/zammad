# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class TaskbarItemType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Users taskbar item'

    field :user_id, ID, null: false
    field :key, String, null: false
    field :callback, Gql::Types::Enum::TaskbarEntityType, null: false # TODO: rename to something understable like type? maybe with "property: :callback"
    field :state, GraphQL::Types::JSON
    field :params, GraphQL::Types::JSON
    field :prio, Integer, null: false
    field :notify, Boolean, null: false
    field :active, Boolean, null: false
    field :app, Gql::Types::Enum::TaskbarAppType, null: false

    field :form_id, String
    field :form_new_article_present, Boolean, null: false
    field :entity, Gql::Types::User::TaskbarItemEntityType
    field :entity_access, Gql::Types::Enum::TaskbarEntityAccessType
    field :changed, Boolean, null: false
    field :dirty, Boolean, null: false

    def entity
      object_entity!
    rescue
      nil
    end

    def entity_access
      # A tab without an entity model has no access state either - the frontend
      #   then renders the tab content of its plugin.
      return if object_entity!.nil?

      'Granted'
    rescue ActiveRecord::RecordNotFound
      'NotFound'
    rescue Pundit::NotAuthorizedError
      'Forbidden'
    rescue
      nil
    end

    def form_id
      @object.state&.dig('article', 'form_id') || @object.state&.dig('form_id')
    end

    def form_new_article_present
      @object.state&.dig('article', 'type').present?
    end

    def changed
      @object.state_changed?
    end

    def dirty
      @object.preferences&.dig(:dirty) || false
    end

    private

    def object_entity!
      key_prefix, id = @object.key.split('-', 2)

      # Ticket create is ...
      return @object.state.merge({ uid: id, type: 'TicketCreate' }) if key_prefix == 'TicketCreateScreen'

      # A knowledge base answer create tab has no record either, and its key must not look like
      #   the record key of an answer ('KnowledgeBase__Answer-42'), which the edit view uses -
      #   hence the 'Screen' suffix, like the ticket create tab above.
      #
      # The params carry the locale the draft is written in, which the state cannot: one draft is
      #   one translation, and the tab link has to be rebuildable without the form (like Search).
      return @object.params.merge(@object.state).merge({ uid: id, type: 'KnowledgeBaseAnswerCreate' }) if key_prefix == 'KnowledgeBaseAnswerCreateScreen'

      # Search is ...
      return @object.params.merge(@object.state).merge({ type: 'Search' }) if key_prefix == 'Search'

      # No model for the prefix means the entry has no entity at all, e.g.
      #   because it was written in a legacy key format - which is different
      #   from a missing record, so it is no error.
      klass = Taskbar.entity_class_for_key_prefix(key_prefix)
      if klass.nil?
        Rails.logger.debug { "No taskbar entity model for key prefix '#{key_prefix}'." }

        return nil
      end

      # Not the `id` of the split above: a key may qualify the tab behind the
      #   record id - the edit tab of a knowledge base answer carries the locale
      #   it edits - and that qualifier is none of the record's identity.
      entity_id = Taskbar.entity_key_id(@object.key)
      if entity_id.nil?
        Rails.logger.debug { "No taskbar entity id in key '#{@object.key}'." }

        return nil
      end

      entity = klass.find(entity_id)

      # Which query authorizes the entity depends on what the tab is for: an
      #   edit tab is only offered to someone who may edit (see
      #   Taskbar.entity_pundit_method).
      Pundit.authorize(context.current_user, entity, Taskbar.entity_pundit_method(@object.callback))

      entity
    end
  end
end
