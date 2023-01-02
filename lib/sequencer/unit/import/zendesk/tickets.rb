# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Tickets < Sequencer::Unit::Import::Zendesk::SubSequence::Object
  include ::Sequencer::Unit::Import::Zendesk::Mixin::IncrementalExport

  uses :user_map, :organization_map, :group_map, :ticket_field_map, :field_map

  private

  def default_params
    super.merge(
      user_map:         user_map,
      group_map:        group_map,
      organization_map: organization_map,
      ticket_field_map: ticket_field_map,
      field_map:        field_map,
    )
  end
end
