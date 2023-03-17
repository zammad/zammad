# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class FormUpdater < BaseQuery
    description 'Return updated form information for a frontend form (e.g. core workflow information or resolved relations).'

    attr_reader :form_updater

    argument :form_updater_id, Gql::Types::Enum::FormUpdaterIdType, description: 'Form updater identifier'
    argument :relation_fields, [Gql::Types::Input::FormUpdater::RelationFieldType], description: 'Relation field information'
    argument :meta, Gql::Types::Input::FormUpdater::MetaInputType, description: 'Form meta information'
    argument :data, GraphQL::Types::JSON, description: 'Current form data from'
    argument :id, GraphQL::Types::ID, required: false, description: 'Optional ID for related entity (e.g. for update forms)'

    type GraphQL::Types::JSON, null: false

    def initialize(*args, **kwargs, &)
      super(*args, **kwargs, &)

      arguments = context[:current_arguments]

      @form_updater = arguments[:form_updater_id].new(
        context:         context,
        relation_fields: arguments[:relation_fields],
        meta:            arguments[:meta].to_h,
        data:            arguments[:data].dup,
        id:              arguments[:id]
      )

      raise ActiveRecord::RecordNotFound, __('FormSchema could not be found.') if !@form_updater
    end

    def self.authorize(_obj, ctx)
      # Per default the queries require a authenticated user.
      if !ctx[:current_arguments][:form_updater_id].requires_authentication
        true
      end

      super
    end

    def authorized?(...)
      if form_updater.respond_to?(:authorized?)
        return form_updater.authorized?
      end

      super
    end

    def resolve(...)
      form_updater.resolve
    end
  end
end
