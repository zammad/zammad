# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class TaskbarItemType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

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

    def self.authorize(_object, ctx)
      ctx.current_user
    end

    def entity
      object_entity!
    rescue
      nil
    end

    def entity_access
      object_entity!

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
      klass, id = @object.key.split('-', 2)

      # Ticket create is ...
      return @object.state.merge({ uid: id, type: 'TicketCreate' }) if klass == 'TicketCreateScreen'

      # Search is ...
      return @object.params.merge(@object.state).merge({ type: 'Search' }) if klass == 'Search'

      entity = klass.constantize.find(id)
      Pundit.authorize(context.current_user, entity, :show?)

      entity
    end
  end
end
