# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class GitIntegrationBase
  attr_reader :client, :issue_type

  def fix_urls_for_ticket(ticket_id, url_replacements)
    return if ticket_id.blank?
    return if url_replacements.blank?

    ticket = Ticket.find_by(id: ticket_id)
    return if ticket.blank?
    return if ticket.preferences.blank?
    return if ticket.preferences[issue_type].blank?
    return if ticket.preferences[issue_type][:issue_links].blank?

    ticket.with_lock do
      new_issue_links = Array(ticket.preferences[issue_type][:issue_links])
      new_issue_links.map! { |original_link| url_replacements[original_link].presence ? url_replacements[original_link] : original_link }

      ticket.preferences[issue_type][:issue_links] = Array(new_issue_links).uniq
      ticket.save!
    end
  end
end
