# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Form
  include Mixin::RequiredSubPaths

  # Context from GraphQL or possibly other environments.
  # It must respond to :current_user and :current_user? for session information (see Gql::Context::CurrentUserAware).
  # It may respond to :schema with an object providing :id_for_object to perform ID mappings like in Gql::ZammadSchema.
  attr_reader :context

  def initialize(context:)
    @context = context
  end

  def self.forms
    descendants
  end
end
