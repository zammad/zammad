# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::Config < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
  include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

  skip_any_action

  uses :resource, :sanitized_name, :model_class, :default_language
  provides :config

  def process
    attribute_config = attribute_type.config

    state.provide(:config) do
      {
        object: model_class.to_s,
        name:   sanitized_name,
      }.merge(attribute_config)
    end
  rescue => e
    logger.error "The custom field type '#{resource['type']}' can not be mapped to an internal field."
    handle_failure(e)
  end

  private

  def attribute_type
    "Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::#{resource['type'].capitalize}".constantize.new(resource, default_language)
  end
end
