# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::SanitizedType < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :resource
  provides :backend_class, :action

  private

  def process
    if backend_class.nil?
      logger.info { "Skipping. Unsupported field type '#{resource.type}'#{target_type} for field '#{resource['key'] || resource.title}'." }
      state.provide(:action, :skipped)
      return
    end

    state.provide(:backend_class, backend_class)
  end

  def backend_class
    @backend_class ||= "Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::#{resource.type.capitalize}".safe_constantize
  end

  def target_type
    return if resource['relationship_target_type'].blank?

    " (#{resource['relationship_target_type']})"
  end
end
