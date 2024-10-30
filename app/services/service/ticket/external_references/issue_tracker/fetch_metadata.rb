# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::ExternalReferences::IssueTracker::FetchMetadata < Service::Ticket::ExternalReferences::IssueTracker::Base
  attr_reader :issue_links

  def initialize(type:, issue_links:)
    super(type:)

    @issue_links = issue_links
  end

  def execute
    Service::CheckFeatureEnabled.new(name: integration_setting_name).execute

    return [] if issue_links.blank?

    issue_tracker_object.issues_by_urls(issue_links)[:issues] || []
  end
end
