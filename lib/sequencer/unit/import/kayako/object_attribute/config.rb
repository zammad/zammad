# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::Config < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
  include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

  skip_any_action

  uses :resource, :sanitized_name, :model_class, :default_language
  provides :config

  def process
    if attribute_type_class.nil?
      logger.info { "Skipping. Unsupported field type '#{resource['type']}' for field '#{resource['key']}'." }
      state.provide(:action, :skipped)
      return
    end

    attribute_config = attribute_type.config

    state.provide(:config) do
      {
        object: model_class.to_s,
        name:   sanitized_name,
      }.merge(attribute_config)
    end
  rescue => e
    handle_failure(e)
  end

  private

  def attribute_type
    attribute_type_class.new(resource, default_language, model_class)
  end

  def attribute_type_class
    @attribute_type_class ||= "Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::#{resource['type'].capitalize}".safe_constantize
  end
end
