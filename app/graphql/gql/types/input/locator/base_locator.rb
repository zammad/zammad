# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Locator
  class BaseLocator < Gql::Types::BaseInputObject

    def self.klass(klass = nil)
      return @klass if klass.nil?

      @klass = klass

      init_arguments
      init_validators
    end

    def self.init_arguments
      argument id_field_name, GraphQL::Types::ID, required: false, description: "#{klass.name} ID"
      argument internal_id_field_name, Integer, required: false, description: "#{klass.name} internalId"
    end

    def self.init_validators
      validates required: { one_of: [id_field_name, internal_id_field_name] }
    end

    def self.id_field_name
      :"#{@klass.name.demodulize.underscore}_id"
    end

    def self.internal_id_field_name
      :"#{@klass.name.demodulize.underscore}_internal_id"
    end

    def prepare
      super
      find_record.tap do |record|
        Pundit.authorize(context.current_user, record, :show?)
      rescue Pundit::NotAuthorizedError => e
        raise Exceptions::Forbidden, e.message
      end
    end

    def find_by_internal_id(internal_id)
      self.class.klass.find_by(id: internal_id) ||
        raise(ActiveRecord::RecordNotFound, "No #{self.class.klass.name} found for #{self.class.internal_id_field_name} #{internal_id}.")
    end

    def find_record
      internal_id = public_send(self.class.internal_id_field_name)
      return find_by_internal_id(internal_id) if internal_id

      Gql::ZammadSchema.verified_object_from_id(public_send(self.class.id_field_name), type: self.class.klass)
    end

  end
end
