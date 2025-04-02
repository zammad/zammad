# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class GitIntegrationBase
  attr_reader :client, :issue_type

  def fix_urls_for_ticket(ticket, url_replacements)
    return if url_replacements.blank?

    issues_links = ticket.preferences.dig(issue_type, :issue_links)

    return if issues_links.blank?

    ticket.with_lock do
      ticket.preferences[issue_type][:issue_links] = issues_links
        .map { |elem| url_replacements[elem].presence || elem }
        .uniq

      ticket.save!
    end
  end
end
