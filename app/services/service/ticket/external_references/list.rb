# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The ticket's references into other systems as the ticket stores them, each only while its integration is on. Asks none
#   of these systems; their details come from the issue tracker services.
class Service::Ticket::ExternalReferences::List < Service::Base
  attr_reader :ticket

  def initialize(ticket:)
    @ticket = ticket
  end

  # @return [Hash, nil] GitHub and GitLab issue links and i-doit object IDs, e.g. { idoit: [42] }; nil without any
  def execute
    output = {}

    if Setting.get('github_integration')
      output[:github] = ticket.preferences.dig('github', 'issue_links')
    end

    if Setting.get('gitlab_integration')
      output[:gitlab] = ticket.preferences.dig('gitlab', 'issue_links')
    end

    if Setting.get('idoit_integration')
      output[:idoit] = ticket.preferences.dig('idoit', 'object_ids')&.map(&:to_i)
    end

    output.compact_blank.presence
  end
end
