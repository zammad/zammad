# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# This unit checks if an Sequencer state attribute (e.g. `mapped`) is blank.
# Don't confuse it with e.g. 'Import::Common::Model::Skip::MissingMandatory::Base' which checks if an attribute key (e.g. mapped[:some_key]) is blank/missing.
class Sequencer::Unit::Import::Common::Model::Skip::Blank::Base < Sequencer::Unit::Base
  include ::Sequencer::Unit::Common::Mixin::DynamicAttribute
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
  include ::Sequencer::Unit::Import::Common::Model::Mixin::Log::ContextIdentificationString

  skip_any_action

  provides :action

  optional :model_class

  def process
    return if !skip?

    logger.info { skip_log_message }
    state.provide(:action, :skipped)
  end

  private

  def ignore
    [:id]
  end

  def skip?
    return true if attribute_value.blank?

    relevant_blank?
  end

  def skip_log_message
    "Skipping. Blank attribute '#{attribute}' found (#{attribute_value.inspect})#{context_identification_string}"
  end

  def relevant_blank?
    attribute_value.except(*ignore).values.none?(&:present?)
  end
end
