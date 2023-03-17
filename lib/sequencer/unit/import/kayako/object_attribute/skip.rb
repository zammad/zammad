# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::Skip < Sequencer::Unit::Base

  uses :resource
  provides :action

  def process
    return if (!resource['is_system'] && skip_attribute_types.exclude?(resource['type'])) || allowed_system_attributes.include?(resource['key'])

    state.provide(:action, :skipped)
  end

  private

  def skip_attribute_types
    @skip_attribute_types ||= %w[FILE]
  end

  def allowed_system_attributes
    @allowed_system_attributes ||= %w[type]
  end
end
