# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::ExternalReferences::IssueTracker::Item < Service::Ticket::ExternalReferences::IssueTracker::Base
  attr_reader :issue_link

  def initialize(type:, issue_link:)
    super(type:)

    @issue_link = issue_link
  end

  def execute
    Service::CheckFeatureEnabled.new(name: integration_setting_name).execute

    issue_tracker_object.issue_by_url(issue_link)
  end
end
