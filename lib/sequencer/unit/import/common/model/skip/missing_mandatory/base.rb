# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Skip::MissingMandatory::Base < Sequencer::Unit::Base
  include ::Sequencer::Unit::Common::Mixin::DynamicAttribute
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
  include ::Sequencer::Unit::Import::Common::Model::Mixin::Log::ContextIdentificationString

  skip_any_action

  provides :action

  def process
    return if !mandatory_missing?

    logger.info { skip_log_message }
    state.provide(:action, :skipped)
  end

  private

  def mandatory
    raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
  end

  def mandatory_missing?
    return true if attribute_value.blank?

    missing_for_keys.present?
  end

  def skip_log_message
    "Skipping. Missing values for mandatory keys '#{missing_for_keys.join(', ')}' in attribute '#{attribute}'#{context_identification_string}"
  end

  def missing_for_keys
    @missing_for_keys ||= mandatory.select { |key| attribute_value[key].blank? }
  end
end
