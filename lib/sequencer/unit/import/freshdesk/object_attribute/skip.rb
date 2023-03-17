# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::ObjectAttribute::Skip < Sequencer::Unit::Base

  uses :resource
  provides :action

  def process
    return if !resource['default'] || allowed_default_attributes.include?(resource['name'])

    state.provide(:action, :skipped)
  end

  private

  def allowed_default_attributes
    @allowed_default_attributes ||= %w[ticket_type]
  end
end
