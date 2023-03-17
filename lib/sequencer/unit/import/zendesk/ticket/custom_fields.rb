# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::CustomFields < Sequencer::Unit::Import::Zendesk::Common::CustomFields

  uses :ticket_field_map

  private

  def remote_fields
    custom_fields = resource.custom_fields
    return {} if custom_fields.blank?

    custom_fields.select { |custom_field| ticket_field_map[ custom_field['id'] ].present? }
    .to_h do |custom_field|
      [
        ticket_field_map[ custom_field['id'] ].to_sym, # remote_name
        custom_field['value']
      ]
    end
  end
end
