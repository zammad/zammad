# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# i-doit objects, which a ticket stores by their IDs. The caller names one by its ID, as i-doit shows it: finding an
#   object is i-doit's job, through its own interface or an MCP server of its own.
class Service::AI::Tool::SetTicketReferences::System::Idoit < Service::AI::Tool::SetTicketReferences::System
  references 'idoit', label: 'i-doit', noun: 'i-doit object', setting: 'idoit_integration'

  class << self
    def resolve(value)
      id = value.to_s.strip.to_i
      refuse("i-doit has no object with the ID #{id}.") if Array(Idoit.query('cmdb.objects', { ids: [id] })['result']).none?

      id
    rescue RuntimeError => e
      Rails.logger.error "AI tool set_ticket_references could not reach i-doit: #{e.message}"
      refuse('i-doit did not answer. Tell the user that i-doit cannot be reached right now.', code: 'unavailable')
    end

    def stored(ticket)
      Array(ticket.preferences.dig(system_name, 'object_ids')).map(&:to_i)
    end

    def store(ticket, values)
      ticket.preferences[system_name] = (ticket.preferences[system_name] || {}).merge('object_ids' => values)
    end

    def stored_match(stored, value)
      stored.find { |id| id == value.to_s.strip.to_i }
    end

    def value_error(value)
      # rubocop:disable-next Zammad/DetectTranslatableString
      'Name an i-doit object by its ID, as i-doit shows it.' if !value.to_s.strip.match?(%r{\A\d+\z})
    end
  end
end
