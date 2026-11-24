# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# An issue tracker, whose issues a ticket stores by their links, as the ticket view does.
class Service::AI::Tool::SetTicketReferences::System::IssueTracker < Service::AI::Tool::SetTicketReferences::System
  class << self
    def resolve(value)
      item = Service::Ticket::ExternalReferences::IssueTracker::Item.execute(type: system_name, issue_link: value.to_s.strip.chomp('/'))
      refuse("#{label} has no issue at this link, or the integration's token may not read it.") if item.blank?

      item[:url].to_s
    rescue Exceptions::UnprocessableContent => e
      refuse("#{e.message}. Give the link of an issue, as #{label} shows it.", code: 'invalid_value')
    rescue RuntimeError => e
      Rails.logger.error "AI tool set_ticket_references could not reach #{label}: #{e.message}"
      refuse("#{label} did not answer. Tell the user that #{label} cannot be reached right now.", code: 'unavailable')
    end

    def stored(ticket)
      Array(ticket.preferences.dig(system_name, 'issue_links'))
    end

    def store(ticket, values)
      ticket.preferences[system_name] = (ticket.preferences[system_name] || {}).merge('issue_links' => values)
    end

    def stored_match(stored, value)
      stored.find { |link| comparable(link) == comparable(value) }
    end

    private

    def comparable(link)
      link.to_s.strip.chomp('/').downcase
    end
  end
end
